package Langertha::Engine::Cerebras;
# ABSTRACT: Cerebras Inference API
our $VERSION = '0.404';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.cerebras.ai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_CEREBRAS_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_CEREBRAS_API_KEY or api_key set";
}

sub default_model { 'llama3.1-8b' }

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Cerebras - Cerebras Inference API

=head1 VERSION

version 0.404

=head1 SYNOPSIS

    use Langertha::Engine::Cerebras;

    my $cerebras = Langertha::Engine::Cerebras->new(
        api_key => $ENV{CEREBRAS_API_KEY},
        model   => 'llama-3.3-70b',
    );

    print $cerebras->simple_chat('Hello from Perl!');

=head1 DESCRIPTION

Provides access to Cerebras Inference, the fastest AI inference platform.
Composes L<Langertha::Role::OpenAICompatible> with Cerebras's endpoint
(C<https://api.cerebras.ai/v1>) and API key handling.

Cerebras uses custom wafer-scale chips to deliver extremely fast inference
speeds. Available models include C<llama3.1-8b> (default), C<qwen-3-235b-a22b-instruct-2507>,
and C<gpt-oss-120b>.

Supports chat, streaming, and MCP tool calling. Embeddings and transcription
are not supported.

Get your API key at L<https://cloud.cerebras.ai/> and set
C<LANGERTHA_CEREBRAS_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://status.cerebras.ai/> - Cerebras service status

=item * L<https://inference-docs.cerebras.ai/> - Cerebras Inference documentation

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
