#########################

use Test::More tests => 5;

BEGIN {

    use_ok 'Encode::Arabic::Parkinson';
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $utf = "\x{0627}\x{0650}\x{0642}\x{0652}\x{0631}\x{064E}\x{0623}\x{0652} " .
          "\x{0647}\x{0670}\x{0630}\x{064E}\x{0627} " .
          "\x{0671}\x{0644}\x{0646}\x{0651}\x{064E}\x{0635}\x{0651}\x{064E} " .
          "\x{0628}\x{0650}\x{0671}\x{0646}\x{0652}\x{062A}\x{0650}\x{0628}\x{064E}\x{0627}\x{0647}\x{064D}. " .
          "\x{0643}\x{064E}\x{064A}\x{0652}\x{0641}\x{064E} " .
          "\x{0671}\x{0644}\x{0652}\x{062D}\x{064E}\x{0627}\x{0644}\x{064F}\x{061F}";

my $dil = "AiqoraLo hRvaA Oln~aS~a biOnotibaAhI. kayofa OloHaAlu?";

my $encode = encode "parkinson", $utf;
my $decode = decode "parkinson", $dil;

is $encode, $dil, '$encode is $dil';
is $decode, $utf, '$decode is $utf';

is $encode, (encode "parkinson", $decode), 'encode(..., $decode) is fine';
is $decode, (decode "parkinson", $encode), 'decode(..., $encode) is fine';
