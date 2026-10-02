package Langertha::Engine::NousResearch;
# ABSTRACT: Nous Research Inference API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools', 'Langertha::Role::HermesTools', 'Langertha::Role::StaticModels';

# karr k238 (ADR 0033, amends 0001/0002/0019): hermes is not the endpoint
# dialect, it is the wire for Hermes models only. NousResearch is an
# OpenAI-compatible gateway fronting ~341 models; a non-Hermes slug
# (anthropic/..., openai/..., ...) routes to a real backend that takes native
# OpenAI tools, so hermes there would be wrong. Hermes models want the hermes
# wire -- tools ride the system prompt and <tool_call> tags are lifted onto
# Response.tool_calls -- which is the robust choice given upstream
# hermes-agent#741, where Hermes-4 intermittently emits tool calls as
# <tool_call> XML / bare JSON even with native calling wired up. So Hermes is
# the named exception; native is the default (safer for the 280+ non-Hermes
# slugs and any unknown new one). Matches Hermes-4/-4.3, Hermes-3, DeepHermes,
# the nousresearch/ prefix, lowercase, and the legacy Nous-Hermes-2 form.
sub _is_hermes_model {
  my ( $self ) = @_;
  return $self->chat_model =~ m{\A(?:nousresearch/)?(?:nous-)?(?:deep)?hermes}i ? 1 : 0;
}

# Resolved once per instance from chat_model (default_model is 'Hermes-4-70B',
# so reading it never croaks). A tool_wire_format => ... constructor arg wins
# via the init_arg (Role::Tools), so a user can force either wire on any slug.
sub _build_tool_wire_format {
  my ( $self ) = @_;
  return $self->_is_hermes_model ? 'hermes' : 'openai';
}


sub _build_supported_operations {[qw(
  createChatCompletion
)]}

has '+url' => (
  lazy => 1,
  default => sub { 'https://inference-api.nousresearch.com/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_NOUSRESEARCH_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_NOUSRESEARCH_API_KEY or api_key set";
}

sub default_model { 'Hermes-4-70B' }

sub _build_static_models {[
  { id => 'Hermes-4-70B' },
  { id => 'Hermes-4-405B' },
  { id => 'Hermes-4.3-36B' },
]}

has reasoning => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);


my $_default_reasoning_prompt = <<'END_REASONING_PROMPT';
You are a deep thinking AI, you may use extremely long chains of thought to
deeply consider the problem and deliberate with yourself via systematic
reasoning processes to help come to a correct solution prior to answering.
You should enclose your thoughts and internal monologue inside <think> </think>
tags, and then provide your solution or response to the problem.
END_REASONING_PROMPT
chomp $_default_reasoning_prompt;

has reasoning_prompt => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub { $_default_reasoning_prompt },
);


# Prepend the reasoning prompt as the first system message. Wrapping
# _system_messages (not chat_messages) makes Langertha::Chat send it too,
# also when the wrapper brings its own system prompt (karr k277).
around _system_messages => sub {
  my ( $orig, $self, @override ) = @_;
  my @system = $self->$orig(@override);
  return @system unless $self->reasoning;
  # The Nous reasoning prompt is a Hermes-model feature (karr k238, ADR 0033):
  # gate it on _is_hermes_model, the same predicate _build_tool_wire_format
  # uses, NOT on tool_wire_format. This decouples the reasoning prompt from the
  # tool transport, so forcing tool_wire_format => 'openai' on a genuine Hermes
  # model still gets reasoning. On a non-Hermes slug the prompt is meaningless,
  # so drop it with one warning.
  unless ( $self->_is_hermes_model ) {
    $self->_langertha_carp( "".( ref $self ).": reasoning => 1 is ignored -- the Nous"
      . " reasoning prompt is a Hermes-model feature and '" . $self->chat_model
      . "' is not a Hermes model", 'nous_reasoning_non_hermes' );
    return @system;
  }
  return ( { role => 'system', content => $self->reasoning_prompt }, @system );
};

# The reasoning prompt follows chat_model too, so a per-request model that
# crosses the Hermes line flips it (karr k352, Role::Chat::_warn_model_override).
around _model_scoped_wire_decisions => sub {
  my ( $orig, $self, @args ) = @_;
  my %decision = $self->$orig(@args);
  $decision{'reasoning prompt'} = $self->_is_hermes_model ? 1 : 0 if $self->reasoning;
  return %decision;
};

