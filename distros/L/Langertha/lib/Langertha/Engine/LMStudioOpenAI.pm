package Langertha::Engine::LMStudioOpenAI;
# ABSTRACT: LM Studio via OpenAI-compatible API
our $VERSION = '0.503';
use Moose;

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding', 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'http://localhost:1234/v1' },
);

sub _build_api_key {
  return $ENV{LANGERTHA_LMSTUDIO_API_KEY} || 'lmstudio';
}


sub default_model { 'default' }
# No fixed embedding model: the caller's model, else no model field (k297).
sub default_embedding_model { undef }

# LM Studio documents no dimensions field for /v1/embeddings (k319).
sub _embedding_dimensions_field { undef }

# Shares the LM Studio key with the native engine (derivation would name the
# protocol variant); optional, the local server accepts the 'lmstudio' dummy.
sub api_key_env { 'LANGERTHA_LMSTUDIO_API_KEY' }
sub api_key_required { 0 }


sub _build_supported_operations {[qw(
  createChatCompletion
  createEmbedding
)]}

# LM Studio documents a closed parameter list for /v1/chat/completions
# (lmstudio.ai/docs/developer/openai-compat/chat-completions) and
# prompt_cache_key is not on it (checked 2026-09-25, karr #200), so the
# OpenAI cache-routing hint is not advertised (ADR 0002 layer 2).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{prompt_cache_key};
  return $caps;
};

# image_input (k266, ADR 0019): self-hosted: the served model is launch state
# the client cannot see, so no static claim. A layer-3 catch-all rather than a
# layer-2 delete, so a fact probed from the server's native /api/v1/models
# (capabilities.vision) can answer per model (ADR 0032).
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

sub model_metadata_format { 'lmstudio' }
sub model_metadata_url {
  return Langertha::ModelProbe->server_root_url( $_[0]->url ) . '/api/v1/models';
}

__PACKAGE__->meta->make_immutable;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::LMStudioOpenAI - LM Studio via OpenAI-compatible API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::LMStudioOpenAI;

    # 1. Simple chat
    my $lm_oai = Langertha::Engine::LMStudioOpenAI->new(
        url   => 'http://localhost:1234/v1',
        model => 'qwen2.5-7b-instruct-1m',
    );

    print $lm_oai->simple_chat('Hello from OpenAI-compatible endpoint');

    # 2. Streaming
    $lm_oai->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a haiku about Perl');

    # 3. Embeddings (LM Studio serves /v1/embeddings when an embedding
    #    model is loaded)
    my $vector = $lm_oai->simple_embedding('Some text to embed');

    # 4. MCP tool calling (LM Studio supports native tool calling via the
    #    OpenAI-compatible /v1 endpoint for compatible models)
    use Future::AsyncAwait;

    my $lm_oai = Langertha::Engine::LMStudioOpenAI->new(
        url         => 'http://localhost:1234/v1',
        model       => 'qwen2.5-7b-instruct-1m',
        mcp_servers => [$mcp],
    );

    my $response = await $lm_oai->chat_with_tools_f('Add 7 and 15');

=head1 DESCRIPTION

Adapter for LM Studio's OpenAI-compatible local endpoint
(C</v1/chat/completions>, C</v1/models>, C</v1/embeddings>).

Extends L<Langertha::Engine::OpenAIBase> (which composes
L<Langertha::Role::OpenAICompatible>, L<Langertha::Role::OpenAPI>,
L<Langertha::Role::Models>, L<Langertha::Role::Temperature>,
L<Langertha::Role::ResponseSize>, L<Langertha::Role::SystemPrompt>,
L<Langertha::Role::ResponseFormat>, L<Langertha::Role::Streaming>,
L<Langertha::Role::Chat>, L<Langertha::Role::ReasoningEffort>, and
L<Langertha::Role::PromptCache>); LMStudioOpenAI itself additionally
composes L<Langertha::Role::Embedding> (C</v1/embeddings>) and
L<Langertha::Role::Tools> (MCP tool calling).

L<Langertha::Role::Embedding/embedding_dimensions> is not sent (it carps
once): LM Studio does not document a C<dimensions> field for
C</v1/embeddings>, so whether it is honored is unknown.

Authentication is optional. If C<api_key> (or C<LANGERTHA_LMSTUDIO_API_KEY>)
is set, it is sent as a bearer token.

B<Runtime metrics:> LM Studio does not expose a Prometheus C</metrics>
endpoint, so L<Langertha::Role::Runtime::MetricsPoll> is intentionally
B<not> composed here. Sister engines that do (vLLM, SGLang, llama.cpp)
expose Prometheus text-format metrics at the server root.

=head2 api_key

Optional bearer token for LM Studio's OpenAI-compatible endpoint.
If not provided, reads from C<LANGERTHA_LMSTUDIO_API_KEY> and otherwise
defaults to C<lmstudio>.

=head2 model

Chat model name. Defaults to C<default>. For real requests, set this to
an actually loaded LM Studio model key (for example
C<qwen2.5-7b-instruct-1m>).

=head1 CAPABILITIES

Advertised flags (derived from composed roles via L<Langertha::Role::Capabilities>):

=over 4

=item * C<chat> — L<Langertha::Role::Chat>

=item * C<streaming> — L<Langertha::Role::Streaming>

=item * C<tools_native> + C<tool_choice_{auto,any,none,named}> — L<Langertha::Role::Tools>

=item * C<embedding> — L<Langertha::Role::Embedding>

=item * C<response_format_{json_object,json_schema}> — L<Langertha::Role::ResponseFormat>

=item * C<temperature> — L<Langertha::Role::Temperature>

=item * C<response_size>, C<system_prompt>, C<parallel_tool_use>, C<context_size>, C<seed>
— generation-parameter knobs the engine will honour

=back

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::LMStudio> - Native LM Studio API

=item * L<Langertha::Engine::OpenAIBase> - Base class for OpenAI-compatible engines

=item * L<Langertha::Engine::vLLM> - Sister self-hosted OpenAI-compatible engine (also Embedding)

=item * L<Langertha::Engine::LlamaCpp> - Sister self-hosted OpenAI-compatible engine (also Embedding)

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
