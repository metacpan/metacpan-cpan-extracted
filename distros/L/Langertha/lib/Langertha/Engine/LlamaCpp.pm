package Langertha::Engine::LlamaCpp;
# ABSTRACT: llama.cpp server
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding',
     'Langertha::Role::Tools',
     'Langertha::Role::Runtime::MetricsPoll',
     'Langertha::Role::RuntimeKnobs';

# llama.cpp's per-request runtime knobs: cache_prompt, n_cache_reuse, id_slot.
# Speculative decoding is a server-launch flag (--spec-draft-*), not a request
# knob — see Langertha::Runtime::Knobs.
sub _build_knob_wire_format { 'llamacpp' }


sub default_model { 'default' }
# No fixed embedding model: the caller's model, else no model field (k297).
sub default_embedding_model { undef }

# llama-server parses no dimensions field and drops it silently (k319).
sub _embedding_dimensions_field { undef }

# LANGERTHA_LLAMACPP_API_KEY is derived from the class name; a local server
# needs no key, a --api-key-protected `llama-server` does.
sub api_key_required { 0 }

sub _build_api_key {
  return $ENV{LANGERTHA_LLAMACPP_API_KEY};
}

sub _build_supported_operations {[qw(
  createChatCompletion
  createEmbedding
)]}

# llama.cpp's server parses tool_choice as a std::string, so the object (named)
# form is SILENTLY downgraded to "auto" — the forced tool never binds, and
# `strict` is ignored (ggml-org/llama.cpp common/chat.cpp, verified
# 2026-09-01). Clear tool_choice_named so chat_f does not believe it can force a
# specific tool here; the string forms (auto/any->required/none) are parsed and
# stay.
# prompt_cache_key (OpenAI's cache-routing hint) is neither documented for the
# server's /v1/chat/completions (tools/server/README.md) nor read by it (no
# reference in the source; checked 2026-09-25, karr #200). The server's own
# prefix-cache levers are cache_prompt / n_cache_reuse / id_slot via
# RuntimeKnobs, so clear the flag.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete @{$caps}{ qw( tool_choice_named prompt_cache_key ) };
  return $caps;
};

# image_input (k266, ADR 0019): self-hosted: the served model is launch state
# the client cannot see, so no static claim. A layer-3 catch-all rather than a
# layer-2 delete, so a fact probed from /props (modalities.vision) can answer
# (ADR 0032). The server has one model, so the fact is stored under whatever
# id the probe was asked about (chat_model, 'default' unless set).
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

sub model_metadata_format { 'llamacpp' }
sub model_metadata_url {
  return Langertha::ModelProbe->server_root_url( $_[0]->url ) . '/props';
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::LlamaCpp - llama.cpp server

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::LlamaCpp;

    my $llama = Langertha::Engine::LlamaCpp->new(
        url           => 'http://localhost:8080/v1',
        system_prompt => 'You are a helpful assistant',
    );

    print $llama->simple_chat('Hello!');

    my $embedding = $llama->simple_embedding('Some text');

=head1 DESCRIPTION

Provides access to llama.cpp's built-in HTTP server, which exposes an
OpenAI-compatible API. Composes L<Langertha::Role::OpenAICompatible>.

Only C<url> is required. The URL must include the C</v1> path prefix
(e.g., C<http://localhost:8080/v1>). Since llama.cpp serves exactly one
model (loaded at server startup), no model name or API key is needed.

Supports chat, streaming, embeddings, and MCP tool calling.

L<Langertha::Role::Embedding/embedding_dimensions> is not sent (it carps
once): llama.cpp's server does not parse a C<dimensions> field, drops it
silently and returns the full vector.

See L<https://github.com/ggml-org/llama.cpp/blob/master/examples/server/README.md>
for server setup.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://github.com/ggml-org/llama.cpp> - llama.cpp project

=item * L<Langertha::Engine::vLLM> - Another self-hosted OpenAI-compatible engine

=item * L<Langertha::Engine::OllamaOpenAI> - Ollama's OpenAI-compatible API

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