around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  # image_input (k266, ADR 0019): vision is undocumented / unverified on this face, so no claim.
  delete $caps->{image_input};
  return $caps;
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::NousResearch - Nous Research Inference API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::NousResearch;

    my $nous = Langertha::Engine::NousResearch->new(
        api_key => $ENV{NOUSRESEARCH_API_KEY},
        model   => 'Hermes-4-70B',
    );

    print $nous->simple_chat('Explain the Hermes prompt format');

    # Chain-of-thought reasoning (Hermes 4)
    my $nous = Langertha::Engine::NousResearch->new(
        api_key   => $ENV{NOUSRESEARCH_API_KEY},
        model     => 'Hermes-4-70B',
        reasoning => 1,
    );

    my $response = $nous->simple_chat('Solve this step by step...');
    say $response;                  # clean answer
    say $response->thinking;        # chain-of-thought reasoning

    # MCP tool calling (via HermesTools role)
    use Future::AsyncAwait;

    my $nous = Langertha::Engine::NousResearch->new(
        api_key     => $ENV{NOUSRESEARCH_API_KEY},
        model       => 'Hermes-4-70B',
        mcp_servers => [$mcp],
    );

    my $response = await $nous->chat_with_tools_f('Add 7 and 15');

=head1 DESCRIPTION

Provides access to Nous Research's inference API. Composes
L<Langertha::Role::OpenAICompatible> with Nous's endpoint
(C<https://inference-api.nousresearch.com/v1>) and Hermes tool calling.

Available models: C<Hermes-4-70B> (default), C<Hermes-4-405B>,
C<Hermes-4.3-36B>.

The endpoint is a gateway that also routes many non-Hermes models (Claude,
GPT, Gemini, ...) to their real backends. The tool wire is therefore chosen
B<per model>: a Hermes model (C<Hermes-*>, C<DeepHermes-*>) uses the Hermes
prompt format, and every other slug uses native OpenAI C<tools>. Override
C<tool_wire_format> (C<hermes> | C<openai>) to force either wire on any slug.

For a Hermes model, L<Langertha::Role::HermesTools> injects tool descriptions
into the system prompt as C<< <tools> >> XML and parses C<< <tool_call> >> tags
from the model output; no server-side tool calling is required. This is also
the more robust wire for Hermes 4, which intermittently emits its tool calls
as C<< <tool_call> >> text even when native calling is offered. The prompt
cannot force a tool, so on the Hermes wire the engine does not claim
C<tool_choice_named>: L<Langertha::Role::Chat/chat_f> answers a forced tool
with a C<json_schema> C<response_format> (the schema also goes into the system
prompt) and puts the parsed reply on L<Langertha::Response/tool_calls> as a
synthetic call. For a non-Hermes slug the tools and a forced C<tool_choice> go
out natively.

Get your API key at L<https://portal.nousresearch.com/> and set
C<LANGERTHA_NOUSRESEARCH_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 reasoning

    reasoning => 1

Enable chain-of-thought reasoning for Hermes 4 and DeepHermes 3 models.
Prepends the standard Nous reasoning system prompt that instructs the model
to use C<E<lt>thinkE<gt>> tags. The thinking content is automatically
extracted into L<Langertha::Response/thinking> by L<Langertha::Role::ThinkTag>.
This is a Hermes-model feature: on a non-Hermes slug the prompt is ignored
with a warning (the gate is the model, not C<tool_wire_format>, so forcing the
C<openai> tool wire on a genuine Hermes model still enables reasoning).

With DeepHermes 3, reasoning output appears inline as C<E<lt>thinkE<gt>> tags
(handled by the think tag filter). With Hermes 4 (without response prefill),
reasoning appears in the C<reasoning_content> response field (handled by
native extraction).

Defaults to C<0> (disabled).

=head2 reasoning_prompt

The system prompt prepended when C<reasoning> is enabled. Defaults to the
standard Nous Research reasoning prompt from the Hermes model documentation.
Unless you have a specific technical reason (e.g. a different model requires
a different trigger format), it is strongly recommended to keep the default.

=head1 SEE ALSO

=over

=item * L<https://nousresearch.com/> - Nous Research homepage

=item * L<https://portal.nousresearch.com/api-docs> - API documentation

=item * L<Langertha::Role::HermesTools> - Hermes-style tool calling via XML tags

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

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
