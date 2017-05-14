package Calc;
use strict;
use warnings;
use Class::Accessor::Chained::Fast;
use base qw(Class::Accessor::Chained::Fast);
our $VERSION = "0.29";

sub add {
  my($self, $l, $r) = @_;
  
  return $l + $r;
}

sub fib1 {
  my($self, $n) = @_;
  if ($n < 2) {
    return 1;
  } else {
    return $self->fib1($n - 1) + $self->fib1($n - 2);
  }
}

sub fib2 {
  my($self, $n) = @_;
  my $x1 = 1;
  my $x2 = 1;
  my $tmp = 0;
  foreach my $i (1..$n) {
     $tmp = $x1 + $x2;
     $x1 = $x2;
     $x2 = $tmp;
  }
  return $x1;
}
