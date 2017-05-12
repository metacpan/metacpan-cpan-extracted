#!/usr/bin/perl 

use Tie::Function::Examples qw(%thoucomma %nothoucomma %addcents %q_shell %round %sprintf);
use Test::More qw/no_plan/;

for my $line (split(/\n/,<<'END_DATA')) {
	"$thoucomma{7000}"				7,000
	$thoucomma{700}					700
	$thoucomma{1234567890}				1,234,567,890
	$thoucomma{1234567890.28}			1,234,567,890.28
	$thoucomma{'.7000 7000 70.00'}			.7000 7,000 70.00
	$nothoucomma{'7,000'}				7000
	$nothoucomma{'.7000 7,000 70.00'}		.7000 7000 70.00
	$sprintf{'%d', 1.1}				1
	$sprintf{'%s', 1.1}				1.1
	$addcents{'45'}					45.00
	$addcents{'45.0'}				45.00
	$addcents{'45.00'}				45.00
	$addcents{'45.000'}				45.00
	$addcents{'1,234.237'}				1,234.24
	$addcents{'4 5.0 5.00 5.000 1,234.237 2.288'}	4.00 5.00 5.00 5.00 1,234.24 2.29
	$q_shell{'foobar baby'}				'foobar baby'
	$q_shell{johnson}				johnson
	$q_shell{"bq'ote"}				'bq'\''ote'
	$round{1234, 1000}				1000
	$round{1234, 100}				1200
	$round{1234, 10}				1230
	$round{.456, 1}					0
	$round{.456}					0
	$round{.456, .1}				0.5
	$round{.456, .01}				0.46
	$round{.4564, .001}				0.456
END_DATA
	die unless $line =~ /^\t+(.+?)\t+(.*)/;
	my ($a, $b) = ($1, $2);
	my $x = eval $a;
	is ($x, $b, $a);
}

