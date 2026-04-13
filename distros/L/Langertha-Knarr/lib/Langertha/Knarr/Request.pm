package Langertha::Knarr::Request;
# ABSTRACT: Normalized chat request shared across all Knarr protocols
our $VERSION = '1.001';
use Moose;


has model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has messages => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  default => sub { [] },
);

has stream => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has temperature => (
  is => 'ro',
  isa => 'Maybe[Num]',
  default => sub { undef },
);

has max_tokens => (
  is => 'ro',
  isa => 'Maybe[Int]',
  default => sub { undef },
);

has tools => (
  is => 'ro',
  isa => 'Maybe[ArrayRef]',
  default => sub { undef },
);

has system => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has session_id => (
  is => 'rw',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has protocol => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has raw => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

has extra => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Request - Normalized chat request shared across all Knarr protocols

=head1 VERSION

version 1.001

=head1 DESCRIPTION

The normalized request shape that every L<Langertha::Knarr::Protocol>
parser produces and every L<Langertha::Knarr::Handler> receives.
Wire-protocol-specific quirks (OpenAI's C<choices>, Anthropic's
C<system> outside C<messages>, A2A's JSON-RPC envelope, etc.) are
handled by the protocol's C<parse_chat_request> and don't leak into
the handler API.

The original wire-format body is preserved in L</raw> for handlers
(like L<Langertha::Knarr::Handler::Passthrough>) that need to forward
it verbatim.

=head2 protocol

Required. Short string identifying the parser that produced this
request: C<openai>, C<anthropic>, C<ollama>, C<a2a>, C<acp>, C<agui>.

=head2 model

Optional model id from the request body.

=head2 messages

ArrayRef of message hashes (C<< { role => ..., content => ... } >>).

=head2 stream

Boolean. Whether the client requested streaming.

=head2 temperature, max_tokens, tools, system

Optional generation parameters and tool definitions, if the protocol
extracted them.

=head2 session_id

Optional session id, used for per-session state. Pulled from
protocol-specific fields (e.g. OpenAI's C<user>, A2A's C<sessionId>,
or the C<x-session-id> header).

=head2 raw

The original decoded request body. Useful for passthrough handlers
that need to forward without re-encoding.

=head2 extra

Per-protocol scratch space (e.g. JSON-RPC id for A2A, run_id for ACP).

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
