use Test::More tests => 4;
use lib 'lib';
use charnames qw(:full);

BEGIN { use_ok('Encode::Repair', 'repair_double') or exit };

is repair_double("small ae: \xc3\x83\xc2\xa4"), "small ae: \N{LATIN SMALL LETTER A WITH DIAERESIS}",
   "can repair double-encoded a+diaeresis";

is repair_double("\xc3\x83\xc2\xa4", {via => 'Latin1'}),
   "\N{LATIN SMALL LETTER A WITH DIAERESIS}",
   "can repair double-encoded a+diaeresis with explicit latin1 'via'";

is repair_double("beta: \xc4\xaa\xc2\xb2", {via => 'Latin-7'}),
   "beta: \N{GREEK SMALL LETTER BETA}",
   "double-encoded beta via Latin-7 (Greek)";
