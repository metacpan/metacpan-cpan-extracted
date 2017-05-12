#!perl -T

use strict;
use warnings;

use Test::More;

use Encoding::FixLatin;
use Encoding::FixLatin::XS;

ok(1, "Successfully loaded Encoding::FixLatin::XS via 'use'");

diag(
    "Testing Encoding::FixLatin::XS $Encoding::FixLatin::XS::VERSION, "
  . "Encoding::FixLatin $Encoding::FixLatin::VERSION, Perl $], $^X"
);

ok(
    UNIVERSAL::can('Encoding::FixLatin::XS','_fix_latin_xs'),
    'expected XS sub is available'
);

# Alias XS sub name to something shorter for test purposes

*fx = \&Encoding::FixLatin::XS::_fix_latin_xs;

is(
    fx("Plain ASCII", 0, 1),
    "Plain ASCII",
    "plain ASCII input is returned unchanged"
);

is(
    fx("Longer plain ASCII with newline\n", 0, 1),
    "Longer plain ASCII with newline\n",
    "longer plain ASCII input with newline is returned unchanged"
);

is(
    fx("Plain ASCII\0with embedded null byte", 0, 1),
    "Plain ASCII\0with embedded null byte",
    "plain ASCII input with embedded null byte returned unchanged"
);

is(
    fx("M\xC4\x81ori", 0, 1),
    "M\x{101}ori",
    "UTF-8 bytes passed through"
);

is(
    fx("Caf\xE9", 0, 1),
    "Caf\x{E9}",
    "latin byte transcoded to UTF-8"
);

is(
    fx("Caf\xE9 Rom\xC4\x81 (\xE2\x82\xAC9.99)", 0, 1),
    "Caf\x{E9} Rom\x{101} (\x{20AC}9.99)",
    "mixed latin and UTF-8 translated to UTF-8"
);

done_testing;

