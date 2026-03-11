package Langertha::Engine::Mistral;
# ABSTRACT: Mistral API
our $VERSION = '0.307';
use Moose;
use Carp qw( croak );

use File::ShareDir::ProjectDistDir qw( :all );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::'.$_ for (qw(
  ResponseFormat
  Embedding
  Tools
));


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.mistral.ai' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MISTRAL_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MISTRAL_API_KEY or api_key set";
}

sub openapi_file { yaml => dist_file('Langertha','mistral.yaml') };

sub _build_openapi_operations {
  require Langertha::Spec::Mistral;
  return Langertha::Spec::Mistral::data();
}

sub default_model { 'mistral-small-latest' }

sub chat_operation_id { 'chat_completion_v1_chat_completions_post' }

sub list_models_path { '/v1/models' }

sub embedding_operation_id { 'embeddings_v1_embeddings_post' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Mistral - Mistral API

=head1 VERSION

version 0.307

=head1 SYNOPSIS

    use Langertha::Engine::Mistral;

    my $mistral = Langertha::Engine::Mistral->new(
        api_key      => $ENV{MISTRAL_API_KEY},
        model        => 'mistral-large-latest',
        system_prompt => 'You are a helpful assistant',
        temperature  => 0.5,
    );

    print $mistral->simple_chat('Say something nice');

    my $embedding = $mistral->embedding($content);

=head1 DESCRIPTION

Provides access to Mistral AI's models via their API. Composes
L<Langertha::Role::OpenAICompatible> with Mistral's endpoint
(C<https://api.mistral.ai>) and its OpenAPI spec.

Popular models: C<mistral-small-latest> (default, fast), C<mistral-large-latest>
(most capable, 675B parameters), C<codestral-latest> (code generation),
C<devstral-latest> (development workflows), C<pixtral-large-latest> (vision).
Supports chat, embeddings, and tool calling; transcription is not available.

Dynamic model listing via C<list_models()>. Get your API key at
L<https://docs.mistral.ai/getting-started/quickstart/> and set
C<LANGERTHA_MISTRAL_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://status.mistral.ai/> - Mistral service status

=item * L<https://mistral.ai/models> - Official Mistral models documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Engine::DeepSeek> - Another OpenAI-compatible engine

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
