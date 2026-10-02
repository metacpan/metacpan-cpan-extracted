package Langertha::Engine::OllamaOpenAI;
# ABSTRACT: Ollama via OpenAI-compatible API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding', 'Langertha::Role::Tools';


has '+url' => (
  required => 1,
);

sub default_model { croak "".(ref $_[0])." requires model to be set" }
sub default_embedding_model { 'mxbai-embed-large' }

# Ollama's /v1 takes base64 images only, no image URLs
# (docs.ollama.com/api/openai-compatibility), karr k267.
sub _content_inline_images_only { 1 }

# Shares the Ollama key (derivation would name LANGERTHA_OLLAMAOPENAI_API_KEY)
# and, like the native engine, only needs it for Ollama Cloud.
sub api_key_env { 'LANGERTHA_OLLAMA_API_KEY' }
sub api_key_required { 0 }

sub _build_api_key {
  return $ENV{LANGERTHA_OLLAMA_API_KEY};
}


sub _build_supported_operations {[qw( createChatCompletion createEmbedding )]}

# Ollama's OpenAI-compatible /v1 endpoint does not support tool_choice at all —
# its own compatibility checklist marks it unimplemented, and the Go server has
# no DisallowUnknownFields, so a tool_choice is accepted, IGNORED, and answered
# HTTP 200 (docs.ollama.com/api/openai-compatibility, verified 2026-09-01). A
# silently-dropped tool_choice is the dangerous case — the caller believes the
# tool was forced — so clear every tool_choice flag; tools_native stays (the
# `tools` array itself works).
# prompt_cache_key is not a field of Ollama's /v1 ChatCompletionRequest struct
# (openai/openai.go; Go's decoder drops it) -- only the /v1/responses shim
# echoes it back as null (checked 2026-09-25, karr #200). Clear it too.
# parallel_tool_calls is not a field of that struct either (same file, main
# 2026-09-24): clear parallel_tool_use (karr k241). The OpenAI envelope sends
# neither tool_choice nor parallel_tool_calls without the flag (k239, k241).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete @{$caps}{ qw(
    tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
    prompt_cache_key parallel_tool_use
  ) };
  return $caps;
};

# image_input (k266, ADR 0019): self-hosted: the served model is launch state
# the client cannot see, so no static claim. A layer-3 catch-all rather than a
# layer-2 delete, so a fact probed from the server's /api/show can answer per
# model (ADR 0032).
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

sub model_metadata_format { 'ollama' }
sub model_metadata_url {
  return Langertha::ModelProbe->server_root_url( $_[0]->url ) . '/api/show';
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OllamaOpenAI - Ollama via OpenAI-compatible API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OllamaOpenAI;

    # Direct construction (url with /v1 suffix is required)
    my $ollama_oai = Langertha::Engine::OllamaOpenAI->new(
        url   => 'http://localhost:11434/v1',
        model => 'llama3.3',
    );

    print $ollama_oai->simple_chat('Hello!');

    # Streaming
    $ollama_oai->simple_chat_stream(sub {
        print shift->content;
    }, 'Tell me about Perl');

    # Preferred: create via Ollama's openai() method (appends /v1 automatically)
    use Langertha::Engine::Ollama;

    my $ollama = Langertha::Engine::Ollama->new(
        url   => 'http://localhost:11434',
        model => 'llama3.3',
    );
    my $oai = $ollama->openai;
    print $oai->simple_chat('Hello via OpenAI format!');

=head1 DESCRIPTION

Provides access to Ollama's OpenAI-compatible C</v1> API endpoint. Composes
L<Langertha::Role::OpenAICompatible> for the standard OpenAI format.

C<url> is required and must include the C</v1> path prefix (e.g.,
C<http://localhost:11434/v1>). When using L<Langertha::Engine::Ollama/openai>,
the C</v1> suffix is appended automatically.

Authentication is optional. A local server needs none; Ollama Cloud
(C<https://ollama.com/v1>) requires a bearer token — set L</api_key> or
C<LANGERTHA_OLLAMA_API_KEY>.

Supports chat completions (SSE streaming), embeddings (default:
C<mxbai-embed-large>), MCP tool calling, and dynamic model listing.
Transcription is not supported.

For the native Ollama API with C<keep_alive>, C<seed>, C<context_size>,
NDJSON streaming, and Hermes tool calling, use L<Langertha::Engine::Ollama>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

Optional bearer token, shared with L<Langertha::Engine::Ollama>. A local
server needs none; Ollama Cloud rejects unauthenticated requests with
HTTP 401. If not provided, reads from C<LANGERTHA_OLLAMA_API_KEY>. When
undefined, L<Langertha::Role::OpenAICompatible> sends no C<Authorization>
header.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Ollama> - Native Ollama API (with keep_alive, seed, context_size)

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role composed by this engine

=item * L<https://github.com/ollama/ollama> - Ollama project

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
