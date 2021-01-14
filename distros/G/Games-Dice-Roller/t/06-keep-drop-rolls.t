#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the roll method with keep and drop result modifiers" );

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

# kh
($res,$descr) = $forced_dice->roll('12d6kh4');
ok ( $res == 22, "expected result for '12d6kh4'" );
ok ( $descr eq '6 6 5 5 (4) (4) (3) (3) (2) (2) (1) (1)', "expected description for '12d6kh4'" );

# kl
($res,$descr) = $forced_dice->roll('12d6kl4');
ok ( $res == 6, "expected result for '12d6kl4'" );
ok ( $descr eq '1 1 2 2 (3) (3) (4) (4) (5) (5) (6) (6)', "expected description for '12d6kl4'" );


# dl
($res,$descr) = $forced_dice->roll('12d6dl8');
ok ( $res == 22, "expected result for '12d6dl8'" );
ok ( $descr eq '6 6 5 5 (4) (4) (3) (3) (2) (2) (1) (1)', "expected description for '12d6dl8'" );

# dl
($res,$descr) = $forced_dice->roll('12d6dl7');
ok ( $res == 26, "expected result for '12d6dl7'" );
ok ( $descr eq '6 6 5 5 4 (4) (3) (3) (2) (2) (1) (1)', "expected description for '12d6dl7'" );

# dh
($res,$descr) = $forced_dice->roll('12d6dh5');
ok ( $res == 16, "expected result for '12d6dh5'" );
ok ( $descr eq '1 1 2 2 3 3 4 (4) (5) (5) (6) (6)', "expected description for '12d6dh5'" );

# keep or drop too many dice
dies_ok { $forced_dice->roll('12d6dh12') } "expected to die if too many dice to keep or drop";

done_testing;