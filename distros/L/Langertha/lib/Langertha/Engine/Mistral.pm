package Langertha::Engine::Mistral;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Mistral API
$Langertha::Engine::Mistral::VERSION = '0.008';
use Moose;
extends 'Langertha::Engine::OpenAI';
use Carp qw( croak );

use File::ShareDir::ProjectDistDir qw( :all );

sub all_models {qw(
  codestral-2405
  codestral-2411-rc5
  codestral-2412
  codestral-2501
  codestral-latest
  codestral-mamba-2407
  codestral-mamba-latest
  ministral-3b-2410
  ministral-3b-latest
  ministral-8b-2410
  ministral-8b-latest
  mistral-embed
  mistral-large-2402
  mistral-large-2407
  mistral-large-2411
  mistral-large-latest
  mistral-large-pixtral-2411
  mistral-medium
  mistral-medium-2312
  mistral-medium-latest
  mistral-moderation-2411
  mistral-moderation-latest
  mistral-ocr-2503
  mistral-ocr-latest
  mistral-saba-2502
  mistral-saba-latest
  mistral-small
  mistral-small-2312
  mistral-small-2402
  mistral-small-2409
  mistral-small-2501
  mistral-small-2503
  mistral-small-latest
  mistral-tiny
  mistral-tiny-2312
  mistral-tiny-2407
  mistral-tiny-latest
  open-codestral-mamba
  open-mistral-7b
  open-mistral-nemo
  open-mistral-nemo-2407
  open-mixtral-8x22b
  open-mixtral-8x22b-2404
  open-mixtral-8x7b
  pixtral-12b
  pixtral-12b-2409
  pixtral-12b-latest
  pixtral-large-2411
  pixtral-large-latest
)}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.mistral.ai' },
);
around has_url => sub { 1 };

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MISTRAL_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MISTRAL_API_KEY or api_key set";
}

sub openapi_file { yaml => dist_file('Langertha','mistral.yaml') };

sub default_model { 'mistral-small-latest' }

sub chat_operation_id { 'chat_completion_v1_chat_completions_post' }

sub embedding_operation_id { 'embeddings_v1_embeddings_post' }

sub transcription_request {
  croak "".(ref $_[0])." doesn't support transcription";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Mistral - Mistral API

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use Langertha::Engine::Mistral;

  my $mistral = Langertha::Engine::Mistral->new(
    api_key => $ENV{MISTRAL_API_KEY},
    model => 'mistral-large-latest',
    system_prompt => 'You are a helpful assistant',
    temperature => 0.5,
  );

  print($mistral->simple_chat('Say something nice'));

  my $embedding = $mistral->embedding($content);

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

=head1 HOW TO GET MISTRAL API KEY

L<https://docs.mistral.ai/getting-started/quickstart/>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/langertha>

  git clone https://github.com/Getty/langertha.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
