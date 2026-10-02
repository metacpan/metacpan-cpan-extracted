package Langertha::ToolChoice;
# ABSTRACT: Immutable canonical tool-selection policy with cross-provider conversion
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use Moose::Util::TypeConstraints qw( enum );


# Canonical types: 'auto' (let model decide), 'any' (must call any tool),
# 'none' (no tool calling), 'tool' (must call this specific tool).
enum 'Langertha::ToolChoice::Type' => [qw( auto any none tool )];

has type => (
  is       => 'ro',
  isa      => 'Langertha::ToolChoice::Type',
  required => 1,
);


has name => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  default   => sub { undef },
);


# --- Convenience constructors ---

sub auto     { my $class = shift; $class->new( type => 'auto' ) }
sub any      { my $class = shift; $class->new( type => 'any' ) }
sub none     { my $class = shift; $class->new( type => 'none' ) }
sub specific {
  my ( $class, $name ) = @_;
  return $class->new( type => 'tool', name => $name );
}


# --- Constructors from wire-format hashes/strings ---

sub from_hash {
  my ($class, $val) = @_;
  return undef unless defined $val;
  # A ToolChoice is already canonical input (karr k235): hand it back, so every
  # request builder serializes it with ->to($fmt) instead of leaking TO_JSON.
  return $val if blessed($val) && $val->isa(__PACKAGE__);

  if ( !ref($val) ) {
    return $class->any  if $val eq 'required' || $val eq 'any';
    return $class->auto if $val eq 'auto';
    return $class->none if $val eq 'none';
    return undef;
  }

  return undef unless ref($val) eq 'HASH';
  my $type = $val->{type} // '';

  if ( $type eq 'function' ) {
    my $name = '';
    if ( ref( $val->{function} ) eq 'HASH' ) {
      $name = $val->{function}{name} // '';
    } elsif ( defined $val->{name} ) {
      $name = $val->{name} // '';
    }
    return length($name) ? $class->specific($name) : $class->auto;
  }

  if ( $type eq 'tool' ) {
    my $name = $val->{name} // '';
    return length($name) ? $class->specific($name) : $class->auto;
  }

  return $class->any  if $type eq 'any' || $type eq 'required';
  return $class->auto if $type eq 'auto';
  return $class->none if $type eq 'none';
  return undef;
}


sub from_openai    { shift->from_hash(@_) }
sub from_anthropic { shift->from_hash(@_) }

# --- Serializers ---

sub to_openai {
  my ($self) = @_;
  return 'required' if $self->type eq 'any';
  return 'auto'     if $self->type eq 'auto';
  return 'none'     if $self->type eq 'none';
  if ( $self->type eq 'tool' ) {
    return defined $self->name && length $self->name
      ? { type => 'function', function => { name => $self->name } }
      : 'auto';
  }
  return undef;
}

sub to_anthropic {
  my ($self) = @_;
  return { type => 'any' }  if $self->type eq 'any';
  return { type => 'auto' } if $self->type eq 'auto';
  return { type => 'none' } if $self->type eq 'none';
  if ( $self->type eq 'tool' ) {
    return defined $self->name && length $self->name
      ? { type => 'tool', name => $self->name }
      : { type => 'auto' };
  }
  return undef;
}


sub to_perplexity {
  my ($self) = @_;
  # Perplexity only accepts string forms: none / auto / required.
  # Named-tool forcing is not supported on the wire — engine layer
  # is expected to switch to a response_format-based path when a
  # named tool is requested. We coerce here so callers that ignore
  # capabilities still get *something* sensible.
  return 'none'     if $self->type eq 'none';
  return 'auto'     if $self->type eq 'auto';
  return 'required';
}


sub to_gemini {
  my ($self) = @_;
  # Gemini uses toolConfig.functionCallingConfig:
  #   { mode => AUTO|ANY|NONE, allowed_function_names => [...] }
  # Gemini also offers a fifth mode, VALIDATED ("model decides, but validates a
  # function call with constrained decoding") — deliberately NOT modeled here:
  # the canonical vocabulary is none|auto|required|named, and VALIDATED ("auto,
  # but a call it makes is schema-valid") has no canonical equivalent. If the
  # canonical set ever grows a fifth policy, that is where it maps (karr k140).
  return { functionCallingConfig => { mode => 'NONE' } } if $self->type eq 'none';
  return { functionCallingConfig => { mode => 'AUTO' } } if $self->type eq 'auto';
  return { functionCallingConfig => { mode => 'ANY'  } } if $self->type eq 'any';
  if ( $self->type eq 'tool' ) {
    return { functionCallingConfig => { mode => 'AUTO' } }
      unless defined $self->name && length $self->name;
    return {
      functionCallingConfig => {
        mode                   => 'ANY',
        allowed_function_names => [ $self->name ],
      },
    };
  }
  return undef;
}


sub to_responses {
  my ($self) = @_;
  # Responses API uses flat {type => 'function', name => 'foo'} — no nested function wrapper
  return 'auto'     if $self->type eq 'auto';
  return 'none'      if $self->type eq 'none';
  return 'required' if $self->type eq 'any';
  if ( $self->type eq 'tool' ) {
    return defined $self->name && length $self->name
      ? { type => 'function', name => $self->name }
      : 'auto';
  }
  return undef;
}


