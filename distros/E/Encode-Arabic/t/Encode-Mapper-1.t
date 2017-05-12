#########################

use Test::More tests => 9;

BEGIN {

    use_ok 'Encode::Mapper';
}

require_ok 'Encode';
require_ok 'Data::Dumper';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok 'Encode::Mapper', qw 'new compile process recover compute dumper',
       qw 'encode decode', qw 'options import';

my $mapper = Encode::Mapper->new (

            map {

                (chr $_) x 2,

            } 0x00..0xFF

        );

my @tokens = (

            "\x{060C}",  ",",           "\x{0637}",  ".t",
            "\x{061B}",  ";",           "\x{0638}",  ".z",
            "\x{061F}",  "?",           "\x{0639}",  "`",
            "\x{0621}",  "'",           "\x{063A}",  ".g",
            "\x{0622}",  "'A",          "\x{0640}",  "--",
            "\x{0623}",  "'",           "\x{0641}",  "f",
            "\x{0624}",  "'",           "\x{0642}",  "q",
            "\x{0625}",  "'",           "\x{0643}",  "k",
            "\x{0626}",  "'",           "\x{0644}",  "l",
            "\x{0627}",  "A",           "\x{0645}",  "m",
            "\x{0628}",  "b",           "\x{0646}",  "n",
            "\x{0629}",  "T",           "\x{0647}",  "h",
            "\x{062A}",  "t",           "\x{0648}",  "w",
            "\x{062B}",  "_t",          "\x{0649}",  "Y",
            "\x{062C}",  "^g",          "\x{064A}",  "y",
            "\x{062D}",  ".h",          "\x{064B}",  "aN",
            "\x{062E}",  "_h",          "\x{064C}",  "uN",
            "\x{062F}",  "d",           "\x{064D}",  "iN",
            "\x{0630}",  "_d",          "\x{064E}",  "a",
            "\x{0631}",  "r",           "\x{064F}",  "u",
            "\x{0632}",  "z",           "\x{0650}",  "i",
            "\x{0633}",  "s",           "\x{0651}",  "\\shadda{}",
            "\x{0634}",  "^s",          "\x{0652}",  "\\sukuun{}",
            "\x{0635}",  ".s",          "\x{0670}",  "_a",
            "\x{0636}",  ".d",          "\x{0671}",  "A",

        );

push @tokens, qw 'ě š č ř ž ý á í é = ů ú';


ok defined $mapper,                 "use compile() as the constructor";
ok $mapper->isa('Encode::Mapper'),  "constructs the right class";

is  Encode::decode_utf8(join "", map {
                 UNIVERSAL::isa($_, 'CODE') ? $_->() : $_
             } $mapper->process(@tokens), $mapper->recover()),

   join("", map { Encode::is_utf8($_) ? $_ : Encode::decode_utf8($_) } @tokens),

   "identity mapping, bytes oriented";

is_deeply [ my @x = split //, "\x{c4}\x{80}"],
          [ split //, Encode::encode("utf8", "\x{0100}") ],
          'unicodeness test';

is_deeply [ map { ord } @x ], [ 0xC4, 0x80 ], 'byte comparison';
