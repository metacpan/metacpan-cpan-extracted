#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;


BEGIN {
    use_ok( 'Games::Dice::Roller' ) || print "Bail out!\n";
}

diag( "Testing Games::Dice::Roller $Games::Dice::Roller::VERSION, Perl $], $^X" );
dies_ok { Games::Dice::Roller->new( sub_rand => 'not a CODE ref' ) } "expected to die when sub_rand does not hold a CODE ref";
ok ( ref Games::Dice::Roller->new() eq 'Games::Dice::Roller', "new instance correctly instanciated without arguments" );
ok ( ref Games::Dice::Roller->new( sub_rand => sub{1} ) eq 'Games::Dice::Roller', "new instance with optional sub_rand correctly instanciated" );

done_testing;