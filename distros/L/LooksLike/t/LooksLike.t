#! /usr/bin/env perl

use strict;
use warnings;

use Scalar::Util (); #qw( looks_like_number );

use Test2::V0;

ok( require LooksLike, 'Can require LooksLike' );

my @binary  = qw( 0b01010101 0b10101010 );
my @octal   = qw( 07777777 0666666 055555 04444 0333 022 01 00 );
my @hex     = qw( 0x0123456789abcdef 0xfedcba9876543210 0xdeadbeef );
my @decimal = qw( .1 2.34 56.789 0. );

foreach my $num (@binary) {
    is LooksLike::binary($num), 1, "$num is binary";
}
foreach my $num (@octal) {
    is LooksLike::octal($num),  1, "$num is octal";
}
foreach my $num (@hex) {
    is LooksLike::hex($num),    1, "$num is hex";
}
foreach my $num (@decimal) {
    is LooksLike::decimal($num),    1, " $num is decimal";
    is LooksLike::decimal("-$num"), 1, "-$num is decimal";
}

my @infs  = ( qw( inf infinity ), 1e9999 );
diag( "1e9999 == ", $infs[-1] );
my @nans  = ( qw( nan NaN ), $infs[-1] / $infs[-1] );
diag( "$infs[-1]/$infs[-1] == ", $nans[-1] );
my @odds  = ( qw(   1   23  987654321 ),   123_456_789 );
my @evens = ( qw( 456 7890 9876543210 ), 1_234_567_890 );
my @ints  = ( @odds, @evens );
my @nums  = ( qw( 0.1 2.34 56.789 ), 4**4**4, 10 / 3 );

my @zeroes = ( qw( 0 0.0 0e0 000 ), 0, 0.0, 0e0 );
my @words  = (qw( infinite nano notanumber ));

# These should only work on Perl 5.22 and greater.
push @infs,
    map  { int( rand(2) ) ? uc() : $_ }
        grep { Scalar::Util::looks_like_number($_) }
            '1.#inf', '1.#infinity', '1.#inf00';
push @nans,
    map  { int( rand(2) ) ? uc() : $_ }
        grep { Scalar::Util::looks_like_number($_) }
            qw( nanq nans qnan snan ),
            '1.#nans',     '1.#qnan',
            '1.#nan(123)', '1.#nan(0x45)',
            '1.#ind',      '1.#ind00',
        ;

# Infinity
for my $num (@infs) {
    is( LooksLike::infinity($num),    1, " '$num' is infinity" );
    is( LooksLike::infinity("-$num"), 1, "'-$num' is infinity" );

    my $Uc = ucfirst "$num";
    is( LooksLike::infinity($Uc), 1, " '$Uc' is infinity" );
    my $UC = uc "$num";
    is( LooksLike::infinity($UC), 1, " '$UC' is infinity" );
}

for my $num ( qw( apple ), @nans, @ints, @nums, @words ) {
    is( LooksLike::infinity($num),    '', " '$num' is not infinity" );
    is( LooksLike::infinity( -$num ), '', "'-$num' is not infinity" );
}
is( LooksLike::infinity(undef), undef, "undef is not infinity" );

# NaN
for my $num (@nans) {
    is( LooksLike::nan($num),    1, " '$num' is NaN" );
    is( LooksLike::nan( -$num ), 1, "'-$num' is NaN" );

    my $Uc = ucfirst "$num";
    is( LooksLike::nan($Uc), 1, " '$Uc' is NaN" );
    my $UC = uc "$num";
    is( LooksLike::nan($UC), 1, " '$UC' is NaN" );
}

for my $num ( qw( banana ), @infs, @ints, @nums, @words ) {
    is( LooksLike::nan($num),    '', " '$num' is not NaN" );
    is( LooksLike::nan( -$num ), '', "'-$num' is not NaN" );
}
is( LooksLike::nan(undef), undef, "undef is not NaN" );

# Integer
for my $num (@ints) {
    is( LooksLike::integer($num),    1, " '$num' is an integer" );
    is( LooksLike::integer( -$num ), 1, "'-$num' is an integer" );
}

for my $num ( qw( cherry ), @infs, @nans, @nums, @words ) {
    is( LooksLike::integer($num),    '', " '$num' is not an integer" );
    is( LooksLike::integer( -$num ), '', "'-$num' is not an integer" );
}
is( LooksLike::integer(undef), undef, "undef is not an integer" );

# Numeric
for my $num ( @ints, @nums, @zeroes ) {
    is( LooksLike::numeric($num),    1, " '$num' is numeric" );
    is( LooksLike::numeric( -$num ), 1, "'-$num' is numeric" );

    my $Uc = ucfirst "$num";
    is( LooksLike::numeric($Uc), 1, " '$Uc' is numeric" );
    my $UC = uc "$num";
    is( LooksLike::numeric($UC), 1, " '$UC' is numeric" );
}

for my $num ( qw( date ), @words ) {
    is( LooksLike::numeric($num),    '', " '$num' is not numeric" );
    is( LooksLike::numeric( -$num ), '', "'-$num' is not numeric" );
}
is( LooksLike::numeric(undef), undef, "undef is not numeric" );

