package Langertha::Engine::AnthropicBase;
# ABSTRACT: Base class for Anthropic-compatible engines
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::Remote';

with 'Langertha::Role::Models',
     # Role::Chat::content_format defaults to 'openai'; AnthropicCompatible (composed last) supplies 'anthropic'.
     'Langertha::Role::Chat' => { -excludes => ['content_format'] },
     'Langertha::Role::Temperature',
     # Role::ReasoningEffort::_build_reasoning_wire_format defaults to 'openai'; AnthropicCompatible supplies 'anthropic'.
     'Langertha::Role::ReasoningEffort' => { -excludes => ['_build_reasoning_wire_format'] },
     # Role::PromptCache::_build_cache_wire_format defaults to 'openai'; AnthropicCompatible supplies 'anthropic'.
     'Langertha::Role::PromptCache' => { -excludes => ['_build_cache_wire_format'] },
     'Langertha::Role::ResponseSize',
     'Langertha::Role::SystemPrompt',
     'Langertha::Role::ResponseFormat',
     'Langertha::Role::Streaming',
     'Langertha::Role::ImageInput',
     # Role::Tools::_build_tool_wire_format defaults to 'openai'; AnthropicCompatible supplies 'anthropic'.
     'Langertha::Role::Tools' => { -excludes => ['_build_tool_wire_format'] },
     'Langertha::Role::AnthropicCompatible';

# The Anthropic family has the cache_control enable breakpoint but no OpenAI-style
# routing key. Clear the key flag so only the enable flag is advertised (ADR 0002).
# Partner direction: Langertha::Engine::OpenAIBase runs the symmetric
# correction and deletes prompt_cache, keeping prompt_cache_key. The pair is
# canon in L<ADR 0015|docs/adr/0015-role-composition-patterns.md>.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{prompt_cache_key};
  return $caps;
};

# Back-compat: the documented `effort => 'high'` constructor keeps working as an
# alias of the new normalized `reasoning_effort`. Both attributes stay readable;
# only the wire placement changed (top-level `effort` -> output_config.effort +
# thinking:{type:adaptive}, via Langertha::Reasoning).
around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  if ( exists $args->{effort} && !exists $args->{reasoning_effort} ) {
    $args->{reasoning_effort} = $args->{effort};
  }
  return $args;
};


sub default_model { croak "".(ref $_[0])." requires model to be set" }


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::AnthropicBase - Base class for Anthropic-compatible engines

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    package My::AnthropicCompatible;
    use Moose;

    extends 'Langertha::Engine::AnthropicBase';

    has '+url' => ( default => sub { 'https://api.example.com' } );

    sub _build_api_key { $ENV{MY_API_KEY} || die "MY_API_KEY required" }
    sub default_model { 'my-model-v1' }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Intermediate base class for engines speaking the Anthropic-compatible
C</v1/messages> format. Extends L<Langertha::Engine::Remote> and composes
the universal chat/streaming/tool roles plus the Anthropic wire envelope,
which lives in L<Langertha::Role::AnthropicCompatible> (parallel to the
OpenAI envelope in L<Langertha::Role::OpenAICompatible>). This class is a
thin composition shell: the request/response/auth/stream/rate-limit envelope
for the Anthropic dialect is owned by the role.

Concrete engines extending this class include
L<Langertha::Engine::Anthropic>, L<Langertha::Engine::AKIAnthropic>,
L<Langertha::Engine::MiniMaxAnthropic>,
L<Langertha::Engine::MoonshotAnthropic>, and
L<Langertha::Engine::LMStudioAnthropic>.

Structured output (C<response_format>) takes one of two wire paths depending on
the engine. The first-party L<Langertha::Engine::Anthropic> emits it natively as
C<output_config.format> (GA on the Claude Messages API), which streams as
ordinary text and needs no post-processing. The legacy C</anthropic> shim
engines have no native form and keep the ADR 0005 rewrite: a synthesized tool
plus a forced C<tool_choice>, whose C<tool_use> input C<chat_response> lifts
back into C<Response.content>. That lift has no streaming counterpart, so on a
shim engine C<chat_stream_request> consumes a C<response_format> and croaks
instead of silently streaming unstructured text — use
L<Langertha::Role::Chat/chat_f> or C<chat_request> there. See ADR 0005.

B<THIS API IS WORK IN PROGRESS>

=head2 default_model

Abstract. Subclasses must override this to return the default model name
string. The base implementation croaks with a descriptive error message.

    sub default_model { 'claude-sonnet-5' }

=head1 SEE ALSO

=over

=item * L<https://status.anthropic.com/> - Anthropic service status

=item * L<https://docs.anthropic.com/> - Official Anthropic documentation

=item * L<Langertha::Role::AnthropicCompatible> - Anthropic wire envelope role

=item * L<Langertha::Role::OpenAICompatible> - The parallel OpenAI envelope role

=item * L<Langertha::Role::Chat> - Chat interface methods

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::Streaming> - Streaming support (SSE format)

=item * L<Langertha::Engine::Gemini> - Another non-OpenAI-compatible engine

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
