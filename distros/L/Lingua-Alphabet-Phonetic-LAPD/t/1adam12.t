use strict;
use warnings;
use Test::More tests => 1;
use Lingua::Alphabet::Phonetic;

is(join('', Lingua::Alphabet::Phonetic->new("LAPD")->enunciate("1-A-12")), 'One-Adam-OneTwo', "1-A-12 = One-Adam-OneTwo");
