#!perl -T

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::Dummy';
}

use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;

my $a = Games::Tournament::Contestant::Swiss->new(
    id     => 1,
    name   => 'Roy',
    title  => 'Expert',
    rating => 100,
);

my $p = Games::Tournament::Swiss->new( entrants => [$a] );

my @tests = (
    [ $p->medianScore(2),  1,    'median	2nd	1' ],
    [ $p->medianScore(3),  1.5,  'median	3nd	1.5' ],
    [ $p->medianScore(13), 6.5,  'median	13nd	6.5' ],
    [ $p->medianScore(23), 11.5, 'median	23nd	11.5' ],
);

plan tests => $#tests + 1;

map { is( $_->[0], $_->[ 1, ], $_->[2] ) } @tests;
