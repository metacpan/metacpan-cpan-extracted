#!/usr/bin/env perl

use 5.018;
use warnings;
use Carp;
use Mojo::Util qw(dumper);

use lib "/works/firewall/lib";
use Firewall::Utils::Set;

my $set = Firewall::Utils::Set->new(
  mins => [ 1, 12 ],
  maxs => [ 2, 15 ]
);
my $tmp = $set->isBelong( Firewall::Utils::Set->new( mins => [ 1, 4, 12 ], maxs => [ 2, 10, 15 ] ) );

say $tmp;
