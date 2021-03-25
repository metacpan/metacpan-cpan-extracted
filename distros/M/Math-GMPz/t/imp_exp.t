use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Test::More;
use Config;

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $z      = Math::GMPz->new();
my $z_up   = Math::GMPz->new();
my $z_down = Math::GMPz->new();
my $z_check = Math::GMPz->new();

my $iterations = 500;

my $s = "\xf4\x57\xbc\x2b\xaf\xb7\x3f\x2b\x41\x43\xe9\x3f\x3f\x2b\xc5\x52\x48\x90";
my ($order, $size, $endian, $nails) = (1, 1, 0, 0);

# $s contains no ordinal values greater than 0xff.
# Therefore utf8::is_utf8($s) should be false.

cmp_ok(utf8::is_utf8($s), '==', 0, "string is not utf8");

Rmpz_import($z, length($s), $order, $size, $endian, $nails, $s);

cmp_ok(utf8::is_utf8($s), '==', 0, "Rmpz_import did not alter format");

my $check = Rmpz_export( $order, $size, $endian, $nails, $z);

cmp_ok($check, 'eq', $s, "round trip is successful");

Rmpz_import($z_down, 2, $order, 9, 1, $nails, $s);
cmp_ok($z_down, '==', $z, "reading in multiple bytes works");

utf8::upgrade($s);

cmp_ok(utf8::is_utf8($s), '!=', 0, "string is utf8");

$Math::GMPz::utf8_no_warn = 1; # suppress the warning that would tell us $s is UTF8 and
                               # will therefore be subjected to a utf8::downgrade
                               # inside Rmpz_import.

Rmpz_import($z_up, length($s), 1, 1, 0, 0, $s);

cmp_ok($z_up, '==', $z, "Rmpz_import processes downgraded string");

# $s was given a utf8::downgrade inside Rmpz_import.
# Next we check that Rmpz_import restored $s to its original status,
# by doing a utf8::upgrade prior to termination.

cmp_ok(utf8::is_utf8($s), '!=', 0, "Rmpz_import restores upgrade");

my $check_up = Rmpz_export( $order, $size, $endian, $nails, $z_up);

cmp_ok(utf8::is_utf8($check_up), '==', 0, "export returns downgraded string");

cmp_ok($s , 'eq', $check_up, "upgraded string eq downgraqded string");

my $ws = "\x60\x{150}\x90";

$Math::GMPz::utf8_no_warn = 1; # Disable warning.

# $ws is a UTF8 string that cannot be downgraded.
# $Math::GMPz::utf8_no_croak is currently set to 0, so Rmpz_import should
# croak on the "Wide character" when it tries to process $ws.
# Next we check that this is so.

eval{ Rmpz_import($z, length($ws), $order, $size, $endian, $nails, $ws); };
like($@, qr/^Wide character in subroutine/, '$@ set as exected');

$Math::GMPz::utf8_no_croak = 1;
$Math::GMPz::utf8_no_fail = 1;

# With $Math::GMPz::no_croak set to a true value, we verify that
# that Rmpz_import no longer croaks when processing $ws.

eval{ Rmpz_import($z, length($ws), $order, $size, $endian, $nails, $ws); };
cmp_ok($@, 'eq', '', '1: $@ unset as expected');

$Math::GMPz::utf8_no_downgrade = 1;
$Math::GMPz::utf8_no_croak = 0;
$Math::GMPz::utf8_no_fail = 0;

eval{ Rmpz_import($z_up, length($ws), $order, $size, $endian, $nails, $ws); };
cmp_ok($@, 'eq', '', '2: $@ unset as expected');

cmp_ok($z_up, '==', $z, "wide character string without utf8 downgrade treatment ok");

$Math::GMPz::utf8_no_downgrade = 0;

$z_down = Math::GMPz->new((ord('a') * (256 ** 2)) + (ord('B') * 256) + ord('c'));
Rmpz_import($z, 1, $order, 3, 1, $nails, 'aBc');

cmp_ok($z, '==', $z_down, "Rmpz_import basic sanity check");

$check = Rmpz_export( $order, 1, 1, $nails, $z);

cmp_ok($check, 'eq', 'aBc', "Rmpz_export retrieves original string");

# ord('a') == 0x61
#If we ignore the 4 most siginificant bits of ord('a') then the value is 0x01
$z_down = Math::GMPz->new((1 * (256 ** 2)) + (ord('B') * 256) + ord('c'));
Rmpz_import($z, 1, $order, 3, 1, 4, 'aBc'); # ignore first 4 bits of 'aBc'

