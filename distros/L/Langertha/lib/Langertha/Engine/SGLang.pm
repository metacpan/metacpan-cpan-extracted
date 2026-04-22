package Langertha::Engine::SGLang;
# ABSTRACT: SGLang inference server
our $VERSION = '0.404';
use Moose;

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

Langertha::Engine::SGLang - SGLang inference server

=head1 VERSION

version 0.404

=head1 SYNOPSIS

    use Langertha::Engine::SGLang;

    my $sglang = Langertha::Engine::SGLang->new(
        url   => 'http://localhost:30000/v1',
        model => 'Qwen/Qwen2.5-7B-Instruct',
    );

    print $sglang->simple_chat('Say something nice');

=head1 DESCRIPTION

Adapter for SGLang's OpenAI-compatible endpoint.
SGLang is typically exposed as C</v1/chat/completions> with optional
tool-calling support depending on model/backend setup.

Only C<url> is required. Use the full C</v1> base URL.
No API key is required for local setups.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://docs.sglang.ai/> - SGLang documentation

=item * L<Langertha::Engine::OpenAIBase> - Base class for OpenAI-compatible engines

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Engine::vLLM> - Similar self-hosted OpenAI-compatible engine

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
