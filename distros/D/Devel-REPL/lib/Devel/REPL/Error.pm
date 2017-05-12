package Devel::REPL::Error;

our $VERSION = '1.003028';

use Moose;
use namespace::autoclean;

# FIXME get nothingmuch to refactor and release his useful error object

has type => (
  isa => "Str",
  is  => "ro",
  required => 1,
);

has message => (
  isa => "Str|Object",
  is  => "ro",
  required => 1,
);

sub stringify {
  my $self = shift;

  sprintf "%s: %s", $self->type, $self->message;
}
__PACKAGE__
