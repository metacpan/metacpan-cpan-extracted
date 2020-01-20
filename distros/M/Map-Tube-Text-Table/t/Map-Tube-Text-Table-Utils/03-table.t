use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Text::Table::Utils qw(table);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $ret = table('Title', [1, 2, 3], ['A', 'BB', 'CCC'], [
        ['E', 'A', 'A'],
        ['A', 'Ga', 'Acv'],
]);
my $right_ret = decode_utf8(<<'END');
┌──────────────┐
│ Title        │
├───┬────┬─────┤
│ A │ BB │ CCC │
├───┼────┼─────┤
│ E │ A  │ A   │
│ A │ Ga │ Acv │
└───┴────┴─────┘
END
is($ret, $right_ret, 'Simple test.');

# Test.
$ret = table('Title', [1, 2, 3], ['A', 'BB', 'CCC'], []);
is($ret, '', 'No data.');

# Test.
$ret = table('Title', [1, 2, 3], undef, [
        ['E', 'A', 'A'],
        ['A', 'Ga', 'Acv'],
]);
$right_ret = decode_utf8(<<'END');
┌──────────────┐
│ Title        │
├───┬────┬─────┤
│ E │ A  │ A   │
│ A │ Ga │ Acv │
└───┴────┴─────┘
END
is($ret, $right_ret, 'Test without header.');
