package Langertha::Knarr::Request;
# ABSTRACT: Normalized chat request shared across all Knarr protocols
our $VERSION = '1.100';
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

has tool_choice => (
  is => 'ro',
  default => sub { undef },
);

has response_format => (
  is => 'ro',
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


sub chat_f_args {
  my ($self, $engine) = @_;
  my $supports = $engine && $engine->can('supports')
    ? sub { $engine->supports($_[0]) }
    : sub { 1 };
  my @args = ( messages => $self->messages );
  push @args, tools           => $self->tools           if $self->tools           && $supports->('tools_native');
  push @args, tool_choice     => $self->tool_choice     if defined $self->tool_choice && $supports->('tools_native');
  push @args, response_format => $self->response_format if defined $self->response_format;
  push @args, temperature     => $self->temperature     if defined $self->temperature && $supports->('temperature');
  push @args, max_tokens      => $self->max_tokens      if defined $self->max_tokens  && $supports->('response_size');
  return @args;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Request - Normalized chat request shared across all Knarr protocols

=head1 VERSION

version 1.100

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

=head2 temperature, max_tokens, tools, tool_choice, response_format, system

Optional generation parameters and tool definitions, if the protocol
extracted them. C<tool_choice> and C<response_format> are passed to
L<Langertha::Engine> via C<chat_f> in their canonical form; Langertha
normalizes them to the target engine's wire format.

=head2 session_id

Optional session id, used for per-session state. Pulled from
protocol-specific fields (e.g. OpenAI's C<user>, A2A's C<sessionId>,
or the C<x-session-id> header).

=head2 raw

The original decoded request body. Useful for passthrough handlers
that need to forward without re-encoding.

=head2 extra

Per-protocol scratch space (e.g. JSON-RPC id for A2A, run_id for ACP).

=head2 chat_f_args

    my @args = $request->chat_f_args($engine);
    my $r    = await $engine->chat_f(@args);

Builds a named-argument list suitable for L<Langertha::Role::Chat/chat_f>.
Always includes C<messages>; conditionally adds C<tools>, C<tool_choice>,
C<response_format>, C<temperature>, C<max_tokens> when set on the request
B<and> the engine reports support for the matching capability via
C<< $engine->supports($cap) >>. Engines without C<supports()> get every
defined parameter — older Langertha versions accepted unknown args
silently.

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
