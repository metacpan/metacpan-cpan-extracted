# Test the 'get line at offset' routine.

use Test::More tests => 56;

use strict;
use warnings;
use lib './t/lib';
use Gzip::BinarySearch;
use Test::Gzip::BinarySearch;

my ($filename, $index) = fixture('dict');

my $bs = Gzip::BinarySearch->new(file => $filename);

is($bs->_get_line_at($_), "a\n", "t$_") for (0,1);
is($bs->_get_line_at($_), "abash\n", "t$_") for (2..7);
is($bs->_get_line_at($_), "abbreviates\n", "t$_") for (8);
is($bs->_get_line_at($_), "zits\n", "t$_") for (29631);
is($bs->_get_line_at($_), "zooms\n", "t$_") for (29632..29637);

wipe_index($index);

# more tricky...
($filename, $index) = fixture('edge');
$bs = Gzip::BinarySearch->new(file => $filename);

is($bs->_get_line_at($_),
    "SUPER LINE: CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAX\n",
    "t$_ - long line at start"
) for (0,1,10,50,168,169);

is($bs->_get_line_at($_),
    "Double newline to trip it up\n",
    "t$_ - prior to double newline"
) for (170,198);

is($bs->_get_line_at(199), "\n", "t199 - empty line");

is($bs->_get_line_at($_),
    "Very long lines: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZ\n",
    "t$_ - long line in middle",
) for (200,374);

is($bs->_get_line_at($_), "\n", "t$_ - empty lines") for (375..379);

is($bs->_get_line_at($_), "Lots of blank lines!\n", "t$_") for (380..400);

is($bs->_get_line_at($_),
    "Another long line: BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZ",
    "t$_ - long line at end, no newline",
) for (401,576,577);

wipe_index($index);

