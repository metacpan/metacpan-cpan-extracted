#!perl
use 5.010;
use strict;
use warnings;
use Test::More;


use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the roll method" );

my ($res,$descr);

# avg
my $roller = Games::Dice::Roller->new();
($res,$descr) = $roller->roll('5d6avg');
ok ( $res == 17.5, "expected result for '5d6avg'" );
ok ( $descr eq '3.5 3.5 3.5 3.5 3.5', "expected description for '5d6avg'" );



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

# avg
($res,$descr) = $forced_dice->roll('10d6r6');
ok ( $res == 30, "expected result for '10d6r6'" );
ok ( $descr eq '(6r) (6r) 5 5 4 4 3 3 2 2 1 1', "expected description for '10d6r6'" );

# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('10d6rgt5');
ok ( $res == 30, "expected result for '10d6rgt5'" );
ok ( $descr eq '(6r) (6r) 5 5 4 4 3 3 2 2 1 1', "expected description for '10d6rgt5'" );


# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('8d6rgt4');
ok ( $res == 20, "expected result for '8d6rgt4'" );
ok ( $descr eq '(6r) (6r) (5r) (5r) 4 4 3 3 2 2 1 1', "expected description for '8d6rgt4'" );

# x
# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('10d6x6');
ok ( $res == 42, "expected result for '10d6x6'" );
ok ( $descr eq '6x 6x 5 5 4 4 3 3 2 2 1 1', "expected description for '10d6x6'" );

# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('8d6xgt4');
ok ( $res == 42, "expected result for '8d6xgt4'" );
ok ( $descr eq '6x 6x 5x 5x 4 4 3 3 2 2 1 1', "expected description for '8d6xgt4'" );

# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('10d6xlt3');
ok ( $res == 54, "expected result for '10d6xlt3'" );
ok ( $descr eq '6 6 5 5 4 4 3 3 2x 2x 1x 1x 6 6', "expected description for '10d6xlt3'" );

# 10 forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('10d6x6');
ok ( $res == 30, "expected result for '10d6x6'" );
ok ( $descr eq '5 5 4 4 3 3 2 2 1 1', "expected description for '10d6x6'" );

# cs
# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('12d6cs1');
ok ( $res == 2, "expected result for '12d6cs1'" );
ok ( $descr eq '(6) (6) (5) (5) (4) (4) (3) (3) (2) (2) 1 1', "expected description for '12d6cs1'" );

# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('12d6csgt4');
ok ( $res == 4, "expected result for '12d6csgt4'" );
ok ( $descr eq '6 6 5 5 (4) (4) (3) (3) (2) (2) (1) (1)', "expected description for '12d6csgt4'" );

# forced results reset after 12 call of the fake rand
($res,$descr) = $forced_dice->roll('12d6cslt3');
ok ( $res == 4, "expected result for '12d6cslt3'" );
ok ( $descr eq '(6) (6) (5) (5) (4) (4) (3) (3) 2 2 1 1', "expected description for '12d6cslt3'" );

done_testing;