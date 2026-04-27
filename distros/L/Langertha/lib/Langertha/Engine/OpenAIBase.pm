package Langertha::Engine::OpenAIBase;
# ABSTRACT: Base class for OpenAI-compatible engines
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );
use Module::Runtime qw( use_module );

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  OpenAICompatible
  OpenAPI
  Models
  Temperature
  ResponseSize
  SystemPrompt
  ResponseFormat
  Streaming
  Chat
);

sub _build_openapi_operations {
  return use_module('Langertha::Spec::OpenAI')->data;
}


sub default_model { croak "".(ref $_[0])." requires model to be set" }


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenAIBase - Base class for OpenAI-compatible engines

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    package My::CompatibleEngine;
    use Moose;

    extends 'Langertha::Engine::OpenAIBase';

    has '+url' => ( default => 'https://api.example.com/v1' );

    sub _build_api_key {
        return $ENV{MY_API_KEY} || die "MY_API_KEY required";
    }

    sub default_model { 'my-model-v1' }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Intermediate base class for all engines that speak the OpenAI
C</chat/completions> API format. Extends L<Langertha::Engine::Remote> and
composes the full set of OpenAI-compatible roles:
L<Langertha::Role::OpenAICompatible>, L<Langertha::Role::OpenAPI>,
L<Langertha::Role::Models>, L<Langertha::Role::Temperature>,
L<Langertha::Role::ResponseSize>, L<Langertha::Role::SystemPrompt>,
L<Langertha::Role::Streaming>, and L<Langertha::Role::Chat>.

Subclasses must override C<default_model> to return their default model name.
They also typically override C<_build_api_key> to read from an environment
variable, and C<has '+url'> to supply a default API endpoint.

Concrete engines that extend this class:

=over 4

=item * Cloud providers — L<Langertha::Engine::OpenAI>, L<Langertha::Engine::DeepSeek>,
L<Langertha::Engine::Groq>, L<Langertha::Engine::Mistral>,
L<Langertha::Engine::Cerebras>, L<Langertha::Engine::MiniMax>,
L<Langertha::Engine::NousResearch>, L<Langertha::Engine::OpenRouter>,
L<Langertha::Engine::Replicate>, L<Langertha::Engine::HuggingFace>,
L<Langertha::Engine::Perplexity>, L<Langertha::Engine::AKIOpenAI>,
L<Langertha::Engine::TSystems>, L<Langertha::Engine::Scaleway>

=item * Self-hosted — L<Langertha::Engine::OllamaOpenAI>,
L<Langertha::Engine::vLLM>, L<Langertha::Engine::SGLang>,
L<Langertha::Engine::LlamaCpp>, L<Langertha::Engine::LMStudioOpenAI>

=back

For transcription-only engines (Whisper-style) see
L<Langertha::Engine::TranscriptionBase>; that base does I<not>
compose Chat/Tools/Embedding/ImageGeneration so callers get a focused
audio-transcription handle.

=head2 default_model

Abstract. Subclasses must override this to return the default model name
string. The base implementation croaks with a descriptive error message.

    sub default_model { 'gpt-4o-mini' }

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Remote> - Parent base class

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format (chat, embeddings, tools, streaming)

=item * L<Langertha::Role::Chat> - C<simple_chat>, C<simple_chat_f>, streaming methods

=item * L<Langertha::Role::Models> - C<model>, C<models>, C<list_models>

=item * L<Langertha::Role::Temperature> - C<temperature> attribute

=item * L<Langertha::Role::ResponseSize> - C<response_size> / C<max_tokens>

=item * L<Langertha::Role::SystemPrompt> - C<system_prompt> attribute

=item * L<Langertha::Role::Streaming> - SSE stream parsing

=item * L<Langertha::Engine::OpenAI> - Canonical OpenAI engine

=item * L<Langertha::Engine::Groq> - Groq ultra-fast inference

=item * L<Langertha::Engine::DeepSeek> - DeepSeek reasoning models

=item * L<Langertha::Engine::OllamaOpenAI> - Ollama OpenAI-compatible endpoint

=item * L<Langertha::Engine::vLLM> - vLLM high-throughput inference server

=item * L<Langertha::Engine::SGLang> - SGLang OpenAI-compatible endpoint

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
