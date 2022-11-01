
# Test that Rmpz_import warns as intended and documented

use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Test::More;
use Test::Warn;

my $s = chr(100) . chr(90);
my $z = Math::GMPz->new();

warning_is {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)} undef,
 "No warning when all characters < 0x7f";

$s .= chr(200);

warning_is {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)} undef,
 "No warning when all characters < 0xff";

$s .= chr(256);

$Math::GMPz::utf8_no_croak = 1; # prevent the next Rmpz_import call from croaking
$Math::GMPz::utf8_no_fail  = 1; # suppress warning of failed downgrade attempt

warnings_like {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)}
 [qr/UTF8 string encountered/, qr/To disable this warning/],
 "Warn when any character > 0xff";

$Math::GMPz::utf8_no_fail = 0;
$Math::GMPz::utf8_no_warn = 1;

warnings_like {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)}
 [qr/An attempted utf8 downgrade/, qr/To disable this warning/],
 "Warn when downgrade failure is non-fatal";

$Math::GMPz::utf8_no_fail = 1;

warning_is {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)} undef,
 "Warning of non-fatal downgrade failure is suppressed";

#########################################
# Revert $s to its original setting and #
# reset all 4 globals to default values #
#########################################

$s = chr(100) . chr(90);
clear_globals();

utf8::upgrade($s);

warnings_like {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)}
 [qr/UTF8 string encountered/, qr/To disable this warning/],
 "Warn when string is UTF8";

$Math::GMPz::utf8_no_downgrade = 1;

warning_like {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)} undef,
 "no Warning about UTF8 string when \$Math::GMPz::utf8_no_downgrade is set";

$Math::GMPz::utf8_no_downgrade = 0;
$Math::GMPz::utf8_no_warn = 1;

warning_is {Rmpz_import($z, length($s), 1, 1, 0, 0, $s)} undef,
 "warning of impending downgrade is suppressed";

done_testing();

sub clear_globals {
  $Math::GMPz::utf8_no_warn      = 0; # warn when Rmpz_import receives UTF8 string
  $Math::GMPz::utf8_no_croak     = 0; # make a failed downgrade attempt by Rmpz_import fatal
  $Math::GMPz::utf8_no_fail      = 0; # warn if Rmpz_import makes a failed, non-fatal, downgrade attempt
  $Math::GMPz::utf8_no_downgrade = 0; # do not allow Rmpz_import to attempt a downgrade
}


