package Langertha::Engine::OpenAI;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: OpenAI API
$Langertha::Engine::OpenAI::VERSION = '0.008';
use Moose;
use File::ShareDir::ProjectDistDir qw( :all );
use Carp qw( croak );
use JSON::MaybeXS;

with 'Langertha::Role::'.$_ for (qw(
  JSON
  HTTP
  OpenAPI
  Models
  Temperature
  ResponseSize
  ResponseFormat
  SystemPrompt
  Chat
  Embedding
  Transcription
));

sub all_models {qw(
  babbage-002
  chatgpt-4o-latest
  dall-e-2
  dall-e-3
  davinci-002
  gpt-3.5-turbo
  gpt-3.5-turbo-0125
  gpt-3.5-turbo-1106
  gpt-3.5-turbo-16k
  gpt-3.5-turbo-instruct
  gpt-3.5-turbo-instruct-0914
  gpt-4
  gpt-4-0125-preview
  gpt-4-0613
  gpt-4-1106-preview
  gpt-4-turbo
  gpt-4-turbo-2024-04-09
  gpt-4-turbo-preview
  gpt-4.5-preview
  gpt-4.5-preview-2025-02-27
  gpt-4o
  gpt-4o-2024-05-13
  gpt-4o-2024-08-06
  gpt-4o-2024-11-20
  gpt-4o-audio-preview
  gpt-4o-audio-preview-2024-10-01
  gpt-4o-audio-preview-2024-12-17
  gpt-4o-mini
  gpt-4o-mini-2024-07-18
  gpt-4o-mini-audio-preview
  gpt-4o-mini-audio-preview-2024-12-17
  gpt-4o-mini-realtime-preview
  gpt-4o-mini-realtime-preview-2024-12-17
  gpt-4o-mini-search-preview
  gpt-4o-mini-search-preview-2025-03-11
  gpt-4o-mini-transcribe
  gpt-4o-mini-tts
  gpt-4o-realtime-preview
  gpt-4o-realtime-preview-2024-10-01
  gpt-4o-realtime-preview-2024-12-17
  gpt-4o-search-preview
  gpt-4o-search-preview-2025-03-11
  gpt-4o-transcribe
  o1
  o1-2024-12-17
  o1-mini
  o1-mini-2024-09-12
  o1-preview
  o1-preview-2024-09-12
  o1-pro
  o1-pro-2025-03-19
  o3-mini
  o3-mini-2025-01-31
  omni-moderation-2024-09-26
  omni-moderation-latest
  text-embedding-3-large
  text-embedding-3-small
  text-embedding-ada-002
  tts-1
  tts-1-1106
  tts-1-hd
  tts-1-hd-1106
  whisper-1
)}

has compatibility_for_engine => (
  is => 'ro',
  predicate => 'has_compatibility_for_engine',
);

has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_OPENAI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_OPENAI_API_KEY or api_key set";
}

sub update_request {
  my ( $self, $request ) = @_;
  $request->header('Authorization', 'Bearer '.$self->api_key);
}

sub default_model { 'gpt-4o-mini' }
sub default_embedding_model { 'text-embedding-3-large' }
sub default_transcription_model { 'whisper-1' }

sub openapi_file { yaml => dist_file('Langertha','openai.yaml') };

sub embedding_operation_id { 'createEmbedding' }

sub embedding_request {
  my ( $self, $input, %extra ) = @_;
  return $self->generate_request( $self->embedding_operation_id, sub { $self->embedding_response(shift) },
    model => $self->embedding_model,
    input => $input,
    %extra,
  );
}

sub embedding_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  # tracing
  my @objects = @{$data->{data}};
  return $objects[0]->{embedding};
}

sub chat_operation_id { 'createChatCompletion' }

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  return $self->generate_request( $self->chat_operation_id, sub { $self->chat_response(shift) },
    model => $self->chat_model,
    messages => $messages,
    $self->get_response_size ? ( max_tokens => $self->get_response_size ) : (),
    $self->has_response_format ? ( response_format => $self->response_format ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    stream => JSON->false,
    # $self->has_seed ? ( seed => $self->seed )
    #   : $self->randomize_seed ? ( seed => round(rand(100_000_000)) ) : (),
    %extra,
  );
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  # tracing
  my @messages = map { $_->{message} } @{$data->{choices}};
  return $messages[0]->{content};
}

sub transcription_operation_id { 'createTranscription' }

sub transcription_request {
  my ( $self, $file, %extra ) = @_;
  return $self->generate_request( $self->transcription_operation_id, sub { $self->transcription_response(shift) },
    file => [ $file ],
    $self->transcription_model ? ( model => $self->transcription_model ) : (),
    %extra,
  );
}

sub transcription_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  return $data->{text};
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenAI - OpenAI API

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use Langertha::Engine::OpenAI;

  my $openai = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
    model => 'gpt-4o-mini',
    system_prompt => 'You are a helpful assistant',
    temperature => 0.5,
  );

  print($openai->simple_chat('Say something nice'));

  my $embedding = $openai->embedding($content);

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

=head1 HOW TO GET OPENAI API KEY

L<https://platform.openai.com/docs/quickstart>

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
