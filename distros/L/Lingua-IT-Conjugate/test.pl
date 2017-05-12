# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use vars qw(
	$loaded
	$coniuga
	$confronta
);

use strict;
$^W = 1;
use Lingua::IT::Conjugate qw( coniuga declina );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$coniuga 	= coniuga('essere', 'presente', 1, { pronomi => 0} );
$confronta	= "sono";
if($coniuga ne $confronta) {
	print "# got '$coniuga', expected '$confronta'\n";
	print "not ";
}
print "ok 2\n";

$coniuga 	= coniuga('essere', 'presente', 2, { pronomi => 0} );
$confronta	= "sei";
if($coniuga ne $confronta) {
	print "# got '$coniuga', expected '$confronta'\n";
	print "not ";
}
print "ok 3\n";

$coniuga 	= coniuga('essere', 'passato_prossimo', 3, { pronomi => 0} );
$confronta	= "Š stato";
if($coniuga ne $confronta) {
	print "# got '$coniuga', expected '$confronta'\n";
	print "not ";
}
print "ok 4\n";

$Lingua::IT::Conjugate::Opzioni{pronomi} = 0;

my @declina = declina('avere', 'presente');
my @confronta = qw( ho hai ha abbiamo avete hanno );
for my $i (0..5) {
	if($declina[$i] ne $confronta[$i]) {
		print "# got '$declina[$i]', expected '$confronta[$i]'\n";
		print "not ";
	}
}
print "ok 5\n";

