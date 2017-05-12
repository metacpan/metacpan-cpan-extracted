#!perl -T

use strict;
use warnings;

use Test::More tests => 5;
use Test::Differences;
use Test::NoWarnings;

BEGIN {
    use_ok 'Locale::TextDomain::OO::Util::Constants';
}

my $const = Locale::TextDomain::OO::Util::Constants->instance;


eq_or_diff
    $const->lexicon_key_separator,
    q{:},
    'lexicon_key_separator';
eq_or_diff
    $const->msg_key_separator,
    "\x04",
    'msg_key_separator';
eq_or_diff
    $const->plural_separator,
    "\x00",
    'plural_separator';
