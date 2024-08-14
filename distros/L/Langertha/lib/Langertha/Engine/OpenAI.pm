package Langertha::Engine::OpenAI;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: OpenAI API
$Langertha::Engine::OpenAI::VERSION = '0.004';
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
  SystemPrompt
  Chat
  Embedding
  Transcription
));

sub all_models {qw(
  gpt-4o
  gpt-4o-mini
  gpt-4-turbo
  gpt-4
  gpt-3.5-turbo
  gpt-3.5-turbo-instruct
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

sub embedding_request {
  my ( $self, $input, %extra ) = @_;
  return $self->generate_request( createEmbedding => sub { $self->embedding_response(shift) },
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

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  return $self->generate_request( createChatCompletion => sub { $self->chat_response(shift) },
    model => $self->chat_model,
    messages => $messages,
    $self->get_response_size ? ( max_tokens => $self->get_response_size ) : (),
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

sub transcription_request {
  my ( $self, $file, %extra ) = @_;
  return $self->generate_request( createTranscription => sub { $self->transcription_response(shift) },
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

version 0.004

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
