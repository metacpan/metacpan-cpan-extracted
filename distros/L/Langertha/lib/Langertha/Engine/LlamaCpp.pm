package Langertha::Engine::LlamaCpp;
# ABSTRACT: llama.cpp server
our $VERSION = '0.308';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding';
with 'Langertha::Role::Tools';


sub default_model { 'default' }
sub default_embedding_model { 'default' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createEmbedding
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::LlamaCpp - llama.cpp server

=head1 VERSION

version 0.308

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
