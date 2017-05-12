#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// B.1.1: octal literals
// 15 tests
// ===================================================

// Naughty Test::Builder!
peval('
 no warnings "redefine";
 my $orig_diag = \\&Test::Builder::diag;
 *Test::Builder::diag
   = sub { $_[1] =~ /numbers for your test/ and return; goto &$orig_diag };
');

is(00, 0, '00')
is(01, 1, '01')
is(02, 2, '02')
is(03, 3, '03')
is(04, 4, '04')
is(05, 5, '05')
is(06, 6, '06')
is(07, 7, '07')
is(000, 0, '000')
is(037, 31, '037')
is(040, 32, '040')
is(0401, 257,                    '0401')
is(0771, 505,                      '0771')
is(00001, 1, '00001')
is(03771, 2041                         , '03771')

// ===================================================
// B.1.2: octal escapes
// 16 tests
// ===================================================

is("\0", String.fromCharCode(0), '"\\0"')
is("\1", String.fromCharCode(1), '"\\1"')
is("\2", String.fromCharCode(2), '"\\2"')
is("\3", String.fromCharCode(3), '"\\3"')
is("\4", String.fromCharCode(4), '"\\4"')
is("\5", String.fromCharCode(5), '"\\5"')
is("\6", String.fromCharCode(6), '"\\6"')
is("\7", String.fromCharCode(7), '"\\7"')
is("\8", "8",                     '"\\8"')
is("\00", String.fromCharCode(0), '"\\00"')
is("\37", String.fromCharCode(31), '"\\37"')
is("\40", String.fromCharCode(32), '"\\40"')
is("\401", ' 1',                    '"\\401"')
is("\771", '?1',                      '"\\771"')
is("\0001", String.fromCharCode(0) +'1', '"\\0001"')
is("\3771", 'ÿ1'                         , '"\\3771"')
