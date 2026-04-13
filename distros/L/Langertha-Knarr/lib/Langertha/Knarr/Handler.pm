package Langertha::Knarr::Handler;
# ABSTRACT: Role for Knarr backend handlers (Raider, Engine, Code, ...)
our $VERSION = '1.001';
use Moose::Role;
use Future::AsyncAwait;
use Langertha::Knarr::Stream;


requires 'handle_chat_f';
requires 'list_models';

# Default streaming = run handle_chat_f and emit one chunk.
# Handlers that natively stream should override.
async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $r = await $self->handle_chat_f($session, $request);
  my $content = ref $r eq 'HASH' ? ($r->{content} // '') : "$r";
  return Langertha::Knarr::Stream->from_list($content);
}

# Optional capability hooks — handlers may override.
sub handle_embedding_f {
  my ($self) = @_;
  die "embedding not supported by " . ref($self) . "\n";
}

sub handle_transcription_f {
  my ($self) = @_;
  die "transcription not supported by " . ref($self) . "\n";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler - Role for Knarr backend handlers (Raider, Engine, Code, ...)

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    package My::Handler;
    use Moose;
    use Future;
    with 'Langertha::Knarr::Handler';

    sub handle_chat_f {
        my ($self, $session, $request) = @_;
        return Future->done({ content => 'hello', model => 'my-model' });
    }

    sub list_models { [ { id => 'my-model', object => 'model' } ] }

    1;

=head1 DESCRIPTION

The role every Knarr backend handler must consume. A handler is the
"what answers the request" half of Knarr — it receives a normalized
L<Langertha::Knarr::Request> and returns either a sync result hash via
L</handle_chat_f> or an async chunk iterator via L</handle_stream_f>.

Knarr ships with concrete handlers for the common cases:

=over

=item * L<Langertha::Knarr::Handler::Code> — coderef-backed, for tests/fakes

=item * L<Langertha::Knarr::Handler::Engine> — passthrough to a Langertha engine

=item * L<Langertha::Knarr::Handler::Raider> — per-session L<Langertha::Raider>

=item * L<Langertha::Knarr::Handler::Router> — model-name routing via L<Langertha::Knarr::Router>

=item * L<Langertha::Knarr::Handler::Passthrough> — raw HTTP forward to upstream

=item * L<Langertha::Knarr::Handler::A2AClient> — consume a remote A2A agent

=item * L<Langertha::Knarr::Handler::ACPClient> — consume a remote ACP agent

=item * L<Langertha::Knarr::Handler::Tracing> — Langfuse tracing decorator

=item * L<Langertha::Knarr::Handler::RequestLog> — JSONL request logging decorator

=back

Decorators (Tracing, RequestLog) wrap an inner handler and themselves
consume this role, so they compose freely.

=head2 handle_chat_f

    my $future = $handler->handle_chat_f($session, $request);

Required. Returns a L<Future> that resolves to a hashref with at least
a C<content> key and optionally C<model>.

=head2 handle_stream_f

    my $stream = await $handler->handle_stream_f($session, $request);

Default implementation calls L</handle_chat_f> and emits the result as
a single-chunk stream. Native streamers should override and return a
L<Langertha::Knarr::Stream> whose C<next_chunk_f> yields chunk strings.

=head2 list_models

    my $models = $handler->list_models;

Required. Returns an arrayref of model descriptors as hashes with at
least an C<id> key.

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
