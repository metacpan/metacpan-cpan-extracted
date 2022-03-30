# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Dipki.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
## TO REMOVE IN FINAL DISTR
## BEGIN { unshift @INC, 'C:/!Data/Perl'; }
##
BEGIN { use_ok('Dipki') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use Dipki;

my ($s, $n);
$n = Dipki::Gen::Version();
ok ($n >= 200301, "Gen::Version");
$s = Dipki::Gen::LicenceType();
ok ($s eq 'D' || $s eq 'T', "Gen::LicenceType");

$s = Dipki::Hash::HexFromData('abc');
ok ($s eq 'a9993e364706816aba3e25717850c26c9cd0d89d', "Hash::HexFromData('abc')");

done_testing;
