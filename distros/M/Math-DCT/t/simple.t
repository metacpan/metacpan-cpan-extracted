use Test2::Tools::Compare qw'array float';
use Test2::V0;

use Math::DCT ':all';

my $array    = [qw/90 100 100 105/];
my $arrayref = [
    [90,  100],
    [100, 105],
];

my $expect1d = array {
    item float(395);
    item float(-13.8581929876693);
    item float(-3.53553390593274);
    item float(-5.74025148547635);
    end();
};

my $expect2d = array {
    item float(395);
    item float(-10.6066017177982);
    item float(-10.6066017177982);
    item float(-2.5);
    end();
};

my $result = dct1d($array);
is($result, $expect1d, "1d");

$result = dct2d($array);
is($result, $expect2d, "2d");

$result = dct2d($array, 2);
is($result, $expect2d, "2d - define size");

$result = dct([$array]);
is($result, [$expect1d], "1d - auto");

$result = dct($arrayref);
is(
    $result,
    [
        array {
            item float(395);
            item float(-10.6066017177982);
        },
        array {
            item float(-10.6066017177982);
            item float(-2.5);
        }
    ],
    "2d - auto"
);

$result = idct2d([395, -10.6066017177982, -10.6066017177982, -2.5], 2);

is($result->[$_], float($array->[$_]), "2d iDCT matches original")
    for 0..3;

done_testing;