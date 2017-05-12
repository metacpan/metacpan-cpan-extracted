#########################

use Test::More tests => 10;

BEGIN {

    use_ok 'Encode::Arabic::ArabTeX', ':xml';
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok 'Encode::Arabic::ArabTeX', qw 'encode decode encoder decoder';

ok defined &encode, "import Encode's encode() function";
ok defined &decode, "import Encode's decode() function";

$Encode::Mapper::options{'Encode::Arabic::ArabTeX'}{'join'} = undef;

my $encoder = Encode::Arabic::ArabTeX->encoder();
my $decoder = Encode::Arabic::ArabTeX->decoder();

ok defined $Encode::Arabic::ArabTeX::encoder, 'encoder defined';
ok defined $Encode::Arabic::ArabTeX::decoder, 'decoder defined';

my $utf = "\x{0627}\x{0650}\x{0642}\x{0652}\x{0631}\x{064E}\x{0623}\x{0652} " .
          "\x{0647}\x{0670}\x{0630}\x{064E}\x{0627} " .
          "\x{0671}\x{0644}\x{0646}\x{0651}\x{064E}\x{0635}\x{0651}\x{064E} " .
          "\x{0628}\x{0650}\x{0671}\x{0646}\x{0652}\x{062A}\x{0650}\x{0628}\x{064E}\x{0627}\x{0647}\x{064D}. " .
          "\x{0643}\x{064E}\x{064A}\x{0652}\x{0641}\x{064E} " .
          "\x{0671}\x{0644}\x{0652}\x{062D}\x{064E}\x{0627}\x{0644}\x{064F}\x{061F}";

my $tex = "iqra' h_a_dA an-na.s.sa bi-intibAhiN. kayfa al-.hAlu?";

my $encode = encode "arabtex", $utf;
my $decode = decode "arabtex", $tex;

TODO: {

    local $TODO = 'Non-simple mapping';

    is $encode, $tex, '$encode is $tex';
  # is $decode, $utf, '$decode is $utf';

    is $encode, (encode "arabtex", $decode), 'encode(..., $decode) is fine';
  # is $decode, (decode "arabtex", $encode), 'decode(..., $encode) is fine';
}

ok ! Encode::is_utf8($encode), "from Perl's internal utf8: " . $encode;
ok Encode::is_utf8($decode), "into Perl's internal utf8: " . encode 'utf8', $decode;
