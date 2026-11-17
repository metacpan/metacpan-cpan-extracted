package Holmgang::LongFailEngine;
# Test engine for the CLI's no-answer note (k44): a Langertha::Engine::Virtual
# with an invented key whose every request dies with a long, multi-line text
# that carries the key, a Bearer header, a host path and Perl's location.
# The text names the repetition, so a test can tell which one is quoted first.
use Moose;
extends 'Langertha::Engine::Virtual';

our $KEY = 'hgtest0invented0key0do0not0use0k44';

sub _build_api_key { $KEY }

our $N = 0;

sub chat_f {
  my ( $self ) = @_;
  $N++;
  die "HTTP 401 Unauthorized (request $N): the key $KEY was refused\n"
    ."  POST https://api.invented.example/v1/chat\n"
    ."  Authorization: Bearer $KEY\n"
    ."  key file /home/someone/.config/invented/key.txt\n"
    .( "  more detail from the provider that nobody needs on one line\n" x 6 )
    ."end of the body";
}

__PACKAGE__->meta->make_immutable;

1;
