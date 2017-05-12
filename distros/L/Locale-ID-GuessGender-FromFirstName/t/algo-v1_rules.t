#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

use Locale::ID::GuessGender::FromFirstName qw(guess_gender);

is((guess_gender({algos=>['v1_rules']}, "kartini"))[0]{result}, "F", "kartini");
is((guess_gender({algos=>['v1_rules']}, "kartono"))[0]{result}, "M", "kartono");
