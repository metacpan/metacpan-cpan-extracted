package List::Utils::MoveElement::PP;

use 5.008;
use strict;
use warnings;
our @VERSION = 0.01;

use Carp qw/croak/;

sub to_beginning {
  my ($i, @array) = @_;
  croak 'Usage: to_beginning($n, @list)' if !defined($i) or !@array;
  croak 'Array index out of range' if $i > $#array;
  return @array if $i == 0; #no-op
  return @array[$i, 0 .. $i-1, $i+1 .. $#array];
}

sub to_end {
  my ($i, @array) = @_;
  croak 'Usage: to_end($n, @list)' if !defined($i) or !@array;
  croak 'Array index out of range' if $i > $#array;
  return @array if $i == $#array; #no-op
  return @array[0 .. $i-1, $i+1 .. $#array, $i];
}

sub left {
  my ($i, @array) = @_;
  croak 'Usage: move_left($n, @list)' if !defined($i) or !@array;
  croak 'Array index out of range' if $i > $#array;
  return @array if $i == 0; #no-op
  ($array[$i-1], $array[$i]) = ($array[$i], $array[$i-1]);
  return @array;
}

sub right {
  my ($i, @array) = @_;
  croak 'Usage: move_left($n, @list)' if !defined($i) or !@array;
  croak 'Array index out of range' if $i > $#array;
  return @array if $i == $#array; #no-op
  ($array[$i+1], $array[$i]) = ($array[$i], $array[$i+1]);
  return @array;
}

1;
