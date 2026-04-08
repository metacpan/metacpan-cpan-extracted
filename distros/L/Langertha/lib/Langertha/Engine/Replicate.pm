package Langertha::Engine::Replicate;
# ABSTRACT: Replicate API
our $VERSION = '0.400';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.replicate.com/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_REPLICATE_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_REPLICATE_API_KEY or api_key set";
}

sub default_model { croak "".(ref $_[0])." requires model to be set" }

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Replicate - Replicate API

=head1 VERSION

version 0.400

=head1 SYNOPSIS

    use Langertha::Engine::Replicate;

    my $replicate = Langertha::Engine::Replicate->new(
        api_key => $ENV{REPLICATE_API_TOKEN},
        model   => 'meta/llama-4-maverick',
    );

    print $replicate->simple_chat('Hello from Perl!');

    # Streaming
    $replicate->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a Perl haiku');

=head1 DESCRIPTION

Provides access to Replicate's OpenAI-compatible chat endpoint. Replicate
hosts thousands of open-source models with pay-per-use pricing.

Model names use C<owner/model> format (e.g., C<meta/llama-4-maverick>,
C<meta/llama-4-scout>). No default model is set; C<model> must be specified
explicitly.

Supports chat, streaming, and MCP tool calling via the OpenAI-compatible
endpoint at C<https://api.replicate.com/v1>. Embeddings and transcription
are not supported through this interface.

Get your API token at L<https://replicate.com/account/api-tokens> and set
C<LANGERTHA_REPLICATE_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://www.replicatestatus.com/> - Replicate service status

=item * L<https://replicate.com/docs/topics/openai-compatibility> - Replicate OpenAI compatibility docs

=item * L<https://replicate.com/explore> - Browse available models

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
