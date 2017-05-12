# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::EN::MatchNames;
$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Test;
BEGIN { plan tests => 18 }

ok(name_eq(split /  +/)) while(<DATA>);
ok(!name_eq(qw(Bart  Simpson  Lisa  Simpson)));
ok(!name_eq(qw(Arthur  Dent  Zaphod  Beeblebrox)));

__END__
Homer  Simpson  HOMER  SIMPOSN
Marge  Simpson  MIDGE  SIMPSON
Brian  Lalonde  BRYAN  LA LONDE
Brian  Lalonde  RYAN   LALAND
Peggy  MacHenry  Midge  Machenry
Liz  Grene   Elizabeth  Green
Chuck  Reed, Jr.  Charles  Reed II
Kathy  O'Brien  Catherine  Obrien
Lizzie  Hanson  Lisa  Hanson
H. Ross  Perot  Ross  PEROT
Kathy  Smith-Curry  KATIE  CURRY
Dina  Johnson-Warner  Dinah  J-Warner
Leela  Miles-Conrad  Leela  MilesConrad
C. Renee  Smythe  Cathy  Smythe
Victoria (Honey)  Rider  HONEY  RIDER
Bart  Simpson  El Barto  Simpson
