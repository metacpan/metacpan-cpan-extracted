package Langertha::Engine::Whisper;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Whisper compatible transcription server
$Langertha::Engine::Whisper::VERSION = '0.008';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAI';

sub default_transcription_model { '' }

has '+url' => (
  required => 1,
);

sub _build_api_key { 'whisper' }

sub _build_supported_operations {[qw(
  createTranscription
  createTranslation
)]}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Whisper - Whisper compatible transcription server

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use Langertha::Engine::Whisper;

  my $whisper = Langertha::Engine::Whisper->new(
    url => $ENV{WHISPER_URL},
  );

  print($whisper->simple_transcription('recording.ogg'));

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

=head1 HOW TO INSTALL FASTER WHISPER

L<https://github.com/fedirz/faster-whisper-server>

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
