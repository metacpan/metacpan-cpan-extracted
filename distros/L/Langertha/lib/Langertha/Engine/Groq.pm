package Langertha::Engine::Groq;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: GroqCloud API
$Langertha::Engine::Groq::VERSION = '0.007';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAI';

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_GROQ_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_GROQ_API_KEY or api_key set";
}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.groq.com/openai/v1' },
);

sub default_model { croak "".(ref $_[0])." requires a default_model" }

sub default_transcription_model { 'whisper-large-v3' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createTranscription
)]}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Groq - GroqCloud API

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  use Langertha::Engine::Groq;

  my $groq = Langertha::Engine::Groq->new(
    api_key => $ENV{GROQ_API_KEY},
    model => $ENV{GROQ_MODEL},
    system_prompt => 'You are a helpful assistant',
  );

  print($groq->simple_chat('Say something nice'));

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

=head1 HOW TO GET GROQ API KEY

L<https://console.groq.com/keys>

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
