#!/usr/bin/perl

use strict;
use warnings;
use Devel::Walk;

my $bonk;
my $foo = { bonk=>\$bonk };
$foo->{foo} = $foo;
$foo->{again} = \$bonk;

walk( $foo, sub { print "$_[0]\n"; 1 }, '$foo' );