sub to_hash {
  my ($self) = @_;
  return { type => $self->type, ( defined $self->name ? ( name => $self->name ) : () ) };
}


# Make the object transparent to any JSON encoder configured with
# convert_blessed => 1 (the house default, see Langertha::Plugin::Langfuse).
# to_hash is the complete canonical representation, so this is a plain
# delegator — nothing is dropped.
sub TO_JSON { shift->to_hash }

# --- Tag-driven dispatch ---

# Maps a tool_wire_format tag to the per-format serializer. Only the wires that
# actually carry a tool_choice request parameter are listed: Ollama and Hermes
# have no wire-level tool_choice (Hermes forces via prompt injection), so to()
# croaks for them. Perplexity is not a tool_wire_format value — its named-tool
# request is rewritten to response_format by chat_f — so to_perplexity stays a
# standalone helper, off the tag dispatch; it is legacy (Sonar /chat/completions
# forms), the Agent API has no tool_choice (karr k233).
my %TO_METHOD = (
  openai    => 'to_openai',
  anthropic => 'to_anthropic',
  gemini    => 'to_gemini',
  responses => 'to_responses',
);

sub to {
  my ( $self, $fmt ) = @_;
  my $method = $TO_METHOD{ $fmt // '' }
    or croak "Langertha::ToolChoice: unknown wire format '" . ( $fmt // '' ) . "'";
  return $self->$method;
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ToolChoice - Immutable canonical tool-selection policy with cross-provider conversion

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::ToolChoice;

    my $choice = Langertha::ToolChoice->specific('get_weather');

    $choice->to('openai');     # { type => 'function', function => { name => 'get_weather' } }
    $choice->to('anthropic');  # { type => 'tool', name => 'get_weather' }
    $choice->to('responses');  # { type => 'function', name => 'get_weather' }
    $choice->to('gemini');
    # { functionCallingConfig => { mode => 'ANY',
    #                              allowed_function_names => ['get_weather'] } }

    # Normalize whatever the caller passed (string, any provider's hash,
    # or a ToolChoice object) into the canonical form
    my $tc = Langertha::ToolChoice->from_hash('required');   # type 'any'
    $tc    = Langertha::ToolChoice->from_hash(
        { type => 'function', function => { name => 'extract' } } );
    say $tc->type, ' ', $tc->name;   # tool extract

    # A ToolChoice object is valid tool_choice input on every engine
    my $response = await $engine->chat_f(
        messages    => [ { role => 'user', content => $prompt } ],
        tools       => [ $tool ],
        tool_choice => Langertha::ToolChoice->specific('extract'),
    );

=head1 DESCRIPTION

Canonical value object for the tool-selection policy of a request: may the
model call a tool, must it, and must it call one particular tool. It sits
beside L<Langertha::Tool>, L<Langertha::ToolCall> and L<Langertha::ToolResult>
in the tool wire-translation seam: request builders normalize the caller's
C<tool_choice> with L</from_hash> and serialize it with L</to>, dispatched by
the engine's C<tool_wire_format>, so the per-provider spelling lives in this
one place (ADR 0001, ADR 0010).

The canonical vocabulary has four policies, held in L</type>:

=over 4

=item * C<auto> - the model decides whether to call a tool

=item * C<any> - the model must call some tool (OpenAI's C<required>)

=item * C<none> - the model must not call a tool

=item * C<tool> - the model must call the tool named in L</name>

=back

A ToolChoice object is valid C<tool_choice> input on every engine and tool
wire: L</from_hash> hands an object back unchanged, and every request builder
serializes it through L</to> rather than passing the object through. What
happens beyond the serialized value (for example L<Langertha::Role::Chat/chat_f>
rewriting a named choice into a C<response_format> on engines without the
C<tool_choice_named> capability) is the engine's business, not this class's.

Instances are immutable.

=head2 type

Required. The canonical policy: one of C<auto>, C<any>, C<none> or C<tool>
(the C<Langertha::ToolChoice::Type> enum). Anything else fails the type
constraint at construction.

=head2 name

The tool to force when L</type> is C<tool>; C<undef> by default. A C<tool>
choice without a non-empty name serializes as C<auto> on every wire. The name
is not checked against the request's tool list.

=head2 auto

    my $auto = Langertha::ToolChoice->auto;

Class method that builds an C<auto> choice.

=head2 any

    my $any = Langertha::ToolChoice->any;

Class method that builds an C<any> choice.

=head2 none

    my $none = Langertha::ToolChoice->none;

Class method that builds a C<none> choice.

=head2 specific

    my $choice = Langertha::ToolChoice->specific('get_weather');

Class method that builds a C<tool> choice forcing the named tool.

=head2 from_hash

    my $choice = Langertha::ToolChoice->from_hash($tool_choice);

Class method that normalizes a caller-supplied C<tool_choice> into a
ToolChoice, whichever provider's spelling it uses. Accepts:

=over 4

=item * a ToolChoice object, returned unchanged

=item * the strings C<auto>, C<none>, and C<required> or C<any> (both give
C<any>)

=item * a hash with C<type> C<auto>, C<none>, C<any> or C<required>

=item * a named-tool hash in the OpenAI Chat Completions shape
C<< { type => 'function', function => { name => ... } } >>, the flat
Responses shape C<< { type => 'function', name => ... } >>, or the Anthropic
shape C<< { type => 'tool', name => ... } >>; a missing or empty name gives
C<auto>

=back

Returns C<undef> for C<undef> and for anything it does not recognize (an
unknown string or C<type>, a non-hash reference). It never dies, so callers
test the result.

=head2 from_openai

Alias for L</from_hash>, which reads every supported shape regardless of the
provider it came from.

=head2 from_anthropic

Alias for L</from_hash>, like L</from_openai>.

=head2 to_openai

    my $wire = $choice->to_openai;

Serializes for the OpenAI Chat Completions C<tool_choice> field: the strings
C<auto>, C<none> and C<required> (for C<any>), or
C<< { type => 'function', function => { name => $name } } >> for a named
tool. The C<openai> entry of L</to>.

=head2 to_anthropic

    my $wire = $choice->to_anthropic;

Serializes for the Anthropic Messages C<tool_choice> field: always a hash,
C<< { type => 'auto' } >>, C<< { type => 'any' } >>, C<< { type => 'none' } >>
or C<< { type => 'tool', name => $name } >>. The C<anthropic> entry of
L</to>. C<disable_parallel_tool_use> is not part of this value; the request
builder in L<Langertha::Role::AnthropicCompatible> folds the engine's
C<parallel_tool_use> (L<Langertha::Role::ParallelToolUse>) into the block.

=head2 to_perplexity

    my $wire = $choice->to_perplexity;   # 'none' | 'auto' | 'required'

B<Legacy.> Serializes to the string forms of Perplexity's old Sonar
C</chat/completions> endpoint: C<none>, C<auto>, and C<required> for both
C<any> and a named tool (that wire could not force a named tool). Kept for
callers of that endpoint; L<Langertha::Engine::Perplexity> no longer uses it.
The Agent API (C</v1/agent>) that engine speaks has no C<tool_choice> field at
all, so the engine never sends one (see L<Langertha::Role::ResponsesCompatible>).
Not on the C<to($fmt)> dispatch.

=head2 to_gemini

    my $wire = $choice->to_gemini;
    # { functionCallingConfig => { mode => 'ANY', allowed_function_names => ['x'] } }

Serializes for Gemini's C<toolConfig>: C<< { functionCallingConfig => { mode
=> 'AUTO' | 'ANY' | 'NONE' } } >>, and for a named tool mode C<ANY> with
C<allowed_function_names> holding that one name. Gemini's C<VALIDATED> mode
has no canonical equivalent and is never produced. The C<gemini> entry of
L</to>.

=head2 to_responses

    my $wire = $choice->to_responses;

Serializes for the Open-Responses C<tool_choice> field
(L<Langertha::Engine::OpenAIResponses>): the strings C<auto>, C<none> and
C<required> (for C<any>), or the flat C<< { type => 'function', name =>
$name } >> for a named tool, without the nested C<function> wrapper of Chat
Completions. The C<responses> entry of L</to>.

=head2 to_hash

    my $hash = $choice->to_hash;   # { type => 'tool', name => 'extract' }

The canonical, provider-neutral form: C<type>, plus C<name> when it is
defined. L</from_hash> reads it back.

=head2 TO_JSON

Returns L</to_hash>, so a JSON encoder with C<convert_blessed> enabled
serializes the object in its canonical form. That is for logging and
tracing (for example L<Langertha::Plugin::Langfuse>); a request body gets the
wire form from L</to>.

=head2 to

    my $wire = $choice->to( $engine->tool_wire_format );

Serializes for a C<tool_wire_format> by dispatching to L</to_openai>,
L</to_anthropic>, L</to_gemini> or L</to_responses>. Only those four wires
carry a C<tool_choice> request field. C<ollama> and C<hermes> have none, so
C<to> croaks for them, as it does for any unknown or undefined format. (On
the hermes wire L<Langertha::Role::Chat> handles the choice itself: C<none>
withholds the tools from the prompt, anything else but C<auto> is ignored
with a warning.) L</to_perplexity> is not on this dispatch.

=head1 SEE ALSO

=over

=item * L<Langertha::Tool> - Sibling value object for tool definitions

=item * L<Langertha::ToolCall> - Sibling value object for the calls a model emits

=item * L<Langertha::ToolResult> - Sibling value object for tool result blocks

=item * L<Langertha::Role::Chat/chat_f> - Takes C<tool_choice> and rewrites a
named choice where the wire cannot force a tool

=item * L<Langertha::Role::Capabilities> - The C<tool_choice_auto>,
C<tool_choice_any>, C<tool_choice_none> and C<tool_choice_named> flags

=item * ADR 0001 and ADR 0010 in F<docs/adr/> - Why tool wire-translation
routes through these value objects

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