# Number
for my $num ( @infs, @ints, @nans, @nums, @zeroes ) {
    is( LooksLike::number($num),    1, " '$num' is a number" );
    is( LooksLike::number( -$num ), 1, "'-$num' is a number" );

    my $Uc = ucfirst "$num";
    is( LooksLike::number($Uc), 1, " '$Uc' is a number" );
    my $UC = uc "$num";
    is( LooksLike::number($UC), 1, " '$UC' is a number" );
}

for my $num ( qw( elderberry ), @words ) {
    is( LooksLike::number($num),    '', " '$num' is not a number" );
    is( LooksLike::number( -$num ), '', "'-$num' is not a number" );
}
is( LooksLike::number(undef), undef, "undef is not a number" );

# Zero
for my $num (@zeroes) {
    is( LooksLike::zero($num),    1, " '$num' is zero" );
    is( LooksLike::zero( -$num ), 1, "'-$num' is zero" );

    my $Uc = ucfirst "$num";
    is( LooksLike::zero($Uc), 1, " '$Uc' is zero" );
    my $UC = uc "$num";
    is( LooksLike::zero($UC), 1, " '$UC' is zero" );
}

for my $num ( qw( fig ), @words ) {
    is( LooksLike::zero($num),    '', " '$num' is not zero" );
    is( LooksLike::zero( -$num ), '', "'-$num' is not zero" );
}
is( LooksLike::zero(undef), undef, "undef is not zero" );

# Non-Zero
for my $num ( @infs, @ints, @nums ) {
    is( LooksLike::nonzero($num),    1, " '$num' is zero" );
    is( LooksLike::nonzero( -$num ), 1, "'-$num' is zero" );

    my $Uc = ucfirst "$num";
    is( LooksLike::nonzero($Uc), 1, " '$Uc' is zero" );
    my $UC = uc "$num";
    is( LooksLike::nonzero($UC), 1, " '$UC' is zero" );
}

for my $num ( qw( grape ), @zeroes, @words ) {
    is( LooksLike::nonzero($num),    '', " '$num' is not zero" );
    is( LooksLike::nonzero( -$num ), '', "'-$num' is not zero" );
}
is( LooksLike::zero(undef), undef, "undef is not zero" );

# Positive
for my $num ( @infs, @ints, @nums ) {
    is( LooksLike::positive($num),    1,  " '$num' is positive" );
    is( LooksLike::positive( -$num ), '', "'-$num' is not positive" );

    my $Uc = ucfirst "$num";
    is( LooksLike::positive($Uc), 1, " '$Uc' is positive" );
    my $UC = uc "$num";
    is( LooksLike::positive($UC), 1, " '$UC' is positive" );
}

for my $num ( qw( huckleberry ), @zeroes, @words ) {
    is( LooksLike::positive($num),    '', " '$num' is not positive" );
    is( LooksLike::positive( -$num ), '', "'-$num' is not positive" );
}
is( LooksLike::zero(undef), undef, "undef is not positive" );

# Negative
for my $num ( @infs, @ints, @nums ) {
    is( LooksLike::negative( -$num ), 1,  "'-$num' is negative" );
    is( LooksLike::negative($num),    '', " '$num' is not negative" );

    my $Uc = '-' . ucfirst "$num";
    is( LooksLike::negative($Uc), 1, "'$Uc' is negative" );
    my $UC = '-' . uc "$num";
    is( LooksLike::negative($UC), 1, "'$UC' is negative" );
}

for my $num ( qw( juniper ), @zeroes, @words ) {
    is( LooksLike::negative($num),    '', " '$num' is not negative" );
    is( LooksLike::negative( -$num ), '', "'-$num' is not negative" );
}
is( LooksLike::zero(undef), undef, "undef is not negative" );

# Even
for my $num ( @evens, 0 ) {
    is( LooksLike::even($num),    1, " '$num' is an even" );
    is( LooksLike::even( -$num ), 1, "'-$num' is an even" );

    is( LooksLike::odd($num),    '', " '$num' is not odd" );
    is( LooksLike::odd( -$num ), '', "'-$num' is not odd" );
}

for my $num ( qw( kiwi ), @nans, @infs, @nums, @words ) {
    is( LooksLike::even($num),    '', " '$num' is not even" );
    is( LooksLike::even( -$num ), '', "'-$num' is not even" );
}
is( LooksLike::even(undef), undef, "undef is not even" );

# Odd
for my $num (@odds) {
    is( LooksLike::odd($num),    1, " '$num' is an odd" );
    is( LooksLike::odd( -$num ), 1, "'-$num' is an odd" );

    is( LooksLike::even($num),    '', " '$num' is not even" );
    is( LooksLike::even( -$num ), '', "'-$num' is not even" );
}

for my $num ( qw( lemon ), @nans, @infs, @nums, @words ) {
    is( LooksLike::odd($num),    '', " '$num' is not odd" );
    is( LooksLike::odd( -$num ), '', "'-$num' is not odd" );
}
is( LooksLike::odd(undef), undef, "undef is not odd" );

