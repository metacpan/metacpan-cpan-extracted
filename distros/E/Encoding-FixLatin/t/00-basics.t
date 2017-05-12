#!perl -T

use strict;
use warnings;

use Test::More;

use Encoding::FixLatin;

ok(1, "Successfully loaded Encoding::FixLatin::XS via 'use'");

diag(
    "Testing Encoding::FixLatin $Encoding::FixLatin::VERSION, Perl $], $^X"
);

ok(!__PACKAGE__->can('fix_latin'), 'fix_latin() function was not imported');

is(Encoding::FixLatin::fix_latin(undef), undef, 'undefined input handled correctly');
is(Encoding::FixLatin::fix_latin(''), '', 'empty string handled correctly');

eval {
    Encoding::FixLatin::fix_latin('', dwim => 1);
};
like("$@", qr{Unknown option 'dwim'}, 'bad option caught');
like("$@", qr{at.*00-basics.*line},   'calling context in error message');

done_testing;

