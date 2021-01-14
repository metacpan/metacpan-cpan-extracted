#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok( 'Games::Dice::Roller' ); 
diag( "Testing dice pools" );

# dies_ok { Games::Dice::Roller::_identify_type('2d4avgkh') } "expected to die if avg has also a result modification k or d";

# ok ( $dice->single_die(6) < 7, "expected result lesser than 7 for 1d6" );

my @forced = (qw( 5 5 4 4 3 3 2 2 1 1 0 0));
my $forced_dice =  Games::Dice::Roller->new(
	sub_rand => sub{ 
					my $sides = shift; 
					my $res = shift @forced;
					push @forced, $res;
					return $res;					
				},
);

# $forced_dice->roll('3d6+3 12');

# too many bare numbers
dies_ok { $forced_dice->roll('12d6+3 12 12 12') } "expected to die if more than one bare number are passed";

# # too many global modifiers
dies_ok { $forced_dice->roll('12d6+3 12 kh kh') } "expected to die if more than one global modifier are passed";

# kh
my ($res,$descr)=$forced_dice->roll('6d6+3 6d6+5 12 kh');
ok ( $res = 33, "expected result for '3d6+3 4d6+4 3d6-10 2d6 12 kh'" );
ok ( $descr eq '6d6+3 = 6 6 5 5 4 4 +3, ( 6d6+5 = 3 3 2 2 1 1 +5 = 17 ), ( 12 )', "expected description for '6d6+3 6d6+5 12 kh'" );

#default kh
($res,$descr)=$forced_dice->roll('6d6+3 6d6+5 12');
ok ( $res = 33, "expected result for '3d6+3 4d6+4 3d6-10 2d6 12' default to kh" );
ok ( $descr eq '6d6+3 = 6 6 5 5 4 4 +3, ( 6d6+5 = 3 3 2 2 1 1 +5 = 17 ), ( 12 )', "expected description for '6d6+3 6d6+5 12' default to kh" );

# kl 
($res,$descr)= $forced_dice->roll('6d6+3 6d6+5 20 kl');
ok ( $res = 17, "expected result for '6d6+3 6d6+5 20 kl'" );
ok ( $descr eq '6d6+5 = 3 3 2 2 1 1 +5, ( 20 ), ( 6d6+3 = 6 6 5 5 4 4 +3 = 33 )', "expected description for '6d6+3 6d6+5 20 kl'" );

print "$_\n" for Games::Dice::Roller->new()->roll('4d4rlt3+6 3d6xgt4+2 2d8+1 12');

done_testing;





