package Langertha::Knarr::Tracing;
our $VERSION = '1.101';
# ABSTRACT: Automatic Langfuse tracing per proxy request
use Moo;
use Time::HiRes qw( gettimeofday );
use Carp qw( croak );
use Scalar::Util qw( blessed );
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
  my ($s, $us) = @_ ? @_ : gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}

# ISO-8601 timestamp at $start_hires + $delta_seconds. Turns the deltas an
# engine measured (ttft_seconds / total_seconds on Langertha::Response) into
# absolute Langfuse timestamps anchored to the moment start_trace ran — not
# to "now", which has already moved past the end of the call.
sub _iso_after {
  my ($start_hires, $delta_seconds) = @_;
  return undef unless ref $start_hires eq 'ARRAY' && defined $delta_seconds;
  # Clamp: a negative delta (clock skew, or a provider-reported duration we
  # did not produce) would otherwise report a trip into the past.
  $delta_seconds = 0 if $delta_seconds < 0;
  my ($s, $us) = @$start_hires;
  my $sum = $us + $delta_seconds * 1_000_000;
  return _timestamp( $s + int( $sum / 1_000_000 ), int($sum) % 1_000_000 );
}

# Flatten a Langertha::RateLimit (or an equivalent hashref) into plain
# scalars for the trace metadata. Only the quota fields — the object's raw
# header hash is deliberately left out so response headers never leak into
# Langfuse, and so the payload stays JSON-encodable without convert_blessed.
my @RATE_LIMIT_FIELDS = qw(
  requests_limit requests_remaining requests_reset
  tokens_limit   tokens_remaining   tokens_reset
);

sub _rate_limit_hash {
  my ($rl) = @_;
  return undef unless defined $rl;
  my %out;
  if ( blessed $rl ) {
    for my $f (@RATE_LIMIT_FIELDS) {
      next unless $rl->can($f);
      my $v = $rl->$f;
      $out{$f} = $v if defined $v;
    }
  }
  elsif ( ref $rl eq 'HASH' ) {
    for my $f (@RATE_LIMIT_FIELDS) {
      $out{$f} = $rl->{$f} if defined $rl->{$f};
    }
  }
  return %out ? \%out : undef;
}

# Flatten a Langertha::Usage into its canonical token counts, for the same
# reason _rate_limit_hash exists: Langertha's value objects carry no TO_JSON,
# so the object itself would blow up L</flush>'s encode. A plain hashref (the
# shape end_trace's own SYNOPSIS documents) passes through untouched; an
# object we cannot flatten is dropped rather than poisoning the batch.
sub _usage_hash {
  my ($u) = @_;
  return undef unless defined $u;
  return $u->to_hash if blessed($u) && $u->can('to_hash');
  return $u if ref($u) eq 'HASH';
  return undef;
}


