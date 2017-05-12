#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

use Locale::ID::GuessGender::FromFirstName qw(guess_gender);

is((guess_gender({algos=>['common']}, "budi"))[0]{result}, "M", "budi");
is((guess_gender({algos=>['common']}, "lina"))[0]{result}, "F", "lina");
is((guess_gender({algos=>['common']}, "wati"))[0]{result}, "F", "wati");

