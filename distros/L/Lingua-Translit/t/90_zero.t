use strict;
use Test::More tests => 15;

my $name        =   "DIN 1460 UKR";
my $reversible  =   1;

use Lingua::Translit;

my $tr = new Lingua::Translit($name);

my $output;


# 1
is($tr->can_reverse(), $reversible, "$name: reversibility");

# 2
$output = $tr->translit( "0" );

is($output, "0", "$name: transliteration #1");

# 3
$output = $tr->translit( 0 );

is($output, "0", "$name: transliteration #2");

# 4
$output = $tr->translit( "\x30" );

is($output, "0", "$name: transliteration #3");

# 5
$output = $tr->translit();

is($output, undef, "$name: transliteration #4");

# 6
$output = $tr->translit( undef );

is($output, undef, "$name: transliteration #5");

# 7
$output = $tr->translit( '' );

is($output, '', "$name: transliteration #6");

# 8
$output = $tr->translit( '01' );

is($output, '01', "$name: transliteration #7");

# 9
$output = $tr->translit_reverse( "0" );

is($output, "0", "$name: transliteration #8");

# 10
$output = $tr->translit_reverse( 0 );

is($output, "0", "$name: transliteration #9");

# 11
$output = $tr->translit_reverse( "\x30" );

is($output, "0", "$name: transliteration #10");

# 12
$output = $tr->translit_reverse();

is($output, undef, "$name: transliteration #11");

# 13
$output = $tr->translit_reverse( undef );

is($output, undef, "$name: transliteration #12");

# 14
$output = $tr->translit_reverse( '' );

is($output, '', "$name: transliteration #13");

# 15
$output = $tr->translit_reverse( '01' );

is($output, '01', "$name: transliteration #14");

# vim: set ft=perl sts=4 sw=4 ts=4 ai et:
