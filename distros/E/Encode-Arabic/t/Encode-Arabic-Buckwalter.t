#########################

use Test::More tests => 7;

BEGIN {

    use_ok 'Encode::Arabic::Buckwalter', ':xml';
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

my $tim = "AiqoraOo h`*aA {ln~aS~a bi{notibaAhK. kayofa {loHaAlu?";

my $encode = encode "buckwalter", $utf;
my $decode = decode "buckwalter", $tim;

is $encode, $tim, '$encode is $tim';
is $decode, $utf, '$decode is $utf';

is $encode, (encode "buckwalter", $decode), 'encode(..., $decode) is fine';
is $decode, (decode "buckwalter", $encode), 'decode(..., $encode) is fine';

$using_xml = eval q { use Encode::Arabic::Buckwalter ':xml'; decode 'buckwalter', 'OWI' };
$classical = eval q { use Encode::Arabic::Buckwalter; decode 'buckwalter', '>&<' };

is $classical, $using_xml, '$classical eq $using_xml';
is $classical, "\x{0623}\x{0624}\x{0625}", '$classical eq "\x{0623}\x{0624}\x{0625}"';
