#########################

use Test::More tests => 5;

BEGIN {

    use_ok 'Encode::Arabic::Habash';
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

my $hsb = encode "utf8", "\x{0041}\x{0069}\x{0071}\x{00B7}\x{0072}\x{0061}\x{00C2}\x{00B7} " .
          "\x{0068}\x{00E1}\x{00F0}\x{0061}\x{0041} " .
          "\x{00C4}\x{006C}\x{006E}\x{007E}\x{0061}\x{0053}\x{007E}\x{0061} " .
          "\x{0062}\x{0069}\x{00C4}\x{006E}\x{00B7}\x{0074}\x{0069}\x{0062}\x{0061}\x{0041}\x{0068}\x{0129}\x{002E} " .
          "\x{006B}\x{0061}\x{0079}\x{00B7}\x{0066}\x{0061} " .
          "\x{00C4}\x{006C}\x{00B7}\x{0048}\x{0061}\x{0041}\x{006C}\x{0075}\x{003F}";

my $encode = encode "habash", $utf;
my $decode = decode "habash", $hsb;

is $encode, $hsb, '$encode is $hsb';
is $decode, $utf, '$decode is $utf';

is $encode, (encode "habash", $decode), 'encode(..., $decode) is fine';
is $decode, (decode "habash", $encode), 'decode(..., $encode) is fine';
