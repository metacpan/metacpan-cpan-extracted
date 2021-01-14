#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the basic behaviour of the roll method" );
my $roller = Games::Dice::Roller->new();

dies_ok { $roller->roll() } "expected to die without arguments";
dies_ok { $roller->roll( '1d6', 'unwanted') } "expected to die with more than one argument";

done_testing();
