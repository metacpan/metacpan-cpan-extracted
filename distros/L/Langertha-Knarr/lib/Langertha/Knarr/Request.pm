package Langertha::Knarr::Request;
# ABSTRACT: Normalized chat request shared across all Knarr protocols
our $VERSION = '1.102';
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

has reasoning_effort => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has seed => (
  is => 'ro',
  isa => 'Maybe[Int]',
  default => sub { undef },
);

has parallel_tool_use => (
  is => 'ro',
  isa => 'Maybe[Bool]',
  default => sub { undef },
);

has prompt_cache_key => (
  is => 'ro',
  isa => 'Maybe[Str]',
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


sub forward_header_pairs {
  my ($self) = @_;
  my $fwd = $self->extra->{forward_headers};
  return map { [ @$_ ] } @$fwd if ref $fwd eq 'ARRAY';
  return map { [ $_, $fwd->{$_} ] } sort keys %$fwd if ref $fwd eq 'HASH';
  return;
}


sub forward_header {
  my ($self, $name) = @_;
  return map { $_->[1] }
    grep { lc $_->[0] eq lc $name && defined $_->[1] } $self->forward_header_pairs;
}


# Which capability flag a given response_format value requires. Only an
# explicit json_schema type needs the schema flag; json_object, Ollama's
# bare 'json' string and any raw-schema HashRef fall back to the object
# flag, which is the weaker of the two.
sub _response_format_cap {
  my ($rf) = @_;
  return 'response_format_json_schema'
    if ref($rf) eq 'HASH' && ( $rf->{type} // '' ) eq 'json_schema';
  return 'response_format_json_object';
}

sub chat_f_args {
  my ($self, $engine) = @_;
  my $supports = $engine && $engine->can('supports')
    ? sub { $engine->supports($_[0]) }
    : sub { 1 };
  my $rf = $self->response_format;
  my $tools_ok = $supports->('tools_native') || $supports->('tools_hermes');
  my @args = ( messages => $self->messages );
  push @args, tools           => $self->tools           if $self->tools           && $tools_ok;
  push @args, tool_choice     => $self->tool_choice     if defined $self->tool_choice && $tools_ok;
  push @args, response_format => $rf                    if defined $rf              && $supports->( _response_format_cap($rf) );
  push @args, temperature     => $self->temperature     if defined $self->temperature && $supports->('temperature');
  push @args, max_tokens      => $self->max_tokens      if defined $self->max_tokens  && $supports->('response_size');
  push @args, reasoning_effort => $self->reasoning_effort if defined $self->reasoning_effort && $supports->('reasoning_effort');
  push @args, seed              => $self->seed              if defined $self->seed              && $supports->('seed');
  push @args, parallel_tool_use => $self->parallel_tool_use if defined $self->parallel_tool_use && $supports->('parallel_tool_use');
  push @args, prompt_cache_key  => $self->prompt_cache_key  if defined $self->prompt_cache_key  && $supports->('prompt_cache_key');
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

version 1.102

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

=head2 temperature, max_tokens, reasoning_effort, seed, parallel_tool_use, prompt_cache_key, tools, tool_choice, response_format, system

Optional generation parameters and tool definitions, if the protocol
extracted them. C<tool_choice> and C<response_format> are passed to
L<Langertha::Engine> via C<chat_f> in their canonical form; Langertha
normalizes them to the target engine's wire format. C<reasoning_effort>
is the per-request reasoning effort (e.g. C<low>/C<medium>/C<high>),
capability-gated like the other generation parameters. The OpenAI face
carries it natively; the Anthropic face's C<thinking> and the Ollama face's
C<think> are mapped onto it by L<Langertha::Knarr::Reasoning>.

C<seed>, C<parallel_tool_use> and C<prompt_cache_key> are further
per-request controls, each extracted by a protocol parser only where the
inbound wire format actually carries the field (OpenAI's top-level
C<seed> / C<parallel_tool_calls> / C<prompt_cache_key>, and Ollama's
C<options.seed>) and each capability-gated in L</chat_f_args>. Knarr only
validates and forwards them; Langertha does the honoring and places each
on the target engine's own wire.

=head2 session_id

Optional session id, used for per-session state. Pulled from
protocol-specific fields (e.g. OpenAI's C<user>, A2A's C<sessionId>,
or the C<x-session-id> header).

=head2 raw

The original decoded request body. Useful for passthrough handlers
that need to forward without re-encoding.

=head2 extra

Per-protocol scratch space (e.g. JSON-RPC id for A2A, run_id for ACP).
The Ollama parser records the path the client asked for as C<path>
(C</api/chat> or C</api/generate>): it picks the answer's shape, and
L<Langertha::Knarr::Handler::Passthrough> sends the request to the same path
upstream.

The OpenAI, Anthropic and Ollama parsers record the client's auth headers
as C<forward_headers>, an ArrayRef of C<[ name, value ]> pairs with one pair
per header line the client sent, in its order (a header sent twice is two
pairs). L<Langertha::Knarr> takes its own proxy key out of every pair;
L<Langertha::Knarr::Handler::Passthrough> sends each pair upstream as a line
of its own. Read them with L</forward_header_pairs> and L</forward_header>.

=head2 chat_f_args

    my @args = $request->chat_f_args($engine);
    my $r    = await $engine->chat_f(@args);

Builds a named-argument list suitable for L<Langertha::Role::Chat/chat_f>.
Always includes C<messages>; conditionally adds C<tools>, C<tool_choice>,
C<response_format>, C<temperature>, C<max_tokens>, C<reasoning_effort>,
C<seed>, C<parallel_tool_use>, C<prompt_cache_key> when set on the request
B<and> the engine reports support for the matching capability via
C<< $engine->supports($cap) >>. Engines without C<supports()> get every
defined parameter — older Langertha versions accepted unknown args
silently.

Per-request generation controls are handed to C<chat_f> as canonical
named arguments; Langertha extracts them as controls and places each on
the target engine's own wire (top-level C<reasoning_effort> on OpenAI,
C<output_config> plus C<thinking> on Anthropic, C<seed> under Ollama's
C<options>, OpenAI's C<parallel_tool_calls> / C<prompt_cache_key>, and so
on). The capability gate is strict: a control is forwarded only to an
engine whose wire actually advertises it, so e.g. a C<seed> is dropped
onto an engine that does not compose C<Langertha::Role::Seed> even where
its wire would technically accept the field.

C<response_format> is gated on the capability matching the I<kind> of
format requested, because Langertha registers the two separately
(L<Langertha::Role::Capabilities>): an explicit
C<< { type => 'json_schema' } >> needs C<response_format_json_schema>,
while everything else — OpenAI's C<< { type => 'json_object' } >> and
Ollama's bare C<'json'> — needs only C<response_format_json_object>.
Gating both on the schema flag would drop a plain C<json_object>
request on an engine that can only do the loose form.

C<tools> and C<tool_choice> are forwarded when the engine supports
either C<tools_native> or C<tools_hermes>. Hermes-wire engines
(NousResearch, AKI native) carry tools in the system prompt rather than
as a native C<tools> field, and Langertha's C<chat_f> renders them there
and handles C<tool_choice> per wire, so gating on C<tools_native> alone
would silently drop a client's tools on those backends.

=head2 forward_header_pairs

    for my $pair ( $request->forward_header_pairs ) {
      my ($name, $value) = @$pair;
      ...
    }

The client headers recorded in C<< extra->{forward_headers} >> as a list of
C<[ name, value ]> pairs, in their order, repeats kept (copies: changing one
leaves the request alone). A C<forward_headers> hash, as a request built by
hand may carry, reads as one pair per key, sorted by name. Empty when the
request has none.

=head2 forward_header

    my @values = $request->forward_header('authorization');

Every value of one forwarded header, the name matched without regard to
case, in the order the client sent them. Empty when there is none.

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
