#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 4;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('de_DE');
my $quoted = $locale->quote('abc');
is($quoted, '„abc“', 'Quote German');
$quoted = $locale->quote("z $quoted z");
is($quoted, '„z ‚abc‘ z“', 'Quote German');
$quoted = $locale->quote("dd 'z $quoted z dd");
is($quoted, '„dd \'z ‚z „abc“ z‘ z dd“', 'Quote German');