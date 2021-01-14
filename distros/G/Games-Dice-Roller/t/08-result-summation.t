#!perl
use 5.010;
use strict;
use warnings;
use Test::More;


use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the summation modifier" );

my ($res,$descr);


# to emulate 1d6 force results 5..1 because +1 will be added
my @forced = (qw( 5 5 4 4 3 3 2 2 1 1 0 0));
my $forced_dice =  Games::Dice::Roller->new(
	sub_rand => sub{ 
					my $sides = shift; 
					my $res = shift @forced;
					push @forced, $res;
					return $res;					
				},
);

# +3
($res,$descr) = $forced_dice->roll('6d6+3');
ok ( $res == 33, "expected result for '6d6+3'" );
ok ( $descr eq '6 6 5 5 4 4 +3', "expected description for '6d6+3'" );

# -3
($res,$descr) = $forced_dice->roll('6d6-3');
ok ( $res == 9, "expected result for '6d6-3'" );
ok ( $descr eq '3 3 2 2 1 1 -3', "expected description for '6d6-3'" );

# kh+3
($res,$descr) = $forced_dice->roll('12d6kh4+3');
ok ( $res == 25, "expected result for '12d6kh4+3'" );
ok ( $descr eq '6 6 5 5 (4) (4) (3) (3) (2) (2) (1) (1) +3', "expected description for '12d6kh4+3'" );

done_testing;