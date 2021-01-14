#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok( 'Games::Dice::Roller' ); 
diag( "Testing the single_die private method" );
my $dice = Games::Dice::Roller->new();
dies_ok { $dice->single_die() } "expected to die without arguments";
dies_ok { $dice->single_die('a') } "expected to die with non digit argument";
dies_ok { $dice->single_die('3a3') } "expected to die with non digit only argument";
dies_ok { $dice->single_die(3.5) } "expected to die with decimal argument";
dies_ok { $dice->single_die(-6) } "expected to die with negative numbers";

# simple values
ok ( $dice->single_die(6) > 0, "expected result greater than 0 for 1d6" );
ok ( $dice->single_die(6) < 7, "expected result lesser than 7 for 1d6" );

# see https://perlmonks.org/index.pl?node_id=11126201
my $tenk;
$tenk += $dice->single_die(6) for 1..10000;
my $avg = $tenk/10000;
# $avg = 5; # uncomment this line to provoke the warning
if ( ($avg < 3.4) or ($avg > 3.6) ){
	diag(
			"\n\n\nPROBLEM: you got an average of $avg while was expected a value > 3.4 and < 3.6\n\n\n".
			"The average was made on 10000d6 rolls.\n".
			"This can happen in old Perl distribution on some platform.\n".
			"You can use sub_rand => sub{.. during constructor to provide an\n".
			"alternative to core rand function (using rand from Math::Random::MT for example).\n\n\n\n"
	);
}
else { 
		pass "average randomness ok (3.4 < 10000d6 / 10000 < 3.6)" ;
}


# forced result overriding sub_rand
note( "Testing a custom sub_rand provided during construction" );
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

ok ( $forced_dice->single_die(6) == 6, "forced fixed result (6) using a custom sub_rand" );
ok ( $forced_dice->single_die(6) == 6, "forced fixed result (6) using a custom sub_rand" );
ok ( $forced_dice->single_die(5) == 5, "forced fixed result (5) using a custom sub_rand" );



done_testing();