cmp_ok($z, '==', $z_down, "nails test");

my $bits = $Config{ivsize} * 8;
my @uv = (1234567890, 876543210, ~0, 2233445566);

my $val_check =  Math::GMPz->new($uv[3]) +
                (Math::GMPz->new($uv[2]) <<  $bits) +
                (Math::GMPz->new($uv[1]) << ($bits * 2)) +
                (Math::GMPz->new($uv[0]) << ($bits * 3));

Rmpz_import_UV($z, scalar(@uv), 0, $Config{ivsize}, 0, 0, \@uv);

print "$z\n$val_check\n";

cmp_ok($z, '==', $val_check, "Rmpz_import_UV basic sanity check");

my @ret = Rmpz_export_UV(0, $Config{ivsize}, 0, 0, $z);

cmp_ok(scalar(@ret), '==', scalar(@uv), "returned array is of expected size");
cmp_ok($ret[0], '==', $uv[0], "1st array elements match");
cmp_ok($ret[1], '==', $uv[1], "2nd array elements match");
cmp_ok($ret[2], '==', $uv[2], "3rd array elements match");
cmp_ok($ret[3], '==', $uv[3], "4th array elements match");

for(1 .. $iterations) {

    my ($s, $ords) = randstr(0);  # These strings are normal ASCII strings, with all
                                  # characters in the range \x00 .. \x7f.
                                  # Makes no difference to Rmpz_import whether they
                                  # have been upgraded to UTF8 or not.
#   utf8::upgrade($s);
    my $len = length($s);
    Rmpz_import($z, $len, 1, 1, 0, 0, $s);
#   Rmpz_out_str($z, 16);
#   print("\n");
    my $s_check = Rmpz_export(1, 1, 0, 0, $z);
    Rmpz_import($z_check, $len, 1, 1, 0, 0, $s_check);

    cmp_ok($len, '==', 3, "length of original string (@$ords) is 3");
    cmp_ok($s, 'eq', $s_check, "strings match");
    cmp_ok($z, '==', $z_check, "values match");
    cmp_ok(utf8::is_utf8($s), '==', 0, "string is NOT UTF8");
}

set_globals_to_default();

for(1 .. $iterations) {

    my ($s, $ords) = randstr(0);  # These strings are normal ASCII strings, with all
                                  # characters in the range \x00 .. \x7f.
                                  # Makes no difference to Rmpz_import whether they
                                  # have been upgraded to UTF8 or not.

    $Math::GMPz::utf8_no_warn  = 1;   # Don't warn about utf8 strings

    utf8::upgrade($s);
    my $len = length($s);
    Rmpz_import($z, $len, 1, 1, 0, 0, $s);
#   Rmpz_out_str($z, 16);
#   print("\n");
    my $s_check = Rmpz_export(1, 1, 0, 0, $z);
    Rmpz_import($z_check, $len, 1, 1, 0, 0, $s_check);

    cmp_ok($len, '==', 3, "length of original string (@$ords) is 3");
    cmp_ok($s, 'eq', $s_check, "strings match");
    cmp_ok($z, '==', $z_check, "values match");
    cmp_ok(utf8::is_utf8($s), '!=', 0, "string is UTF8");
}

set_globals_to_default();

for(1 .. $iterations) {

    my ($s, $ords) = randstr(1); # These strings contain at least one character
                                 # in the range \x80 .. \xff, and Rmpz_import
                                 # will treat them differently, depending upon
                                 # their UTF8 status.

#   utf8::upgrade($s);
    my $len = length($s);
    Rmpz_import($z, $len, 1, 1, 0, 0, $s);
#   Rmpz_out_str($z, 16);
#   print("\n");
    my $s_check = Rmpz_export(1, 1, 0, 0, $z);
    Rmpz_import($z_check, $len, 1, 1, 0, 0, $s_check);

    cmp_ok($len, '==', 3, "length of original string (@$ords) is 3");
    cmp_ok($s, 'eq', $s_check, "strings match");
    cmp_ok($z, '==', $z_check, "values match");
    cmp_ok(utf8::is_utf8($s), '==', 0, "string is NOT UTF8");
}

set_globals_to_default();

