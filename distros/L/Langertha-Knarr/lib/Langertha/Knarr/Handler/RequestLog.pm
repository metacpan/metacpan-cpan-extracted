package Langertha::Knarr::Handler::RequestLog;
# ABSTRACT: Decorator handler that writes per-request JSON logs via Knarr::RequestLog
our $VERSION = '1.100';
use Moose;
use Future;
use Future::AsyncAwait;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;

with 'Langertha::Knarr::Handler';


# Wraps an inner handler with structured per-request logging. Same shape
# as Knarr::Handler::Tracing — opens a log handle on each request and
# closes it with the assistant text once the inner handler resolves.

has wrapped => (
  is       => 'ro',
  required => 1,
);

# Anything implementing start_request(%opts) → $handle / end_request($handle, %opts).
# In production this is a Langertha::Knarr::RequestLog instance; tests can
# pass a mock that records calls.
has request_log => (
  is       => 'ro',
  required => 1,
);

sub _open {
  my ($self, $request) = @_;
  return $self->request_log->start_request(
    model    => ( $request->model // '' ),
    format   => $request->protocol,
    engine   => ref( $self->wrapped ),
    path     => '',
    stream   => $request->stream,
    messages => $request->messages,
    params   => {
      temperature => $request->temperature,
      max_tokens  => $request->max_tokens,
      tools       => $request->tools,
    },
  );
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $handle = $self->_open($request);
  my $f = eval { $self->wrapped->handle_chat_f( $session, $request ) };
  if ( my $err = $@ ) {
    $self->request_log->end_request( $handle, error => "$err" );
    die $err;
  }
  return await $f->then( sub {
    my ($r) = @_;
    my $resp = Langertha::Knarr::Response->coerce($r);
    $self->request_log->end_request(
      $handle,
      output => $resp->content,
      ( $resp->usage ? ( usage => $resp->usage ) : () ),
    );
    return Future->done($r);
  })->else( sub {
    my ($err) = @_;
    $self->request_log->end_request( $handle, error => "$err" );
    return Future->fail($err);
  });
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $handle = $self->_open($request);

  my $upstream;
  my $err = do {
    local $@;
    eval { $upstream = $self->wrapped->handle_stream_f( $session, $request )->get; };
    $@;
  };
  if ($err) {
    $self->request_log->end_request( $handle, error => "$err" );
    die $err;
  }

  my $accumulated = '';
  my $closed = 0;

  return Langertha::Knarr::Stream->new(
    source => sub {
      $upstream->next_chunk_f->then( sub {
        my ($delta) = @_;
        if ( defined $delta ) {
          $accumulated .= $delta;
          return Future->done($delta);
        }
        unless ( $closed ) {
          $closed = 1;
          $self->request_log->end_request( $handle, output => $accumulated );
        }
        return Future->done(undef);
      })->else( sub {
        my ($e) = @_;
        unless ( $closed ) {
          $closed = 1;
          $self->request_log->end_request( $handle, error => "$e" );
        }
        return Future->fail($e);
      });
    },
  );
}

sub list_models { $_[0]->wrapped->list_models }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::RequestLog - Decorator handler that writes per-request JSON logs via Knarr::RequestLog

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Langertha::Knarr::RequestLog;
    use Langertha::Knarr::Handler::RequestLog;

    my $rlog = Langertha::Knarr::RequestLog->new(config => $config);
    $handler = Langertha::Knarr::Handler::RequestLog->new(
        wrapped     => $handler,
        request_log => $rlog,
    );

=head1 DESCRIPTION

Decorator handler that writes a structured per-request log entry for
every chat or stream request via L<Langertha::Knarr::RequestLog>.
Sync requests log a single line with the result; streaming requests
accumulate every delta and log one line with the assembled output
when the stream closes.

C<knarr start> mounts this automatically when
C<KNARR_LOG_FILE> / C<KNARR_LOG_DIR> (or the YAML C<logging:> section)
is set.

=head2 wrapped

Required. The inner L<Langertha::Knarr::Handler> being decorated.

=head2 request_log

Required. A L<Langertha::Knarr::RequestLog> instance (or any object
implementing C<start_request> / C<end_request>).

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