sub start_trace {
  my ($self, %opts) = @_;
  return undef unless $self->_enabled;

  my $trace_id = _uuid();
  my $gen_id   = _uuid();
  my @hires    = gettimeofday;
  my $now      = _timestamp(@hires);

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

  return {
    trace_id    => $trace_id,
    gen_id      => $gen_id,
    start_time  => $now,
    start_hires => \@hires,
  };
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
    my $timing = ( ref $opts{timing} eq 'HASH' ) ? $opts{timing} : undef;

    # Engine-measured deltas win over the proxy's wall clock: they are
    # anchored to the same instant as start_time and exclude our own
    # dispatch/formatting overhead. Without them endTime stays "now".
    my $end_time         = $now;
    my $completion_start = undef;
    if ( $timing ) {
      my $hires = $trace_info->{start_hires};
      $end_time = _iso_after( $hires, $timing->{total_seconds} ) // $end_time
        if defined $timing->{total_seconds};
      $completion_start = _iso_after( $hires, $timing->{ttft_seconds} )
        if defined $timing->{ttft_seconds};
    }

    my $usage = _usage_hash( $opts{usage} );

    my %metadata;
    $metadata{timing}      = $timing if $timing;
    $metadata{response_id} = $opts{response_id} if defined $opts{response_id};
    $metadata{thinking}    = $opts{thinking}
      if defined $opts{thinking} && length $opts{thinking};
    if ( my $rl = _rate_limit_hash( $opts{rate_limit} ) ) {
      $metadata{rate_limit} = $rl;
    }

    push @{$self->_batch}, {
      id        => _uuid(),
      type      => 'generation-update',
      timestamp => $now,
      body      => {
        id      => $trace_info->{gen_id},
        output  => $opts{output},
        endTime => $end_time,
        defined $completion_start ? (completionStartTime => $completion_start) : (),
        $opts{model} ? (model => $opts{model}) : (),
        $usage       ? (usage => $usage)       : (),
        %metadata    ? (metadata => \%metadata) : (),
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

  # Tracing is observability, not the product. flush runs inside end_trace on
  # the response path — and for streams after the last chunk was written — so
  # an exception here turns an already-answered request into a 500, or leaves
  # a client waiting for an end marker that never comes. The batch was
  # detached from _batch above and is unrecoverable either way, so a failed
  # encode is logged at error level (as loud as any request fault in
  # Langertha::Knarr) and dropped, exactly like the ingestion failures below.
  my $body;
  my $encode_error = do {
    local $@;
    eval { $body = $self->_json->encode({ batch => $batch }); };
    $@;
  };
  if ($encode_error) {
    $log->errorf("Langfuse batch encode failed, dropping %d event(s): %s",
      scalar @$batch, $encode_error);
    return;
  }

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

version 1.101

=head1 SYNOPSIS

    use Langertha::Knarr::Tracing;

    my $tracing = Langertha::Knarr::Tracing->new(config => $config);

    my $trace_id = $tracing->start_trace(
      model    => 'gpt-5.6-terra',
      engine   => 'Langertha::Engine::OpenAI',
      messages => \@messages,
      params   => \%params,
      format   => 'openai',
    );

    # ... handle request ...

    $tracing->end_trace($trace_id,
      output => $response_text,
      model  => 'gpt-5.6-terra',
      usage  => { input => 100, output => 50, total => 150 },
    );

=head1 DESCRIPTION

Records every proxy request as a Langfuse trace with a nested generation. When
tracing is not configured (no public and secret key), all methods are no-ops.

Langfuse credentials are read from the config file's C<langfuse:> section or
from the C<LANGFUSE_PUBLIC_KEY>, C<LANGFUSE_SECRET_KEY>, and C<LANGFUSE_URL>
environment variables. The module strips surrounding quotes from environment
variable values, which Docker C<--env-file> sometimes adds literally.

=head2 Timing sources

Knarr has two request paths and they do not measure latency the same way.
The generation's C<startTime> always marks the moment L</start_trace> ran;
what differs is where C<endTime> and C<completionStartTime> come from.

=over

=item * B<Routed, non-streaming> — a L<Langertha> engine produced a
L<Langertha::Response>, so L<Langertha::Knarr::Handler::Tracing> hands the
engine-measured C<timing> hash to L</end_trace>. C<endTime> becomes
C<startTime + total_seconds> and C<completionStartTime> becomes
C<startTime + ttft_seconds>, both anchored to the high-resolution
timestamp L</start_trace> recorded. This is the only path with a real
time-to-first-token, and the durations exclude the proxy's own
formatting overhead.

=item * B<Routed, streaming> — the decorator accumulates deltas and never
sees a response object, so there is no C<timing>. C<endTime> is the
wall-clock moment the stream was exhausted and no C<completionStartTime>
is emitted.

=item * B<Raw passthrough> — bytes are piped 1:1 and never parsed, so no
L<Langertha::Response> exists at all. C<endTime> is again the proxy's own
wall clock at L</end_trace>, which includes network time to the upstream
provider.

=back

Callers that pass no C<timing> therefore keep exactly the previous
behaviour: proxy-measured C<endTime>, no C<completionStartTime>.

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

The returned hashref carries C<start_hires>, the C<gettimeofday> pair behind
C<start_time>. L</end_trace> anchors engine-measured durations to it; see
L</Timing sources>.

=head2 end_trace

    $tracing->end_trace($trace_info,
      output => $response_text,
      model  => $model,
      usage  => { input => 100, output => 50, total => 150 },
      timing => { ttft_seconds => 0.25, total_seconds => 1.5 },
      response_id => 'chatcmpl-123',
    );

    # On error:
    $tracing->end_trace($trace_info, error => "Something went wrong");

Closes the generation and trace started by L</start_trace>, then flushes the
batch to Langfuse. Pass C<error> to record a failed generation at level ERROR.
Does nothing when C<$trace_info> is C<undef> (tracing was disabled at start).

Optional metadata carried off a L<Langertha::Knarr::Response>, all skipped
when absent:

=over

=item * C<timing> — HashRef with C<ttft_seconds> / C<total_seconds>. Drives
the generation's C<endTime> and C<completionStartTime> (the Langfuse field
for time-to-first-token) and is recorded verbatim in the metadata, so
provider-native stage durations survive too. See L</Timing sources>.

=item * C<response_id> — the provider's own response id, for correlating a
Langfuse generation with the provider's logs.

=item * C<thinking> — reasoning text the engine split off C<content>. It is
model output that C<output> no longer contains, so the trace is the only
place it survives.

=item * C<rate_limit> — a L<Langertha::RateLimit> (or equivalent hashref).
Flattened to its quota scalars; the raw header hash is not recorded.

=item * C<usage> — a L<Langertha::Usage> (the shape every routed response
carries) or a plain hashref. Objects are flattened with C<to_hash> to
C<input_tokens> / C<output_tokens> / C<total_tokens>; hashrefs are recorded
verbatim.

=back

=head2 flush

    $tracing->flush;

Sends all pending trace events to the Langfuse ingestion API as a batch and
clears the internal buffer. Called automatically by L</end_trace>. Does nothing
when tracing is disabled or the batch is empty.

Never throws: a batch that cannot be JSON-encoded is logged at error level and
dropped, the same way an ingestion HTTP failure is. L</end_trace> runs on the
request's response path, so a tracing problem must not take the client's
response down with it.

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