for(1 .. $iterations) {

    my ($s, $ords) = randstr(1); # These strings contain at least one character
                                 # in the range \x80 .. \xff, and Rmpz_import
                                 # will treat them differently, depending upon
                                 # their UTF8 status.

    $Math::GMPz::utf8_no_warn  = 1;   # Don't warn about utf8 strings
    utf8::upgrade($s);
    my $len = length($s);
    Rmpz_import($z, $len, 1, 1, 0, 0, $s);
    my $s_check = Rmpz_export(1, 1, 0, 0, $z);
    Rmpz_import($z_check, $len, 1, 1, 0, 0, $s_check);

    cmp_ok($len, '==', 3, "length of original string (@$ords) is 3");
    cmp_ok($s, 'eq', $s_check, "strings match");
    cmp_ok($z, '==', $z_check, "values match");
    cmp_ok(utf8::is_utf8($s), '!=', 0, "string is UTF8");
}

set_globals_to_default();

$Math::GMPz::utf8_no_warn  = 1;     # Don't warn about utf8 strings
$Math::GMPz::utf8_no_downgrade = 1; # Don't perform utf8 downgrade

for(1 .. $iterations) {
    my ($s, $ords) = randstr(1);
    my @o = @$ords;
    utf8::upgrade($s);
    my $len = length($s);
    Rmpz_import($z, $len, 1, 1, 0, 0, $s);
    my $s_check = Rmpz_export(1, 1, 0, 0, $z);
    Rmpz_import($z_check, $len, 1, 1, 0, 0, $s_check);

    cmp_ok($len, '==', 3, "length of original string (@o) is 3");

    if( ($o[0] <  128 && $o[1] == 195 && $o[2] == 131)
        ||
        ($o[0] == 195 && $o[1] == 131 && $o[2] == 194) ) {

      if($s ne $s_check) {
        warn "unexpected mismatch - ords: $o[0] $o[1] $o[2]\n";
      }
      cmp_ok($s, 'eq', $s_check, "bytes match - the exceptions to the rule");
    }
    else {
      if($s eq $s_check) {
        warn "unexpected match - ords: $o[0] $o[1] $o[2]\n";
      }
      cmp_ok($s, 'ne', $s_check, "bytes do NOT match");
    }
    cmp_ok($z, '==', $z_check, "values match");
    cmp_ok(utf8::is_utf8($s), '!=', 0, "string is UTF8");
}

set_globals_to_default();

    $Math::GMPz::utf8_no_warn      = 1;     # Don't warn about utf8 strings
    $Math::GMPz::utf8_no_downgrade = 1;     # Don't attempt to downgrade as
                                            # it will inevitably fail.

for(1 .. $iterations) {

    my ($s, $ords) = randstr(2);      # These strings are automatically UTF8, containing
                                      # at least one character greater than \xff.
                                      # Therefore, they cannot be downgraded.

#   utf8::upgrade($s); # not needed, already utf8 - but let's check:
    cmp_ok(utf8::is_utf8($s), '!=', 0, "string is UTF8");
    my $len = length($s);
    Rmpz_import($z, $len, 1, 1, 0, 0, $s);
    my $s_check = Rmpz_export(1, 1, 0, 0, $z);
    Rmpz_import($z_check, $len, 1, 1, 0, 0, $s_check);

    cmp_ok($len, '==', 3, "length of original string (@$ords) is 3");
    cmp_ok($s, 'ne', $s_check, "strings do NOT match");
    cmp_ok($z, '==', $z_check, "values match");
}

set_globals_to_default();

done_testing();

sub randstr {

  # Takes one argument - either something that == 0,
  # or somethng that == 1,
  # or something that !=0 && != 1.

  my($r1, $r2, $r3);
  if($_[0] == 0) {    # all ordinal values < 128
    $r1 = int(rand(127)) + 1;   # disallow 0
    $r2 = int(rand(128));
    $r3 = int(rand(128));
  }
  elsif($_[0] == 1) { # all ordinal values < 256
    $r1 = int(rand(255)) + 1;   # disallow 0
    $r2 = 128 + int(rand(128)); # force value > 127
    $r3 = int(rand(256));
  }
  else {              # all ordinal values < 512
    $r1 = int(rand(511)) + 1;   # disallow 0
    $r2 = 256 + int(rand(256)); # force value > 255
    $r3 = int(rand(512));
  }

  my $s = chr($r1) . chr($r2) . chr($r3);
  my @ords = ($r1, $r2, $r3);
  return ($s, \@ords);
}

sub set_globals_to_default{
  $Math::GMPz::utf8_no_croak = 0;
  $Math::GMPz::utf8_no_warn  = 0;
  $Math::GMPz::utf8_no_fail  = 0;
  $Math::GMPz::utf8_no_downgrade = 0;
}

