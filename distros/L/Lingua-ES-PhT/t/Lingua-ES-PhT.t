# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-PhT.t'

#########################

use strict;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 24;
BEGIN { use_ok('Lingua::ES::PhT', ':test') };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my %words = (
    "pasa" => ["p", "a'", "s", "a"],
    "cinco" => ["T", "i'", "n", "k", "o"],
    "gélido" => ["x", "e'", "l", "i", "d", "o"],
    "mujer" => ["m", "u", "x", "e'", "r"],
    "marrón" => ["m", "a", "rr", "o'", "n"],
    "whisky" => ["g", "u", "i'", "s", "k", "i"],
    "fácil" => ["f", "a'", "T", "i", "l"],
    "hielo" => ["L", "e'", "l", "o"],
    "acelerarán" => ["a", "T", "e", "l", "e", "r", "a", "r", "a'", "n"],
    "miau" => ["m", "j", "a'", "u"],
    "miércoles" => ["m", "j", "e'", "r", "k", "o", "l", "e", "s"],
    "rezo" => ["rr", "e'", "T", "o"],
    "eunuco" => ["e", "u", "n", "u'", "k", "o"],
    "huevo" => ["w", "e'", "b", "o"],
    "patxi" => ["p", "a'", "tS", "i"],
    "psicología" => ["s", "i", "k", "o", "l", "o", "x", "i'", "a"],
    "gneis" => ["n", "e'", "j", "s"],
    "perfectamente" => ["p", "e", "r", "f", "e'", "k", "t", "a", "m", "e", "n", "t", "e"],
    "californiano" =>  ["k", "a", "l", "i", "f", "o", "r", "n", "j", "a'", "n", "o"],
    "mente" => ["m", "e'", "n", "t", "e"],
    "gurrea" => ["x", "u", "rr", "e'", "a"],
    "cañete" => ["k", "a", "J", "e'", "t", "e"],
	"éxodo" => ["e'", "k", "s", "o", "d", "o"]
);

foreach my $word (keys %words) {
    is_deeply([transcribe($word)], $words{$word}, 
              "Test transcribe '$word'");
}
