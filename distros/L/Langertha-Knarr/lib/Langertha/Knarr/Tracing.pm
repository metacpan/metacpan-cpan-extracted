package Langertha::Knarr::Tracing;
our $VERSION = '1.100';
# ABSTRACT: Automatic Langfuse tracing per proxy request
use Moo;
use Time::HiRes qw( gettimeofday );
use Carp qw( croak );
use JSON::MaybeXS ();
use MIME::Base64 qw( encode_base64 );
use Log::Any qw( $log );
use HTTP::Request ();
use Net::Async::HTTP;
use IO::Async::Loop;


has config => (
  is       => 'ro',
  required => 1,
);


has _enabled => (
  is      => 'lazy',
  builder => '_build__enabled',
);

sub _build__enabled {
  my ($self) = @_;
  my $lf = $self->config->langfuse;
  my $pub = $lf->{public_key} // _strip_quotes($ENV{LANGFUSE_PUBLIC_KEY});
  my $sec = $lf->{secret_key} // _strip_quotes($ENV{LANGFUSE_SECRET_KEY});
  return ($pub && $sec) ? 1 : 0;
}

has _public_key => (
  is      => 'lazy',
  builder => '_build__public_key',
);

sub _build__public_key {
  my ($self) = @_;
  return $self->config->langfuse->{public_key} // _strip_quotes($ENV{LANGFUSE_PUBLIC_KEY});
}

has _secret_key => (
  is      => 'lazy',
  builder => '_build__secret_key',
);

sub _build__secret_key {
  my ($self) = @_;
  return $self->config->langfuse->{secret_key} // _strip_quotes($ENV{LANGFUSE_SECRET_KEY});
}

has _url => (
  is      => 'lazy',
  builder => '_build__url',
);

has trace_name => (
  is      => 'lazy',
  builder => '_build_trace_name',
);


sub _build_trace_name {
  my ($self) = @_;
  return $self->config->langfuse->{trace_name}
    // _strip_quotes($ENV{LANGFUSE_TRACE_NAME})
    // _strip_quotes($ENV{KNARR_TRACE_NAME})
    // 'knarr-proxy';
}

sub _build__url {
  my ($self) = @_;
  return $self->config->langfuse->{url} // _strip_quotes($ENV{LANGFUSE_URL}) // _strip_quotes($ENV{LANGFUSE_BASE_URL}) // 'https://cloud.langfuse.com';
}

has _batch => (
  is      => 'rw',
  default => sub { [] },
);

has _json => (
  is      => 'lazy',
  builder => '_build__json',
);

# Strip surrounding quotes from env values (Docker --env-file includes them literally)
sub _strip_quotes {
  my $v = shift;
  return $v unless defined $v;
  $v =~ s/^["']|["']$//g;
  return $v;
}

sub _build__json {
  return JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);
}

sub _uuid {
  my @hex = map { sprintf("%04x", int(rand(65536))) } 1..8;
  return join('-',
    $hex[0].$hex[1],
    $hex[2],
    '4'.substr($hex[3], 1),
    sprintf("%x", 8 + int(rand(4))).substr($hex[4], 1),
    $hex[5].$hex[6].$hex[7],
  );
}

sub _timestamp {
  my ($s, $us) = gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}


sub start_trace {
  my ($self, %opts) = @_;
  return undef unless $self->_enabled;

  my $trace_id = _uuid();
  my $gen_id   = _uuid();
  my $now      = _timestamp();

  push @{$self->_batch}, {
    id        => _uuid(),
    type      => 'trace-create',
    timestamp => $now,
    body      => {
      id       => $trace_id,
      name     => $self->trace_name,
      input    => $opts{messages},
      metadata => {
        format  => $opts{format},
        engine  => $opts{engine},
        model   => $opts{model},
        params  => $opts{params},
      },
      tags => ['knarr'],
    },
  };

  push @{$self->_batch}, {
    id        => _uuid(),
    type      => 'generation-create',
    timestamp => $now,
    body      => {
      id        => $gen_id,
      traceId   => $trace_id,
      name      => 'proxy-request',
      model     => $opts{model},
      input     => $opts{messages},
      startTime => $now,
    },
  };

  return { trace_id => $trace_id, gen_id => $gen_id, start_time => $now };
}


