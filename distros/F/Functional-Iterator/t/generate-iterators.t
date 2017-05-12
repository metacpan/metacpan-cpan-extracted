#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use lib grep { -d } qw(./lib ../lib ./t/lib);

use Functional::Iterator;

my $inner = 5;
my $limit = 10;

my $container = iterator(
  generator => sub {
    if ($inner--) {
      return iterator(records => [1..$limit--]);
    } else {
      return undef;
    }
  },
 );

my @gathered;
while (my $number = $container->next) {
  push @gathered, $number;
}

is_deeply( \@gathered, [1..10, 1..9, 1..8, 1..7, 1..6] );
