# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Encode-BOCU1-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# use lib qw(./blib/lib);
use Test::More tests => 6;
use Encode qw(from_to);

##
## TEST 1
##
BEGIN { use_ok('Encode::BOCU1::XS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##
## TEST 2 (U+FEFF, UTF-8 => BOCU-1)
##
my ($u_feff_utf8, $u_feff_bocu1) = ("\xef\xbb\xbf", "\xfb\xee\x28");
$str = $u_feff_utf8; # U+FEFF
Encode::from_to($str, 'utf8', 'bocu1');
is($str, "", 'U+FEFF at the top, UTF-8 => BOCU-1');

##
## TEST 3 (space + U+FEFF)
##
$str = ' ' . $u_feff_utf8; # space + U+FEFF
Encode::from_to($str, 'utf8', 'bocu1');
is($str, ' ' . $u_feff_bocu1, 'space + U+FEFF, UTF-8 => BOCU-1');

##
## TEST 4 (U+FEFF, BOCU-1 => UTF-8)
##
$str = $u_feff_bocu1; # U+FEFF
Encode::from_to($str, 'bocu1', 'utf8');
is($str, $u_feff_utf8, 'U+FEFF, BOCU-1 => UTF-8');

##
## TEST 5
##
my $orig_str = '"The toilet is clogged." "Why don\'t you make it with Plagger?"';

$str = $orig_str;
from_to($str, 'utf8', 'bocu1');
from_to($str, 'bocu1', 'utf8');

is( $str, $orig_str, 'round trip test (ASCII)' );

##
## TEST 6
##
$orig_str = '「トイレが詰まったんですけど」「それPlaggerでやればいいんじゃね？」';

$str = $orig_str;
from_to($str, 'utf8', 'bocu1');
from_to($str, 'bocu1', 'utf8');

is( $str, $orig_str, 'round trip test (Japanese)' );

1;
