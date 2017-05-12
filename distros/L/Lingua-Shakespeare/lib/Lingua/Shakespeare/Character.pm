package Lingua::Shakespeare::Character;

use Carp;
use strict;

sub new {
  my $class = shift;
  my $name = shift;

  bless { value => 0, list => [], name => $name }, $class;
}


sub name {
  shift->{name}
}

sub value {
  shift->{value}
}

sub assign {
  my $self = shift;
  $self->{value} = shift;
}

sub int_input {
  my $self = shift;

  my $num = <STDIN>;

  croak $self->name . " had a heart attack"
    unless defined $num;

  chomp($num);

  croak $self->name . "'s heart whispered something that is not an integer"
    unless $num =~ /^-?\d+/;

  $self->{value} = $num;
}

sub int_output {
  my $self = shift;

  print $self->{value};
}

sub char_output {
  my $self = shift;

  print chr($self->{value} & 255);
}

sub char_input {
  my $self = shift;

  my $ch;
  $self->{value} = read(STDIN, $ch, 1) ? ord($ch) : -1;
}

sub push {
  my $self = shift;
  push @{ $self->{list} }, shift;
}

sub pop {
  my $self = shift;
  $self->{value} = pop @{ $self->{list} };
}

1;
