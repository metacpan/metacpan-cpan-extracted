use warnings;
use strict;

use Test::More tests => 4;

BEGIN { unshift @INC, "./t/lib"; }

our $onset_test;
my $onset_unfixed;

$^H |= 0x20000 if "$]" < 5.009004;
$^H{"Lexical::SealRequireHints/test"} = 1;

$onset_test = "";
eval q{ require "t/onset.pl"; 1 } or die $@;
delete $INC{"t/onset.pl"};
$onset_unfixed = $onset_test;

require_ok "Lexical::SealRequireHints";
$onset_test = "";
eval q{ require "t/onset.pl"; 1 } or die $@;
delete $INC{"t/onset.pl"};
is $onset_test, $onset_unfixed;

foreach (0..1) {
	Lexical::SealRequireHints->import;
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	is $onset_test, "undef";
}

1;
