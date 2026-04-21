package Langertha::Engine::vLLM;
# ABSTRACT: vLLM inference server
our $VERSION = '0.402';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  required => 1,
);

sub default_model { 'default' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createCompletion
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::vLLM - vLLM inference server

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    use Langertha::Engine::vLLM;

    my $vllm = Langertha::Engine::vLLM->new(
        url           => 'http://localhost:8000/v1',
        system_prompt => 'You are a helpful assistant',
    );

    print $vllm->simple_chat('Say something nice');

    # MCP tool calling (requires server started with tool-call-parser)
    use Future::AsyncAwait;

    my $vllm = Langertha::Engine::vLLM->new(
        url         => 'http://localhost:8000/v1',
        model       => 'Qwen/Qwen2.5-3B-Instruct',
        mcp_servers => [$mcp],
    );

    my $response = await $vllm->chat_with_tools_f('Add 7 and 15');

=head1 DESCRIPTION

Provides access to vLLM, a high-throughput inference engine for large
language models. Composes L<Langertha::Role::OpenAICompatible> since vLLM
exposes an OpenAI-compatible API.

Only C<url> is required. The URL must include the C</v1> path prefix
(e.g., C<http://localhost:8000/v1>). Since vLLM serves exactly one model
(configured at server startup), no model name or API key is needed.

MCP tool calling requires the vLLM server to be started with
C<--enable-auto-tool-choice> and C<--tool-call-parser> matching the model
(C<hermes> for Qwen2.5/Hermes, C<llama3> for Llama, C<mistral> for Mistral).

See L<https://docs.vllm.ai/> for installation and configuration details.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://docs.vllm.ai/> - vLLM documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Engine::OllamaOpenAI> - Another self-hosted OpenAI-compatible engine

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