# grok_number
#<<<    Do Not Let PerlTidy Touch the below section
my @numbers = (
# Start with numbers that are easy to parse.
#     _str     sign       number  fraction  exp_sign  exp_number        excess
[        '0',    '',         '0',    undef,    undef,      undef,           '' ],
[       '-0',   '-',         '0',    undef,    undef,      undef,           '' ],
[       '+0',   '+',         '0',    undef,    undef,      undef,           '' ],
[        '0.0',  '',         '0',      '0',    undef,      undef,           '' ],
[       '-0.0', '-',         '0',      '0',    undef,      undef,           '' ],
[       '+0.0', '+',         '0',      '0',    undef,      undef,           '' ],
[        '0E0',  '',         '0',    undef,       '',        '0',           '' ],
[       '-0E0', '-',         '0',    undef,       '',        '0',           '' ],
[       '+0E0', '+',         '0',    undef,       '',        '0',           '' ],
[        '1',    '',         '1',    undef,    undef,      undef,           '' ],
[       '-1',   '-',         '1',    undef,    undef,      undef,           '' ],
[       '+1',   '+',         '1',    undef,    undef,      undef,           '' ],
[        '1.0',  '',         '1',      '0',    undef,      undef,           '' ],
[       '-1.0', '-',         '1',      '0',    undef,      undef,           '' ],
[       '+1.0', '+',         '1',      '0',    undef,      undef,           '' ],
[        '1E0',  '',         '1',    undef,       '',        '0',           '' ],
[       '-1E0', '-',         '1',    undef,       '',        '0',           '' ],
[      '+1e-2', '+',         '1',    undef,      '-',        '2',           '' ],
[  '-34.5e+67', '-',        '34',      '5',      '+',       '67',           '' ],
[         '.8',  '',          '',      '8',    undef,      undef,           '' ],
[         '9.',  '',         '9',       '',    undef,      undef,           '' ],

[        'Inf',  '',       'Inf',    undef,    undef,      undef,           '' ],
[       '-inf', '-',       'inf',    undef,    undef,      undef,           '' ],
[       '+INF', '+',       'INF',    undef,    undef,      undef,           '' ],

[   'Infinity',  '',  'Infinity',    undef,    undef,      undef,           '' ],
[  '-infinity', '-',  'infinity',    undef,    undef,      undef,           '' ],
[  '+INFINITY', '+',  'INFINITY',    undef,    undef,      undef,           '' ],

[        'NaN',  '',       'NaN',    undef,    undef,      undef,           '' ],
[       '-nan', '-',       'nan',    undef,    undef,      undef,           '' ],
[       '+NAN', '+',       'NAN',    undef,    undef,      undef,           '' ],

# Not real numbers, but start looks like one
[   'infinite',  '',       'inf',    undef,    undef,      undef,      'inite' ],
[      '-nano', '-',       'nan',    undef,    undef,      undef,          'o' ],
[      '+nan0', '+',       'nan',    undef,    undef,      undef,          '0' ],
[     '123abc',  '',       '123',    undef,    undef,      undef,        'abc' ],
[    '456 xyz',  '',       '456',    undef,    undef,      undef,        'xyz' ],
[     '789efg',  '',       '789',    undef,    undef,      undef,        'efg' ],

# Not real numbers at all
[ 'notanumber', undef,     undef,    undef,    undef,      undef, 'notanumber' ],
[       'e123', undef,     undef,    undef,    undef,      undef,       'e123' ],
);
#>>>    Do Not Let PerlTidy Touch the above section

push @numbers,
    grep { Scalar::Util::looks_like_number( $_->[0] ) }
        [ '1.#inf',      '', 'inf',      (undef) x 3, '' ],
        [ '1.#inf00',    '', 'inf',      (undef) x 3, '' ],
        [ '1.#inFiniTy', '', 'inFiniTy', (undef) x 3, '' ],

        [ '1.#nan',      '', 'nan', undef, (undef) x 2, '' ],
        [ '1.#NaN',      '', 'NaN', undef, (undef) x 2, '' ],
        [ '1.#nan(123)', '', 'nan', '123', (undef) x 2, '' ],
        [ '1.#nan(0x4)', '', 'nan', '0x4', (undef) x 2, '' ],
        [ '1.#ind',      '', 'ind', undef, (undef) x 2, '' ],
        [ '1.#Ind00',    '', 'Ind', undef, (undef) x 2, '' ],
    ;

my @parts = qw( _str sign number fraction exp_sign exp_number excess );
for my $number (@numbers) {
    my $num = $number->[0];
    my %expected;
    @expected{@parts} = @$number;
    my %parsed;
    @parsed{@parts} = ( $num, LooksLike::grok_number($num) );
    is( \%parsed, \%expected, "'$num' parsed correctly" );

    my $lln = Scalar::Util::looks_like_number($num);
    is !!$lln, !length( $parsed{excess} ),
        "looks_like_number($num) == grok_number($num)";
}

done_testing();