sub end_trace {
  my ($self, $trace_info, %opts) = @_;
  return unless $self->_enabled;
  return unless $trace_info;

  my $now = _timestamp();

  if ($opts{error}) {
    push @{$self->_batch}, {
      id        => _uuid(),
      type      => 'generation-update',
      timestamp => $now,
      body      => {
        id            => $trace_info->{gen_id},
        endTime       => $now,
        level         => 'ERROR',
        statusMessage => $opts{error},
      },
    };
  } else {
    push @{$self->_batch}, {
      id        => _uuid(),
      type      => 'generation-update',
      timestamp => $now,
      body      => {
        id      => $trace_info->{gen_id},
        output  => $opts{output},
        endTime => $now,
        $opts{model} ? (model => $opts{model}) : (),
        $opts{usage} ? (usage => $opts{usage}) : (),
      },
    };
  }

  push @{$self->_batch}, {
    id        => _uuid(),
    type      => 'trace-create',
    timestamp => $now,
    body      => {
      id     => $trace_info->{trace_id},
      output => $opts{output} // $opts{error},
    },
  };

  $self->flush;
}


has _loop => (
  is      => 'lazy',
  builder => sub { IO::Async::Loop->new },
);

has _http => (
  is      => 'lazy',
  builder => sub {
    my ($self) = @_;
    my $h = Net::Async::HTTP->new( user_agent => 'Langertha-Knarr', timeout => 5 );
    $self->_loop->add($h);
    return $h;
  },
);

sub flush {
  my ($self) = @_;
  return unless $self->_enabled;
  my $batch = $self->_batch;
  return unless @$batch;
  $self->_batch([]);

  my $auth = encode_base64($self->_public_key . ':' . $self->_secret_key, '');
  my $body = $self->_json->encode({ batch => $batch });
  my $req  = HTTP::Request->new(
    POST => $self->_url . '/api/public/ingestion',
    [
      'Content-Type'  => 'application/json',
      'Authorization' => 'Basic ' . $auth,
    ],
    $body,
  );

  my $f = $self->_http->do_request( request => $req );
  $f->on_done(sub {
    my ($resp) = @_;
    return if $resp->is_success;
    $log->warnf("Langfuse ingestion failed: %s", $resp->status_line);
  });
  $f->on_fail(sub {
    my ($err) = @_;
    $log->warnf("Langfuse flush error: %s", $err);
  });
  $f->retain;
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Tracing - Automatic Langfuse tracing per proxy request

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Langertha::Knarr::Tracing;

    my $tracing = Langertha::Knarr::Tracing->new(config => $config);

    my $trace_id = $tracing->start_trace(
      model    => 'gpt-4o',
      engine   => 'Langertha::Engine::OpenAI',
      messages => \@messages,
      params   => \%params,
      format   => 'openai',
    );

    # ... handle request ...

    $tracing->end_trace($trace_id,
      output => $response_text,
      model  => 'gpt-4o',
      usage  => { input => 100, output => 50, total => 150 },
    );

=head1 DESCRIPTION

Records every proxy request as a Langfuse trace with a nested generation. When
tracing is not configured (no public and secret key), all methods are no-ops.

Langfuse credentials are read from the config file's C<langfuse:> section or
from the C<LANGFUSE_PUBLIC_KEY>, C<LANGFUSE_SECRET_KEY>, and C<LANGFUSE_URL>
environment variables. The module strips surrounding quotes from environment
variable values, which Docker C<--env-file> sometimes adds literally.

=head2 config

The L<Langertha::Knarr::Config> object. Required. Provides Langfuse
credentials and C<trace_name>.

=head2 trace_name

The Langfuse trace name applied to all traces. Resolved in priority order from:
C<langfuse.trace_name> in config, C<LANGFUSE_TRACE_NAME> env var,
C<KNARR_TRACE_NAME> env var, or the default C<knarr-proxy>.

=head2 start_trace

    my $trace_info = $tracing->start_trace(
      model    => $model_name,
      engine   => $engine_class,
      messages => \@messages,
      params   => \%params,
      format   => 'openai',
    );

Creates a new Langfuse trace and generation. Returns a C<$trace_info> hashref
that must be passed to L</end_trace>. Returns C<undef> when tracing is
disabled.

=head2 end_trace

    $tracing->end_trace($trace_info,
      output => $response_text,
      model  => $model,
      usage  => { input => 100, output => 50, total => 150 },
    );

    # On error:
    $tracing->end_trace($trace_info, error => "Something went wrong");

Closes the generation and trace started by L</start_trace>, then flushes the
batch to Langfuse. Pass C<error> to record a failed generation at level ERROR.
Does nothing when C<$trace_info> is C<undef> (tracing was disabled at start).

=head2 flush

    $tracing->flush;

Sends all pending trace events to the Langfuse ingestion API as a batch and
clears the internal buffer. Called automatically by L</end_trace>. Does nothing
when tracing is disabled or the batch is empty.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Tracing is wired in automatically for all routes

=item * L<Langertha::Knarr::Config> — Provides Langfuse credentials

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
