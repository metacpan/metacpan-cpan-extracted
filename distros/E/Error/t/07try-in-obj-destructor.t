#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Error qw/ :try /;

package ErrorTest;
use Error qw/ :try /;

sub new {
  return bless {}, 'ErrorTest';
}

sub DESTROY {
  my $self = shift;
  try { 1; } otherwise { };
  return;
}

package main;

my $E;
try {

  my $y = ErrorTest->new();
#  throw Error::Simple("Object die");
  die "throw normal die";

} catch Error with {
  $E = shift;
} otherwise {
  $E = shift;
};

# TEST
is ($E->{'-text'}, "throw normal die",
    "Testing that the excpetion is not trampeled"
);


