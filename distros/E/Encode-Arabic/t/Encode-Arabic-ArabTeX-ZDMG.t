#########################

use Test::More tests => 10;

BEGIN {

    use_ok 'Encode::Arabic::ArabTeX::ZDMG', ':xml';
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok 'Encode::Arabic::ArabTeX::ZDMG', qw 'encode decode encoder decoder';

ok defined &encode, "import Encode's encode() function";
ok defined &decode, "import Encode's decode() function";

$Encode::Mapper::options{'Encode::Arabic::ArabTeX::ZDMG'}{'join'} = undef;

my $encoder = Encode::Arabic::ArabTeX::ZDMG->encoder();
my $decoder = Encode::Arabic::ArabTeX::ZDMG->decoder();

ok defined $Encode::Arabic::ArabTeX::ZDMG::encoder, 'encoder defined';
ok defined $Encode::Arabic::ArabTeX::ZDMG::decoder, 'decoder defined';

my $utf = decode "utf8", "\x49\x71\x72\x61\xCA\xBE\x20" . "\x68\xC4\x81\xE1\xB8\x8F\xC4\x81\x20" .
          "\xCA\xBC\x6E\x2D\x6E\x61\xE1\xB9\xA3\xE1\xB9\xA3\x61\x20" .
          "\x62\x69\x2D\xCA\xBC\x6E\x74\x69\x62\xC4\x81\x68\x69\x6E\x2E\x20" .
          "\x4B\x61\x79\x66\x61\x20" . "\xCA\xBC\x6C\x2D\xE1\xB8\xA5\xC4\x81\x6C\x75\x3F";

my $tex = "\\cap iqra' h_a_dA an-na.s.sa bi-intibAhiN. \\cap kayfa al-.hAlu?";

my $encode = encode "arabtex-zdmg", $utf;
my $decode = decode "arabtex-zdmg", $tex;

TODO: {

    local $TODO = 'Non-simple mapping';

    is $encode, $tex, '$encode is $tex';
  # is $decode, $utf, '$decode is $utf';

    is $encode, (encode "arabtex-zdmg", $decode), 'encode(..., $decode) is fine';
  # is $decode, (decode "arabtex-zdmg", $encode), 'decode(..., $encode) is fine';
}

ok ! Encode::is_utf8($encode), "from Perl's internal utf8: " . $encode;
ok Encode::is_utf8($decode), "into Perl's internal utf8: " . encode 'utf8', $decode;
