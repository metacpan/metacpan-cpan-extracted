#!/usr/bin/perl

use strict;
use warnings;
use Devel::Walk;

my $bonk = { hello=>"hello" };
my $foo = \$bonk;

walk( $foo, sub { print "$_[0]\n"; 1 }, '$foo' );
