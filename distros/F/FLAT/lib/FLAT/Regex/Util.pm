package FLAT::Regex::Util;
use base 'FLAT::Regex';

use strict;
use Carp;

sub get_symbol {
  my @symbols = qw/0 1/;
  return $symbols[rand(2)];
}

sub get_op {
  my @ops = ('*','+','&','','','','','','','');
  return $ops[rand(10)];
}

sub get_random {
  my $length = shift;
  my $string = ''; 
  if (1 < $length) {
    $string = get_symbol().get_op().get_random(--$length);
  } else {
    $string = get_symbol();
  }
  return $string;
}

sub random_pre {
  my $length = ( $_[0] ? $_[0] : 32 );
  return FLAT::Regex::WithExtraOps->new(get_random($length));
}

1;
