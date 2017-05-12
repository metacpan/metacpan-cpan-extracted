package Test::EMX;

use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => ['message'],
};

use Email::MIME;
use Carp qw(croak);

our $DIR = "./t/messages";

sub message {
  my $name = shift;
  -e "$DIR/$name" or croak "no such message: $name";
  open my $fh, "<$DIR/$name" or croak "$DIR/$name: $!";
  return Email::MIME->new(do { local $/; <$fh> });
}

1;
