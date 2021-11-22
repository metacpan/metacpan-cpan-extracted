use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Test::NoWarnings;

use Format::Util::Numbers qw(roundnear roundcommon commas to_monetary_number_format formatnumber financialrounding get_min_unit);

subtest 'roundnear' => sub {
    is(roundnear(0,    345.56789), 345.56789, 'No rounding is correct.');
    is(roundnear(1,    345.56789), 346,       'Ones is correct.');
    is(roundnear(0.01, 345.56789), 345.57,    'Hundredths rounding is correct.');
    is(roundnear(0.02, 345.56789), 345.56,    'Two hundredths rounding is correct.');
    is(roundnear(10,   345.56789), 350,       'No rounding is correct.');
    is(roundnear(0,    undef),     undef,     'Rounding undef yields undef.');
};

subtest 'roundcommon' => sub {
    cmp_ok(roundcommon(0,    345.56789), '==', 345.56789, 'No rounding is correct.');
    cmp_ok(roundcommon(1,    345.56789), '==', 346,       'Ones is correct.');
    cmp_ok(roundcommon(0.1,  345.56789), '==', 345.6,     'Correct rounding for 1 decimal place');
    cmp_ok(roundcommon(0.01, 345.56789), '==', 345.57,    'Hundredths rounding is correct.');
    cmp_ok(roundcommon(0.02, 345.56789), '==', 345.56789, 'Two hundredths rounding is not supported.');
    cmp_ok(roundcommon(10,   345.56789), '==', 345.56789, 'Not supported, only supported integer is 1');
    is(roundcommon(0, undef), undef, 'Rounding undef yields undef.');
    cmp_ok(roundcommon(1e-2,  10.456),            '==', 10.46,         'Rounding with exponential precision');
    cmp_ok(roundcommon(-1e-2, 10.456),            '==', 10.456,        'incorrect precision returns same value back');
    cmp_ok(roundcommon(1e-10, 10.56783333331239), '==', 10.5678333333, 'Rounding with exponential precision');
    cmp_ok(roundcommon(0.01,  0.025),             '==', 0.03,          'Correct rounding, round away from zero');
    cmp_ok(roundcommon(0.01,  -0.025),            '==', -0.03,         'Correct rounding, round away from zero');
    cmp_ok(roundcommon(0.001, 150.9065),          '==', 150.907,       'Correct rounding, handled floating point error');
};

subtest 'commas' => sub {
    is(commas(12345.6789, 0), '12,346',      '0 decimal commas is correct');
    is(commas(12345.6789, 1), '12,345.7',    '1 decimal commas is correct');
    is(commas(12345.6789, 2), '12,345.68',   '2 decimal commas is correct');
    is(commas(12345.6789, 3), '12,345.679',  '3 decimal commas is correct');
    is(commas(12345.6789, 4), '12,345.6789', '4 decimal commas is correct');

    is(commas(12345.00, 0),   '12,345',       '0 decimal commas is correct');
    is(commas(12345, 0),      '12,345',       '0 decimal commas is correct');
    is(commas(1234567, 0),    '1,234,567',    'integer value >1m is correct');
    is(commas(1234567),       '1,234,567',    'integer value >1m with no DP parameter is correct');
    is(commas(1234567.89, 2), '1,234,567.89', 'floating point value >1m is correct');

    is(commas('N/A',    4), 'N/A',        'Non-numeric commas returns same');
    is(commas(.0004,    0), '0',          'Virgule does not produce -0');
    is(commas(100.34,   1), 100.3,        'Virgule fine with smaller numbers');
    is(commas(-1234.56, 3), '-1,234.560', 'Virgule on negatives is fine');
    is(commas(-1234.56, 1), '-1,234.6',   'Virgule does not round down toward zero');
};

subtest 'to_monetary_number_format' => sub {
    is(to_monetary_number_format(undef),        '0.00',           'undef to_monetary_number_format is correct');
    is(to_monetary_number_format('N/A'),        'N/A',            'nonnumeric to_monetary_number_format is correct');
    is(to_monetary_number_format(123456789),    '123,456,789.00', 'Integer to_monetary_number_format is correct');
    is(to_monetary_number_format(123456789, 1), '123,456,789', 'Integer to_monetary_number_format is correct when requested to remove int decimals');
    is(to_monetary_number_format(12345678.9),   '12,345,678.90', 'One decimal to_monetary_number_format is correct');
    is(to_monetary_number_format(12345678.9, 1),
        '12,345,678.90', 'One decimal to_monetary_number_format is correct when requested to remove int decimals');
    is(to_monetary_number_format(1234567.89), '1,234,567.89', 'Two decimal to_monetary_number_format is correct');
    is(to_monetary_number_format(123456.789), '123,456.79',   'Three to_monetary_number_format is correct');

    is(to_monetary_number_format(-4567.89), '-4,567.89', 'negative number to_monetary_number_format is correct');
    is(to_monetary_number_format(-456.789), '-456.79',   'negative number to_monetary_number_format is correct, no leading ","');
    is(to_monetary_number_format(-56.7),    '-56.70',    'negative number to_monetary_number_format is correct, add 2 decimal places');
};

subtest 'formatnumber' => sub {
    is formatnumber('amount', 'USD'), undef, 'undef number comes back same, no formatting done';
    is formatnumber('amount',  'USD', 'abc'), 'abc', 'invalid number comes back same, no formatting done';
    is formatnumber('amount',  'USD', '+.'),  '+.',  'invalid number comes back same, no formatting done';
    is formatnumber('invalid', 'USD', 10),    '10',  'invalid precision type sends back the same value';
    is formatnumber('amount',  'FOO', 10),    '10',  'invalid currency type sends back the same value';

    is formatnumber('amount', 'USD', 10.345),  '10.35',  'Changed the input number';
    is formatnumber('amount', 'USD', -10.345), '-10.35', 'Changed the input number';
    is formatnumber('amount', 'USD', 10.344),  '10.34',  'trimmed the input number';
    is formatnumber('amount', 'EUR', 10.394),  '10.39',  'trimmed the input number';
    is formatnumber('amount', 'JPY', 10.398),  '10.40',  'Changed the input number';
    is formatnumber('amount', 'AUD', -10.398), '-10.40', 'Changed the input number';

    is formatnumber('amount', 'USD', 10),               '10.00',       'USD 10 -> 10.00';
    is formatnumber('amount', 'USD', 10.000001),        '10.00',       'USD 10.000001 -> 10.00';
    is formatnumber('amount', 'EUR', 10.000001),        '10.00',       'EUR 10.000001 -> 10.00';
    is formatnumber('amount', 'JPY', 10.000001),        '10.00',       'JPY 10.000001 -> 10.00';
    is formatnumber('amount', 'BTC', 10),               '10.00000000', 'BTC 10 -> 10.00000000';
    is formatnumber('amount', 'BTC', 10.000001),        '10.00000100', 'BTC 10.000001 -> 10.00000100';
    is formatnumber('amount', 'BTC', 10.0000000000001), '10.00000000', 'BTC 10.0000000000001 -> 10.00000000';
    is formatnumber('amount', 'ETH', 10),               '10.00000000', 'ETH 10 -> 10.00000000';
    is formatnumber('amount', 'ETH', 10.000001),        '10.00000100', 'ETH 10.000001 -> 10.00000100';
    is formatnumber('amount', 'ETH', 10.0000000000001), '10.00000000', 'ETH 10.0000000000001 -> 10.00000000';
};

subtest 'financialrounding' => sub {
    is financialrounding('amount', 'USD'), undef, 'undef number comes back same, no formatting done';
    is financialrounding('amount', 'USD', 'abc'), 'abc', 'invalid number comes back same, no formatting done';
    is financialrounding('amount', 'USD', '+.'),  '+.',  'invalid number comes back same, no formatting done';
    cmp_ok financialrounding('invalid', 'USD', 10), '==', 10, 'invalid precision type sends back the same value';
    cmp_ok financialrounding('amount',  'FOO', 10), '==', 10, 'invalid currency type sends back the same value';

    cmp_ok financialrounding('amount', 'USD', 10.345),  '==', 10.35,  'Changed the input number';
    cmp_ok financialrounding('amount', 'USD', 10.344),  '==', 10.34,  'Changed the input number';
    cmp_ok financialrounding('amount', 'USD', 10.394),  '==', 10.39,  'trimmed the input number';
    cmp_ok financialrounding('amount', 'USD', -10.394), '==', -10.39, 'trimmed the input number';
    cmp_ok financialrounding('amount', 'USD', 10.398),  '==', 10.40,  'Changed the input number';
    cmp_ok financialrounding('amount', 'USD', -10.398), '==', -10.40, 'Changed the input number';

    cmp_ok financialrounding('amount', 'USD', 10),               '==', 10,        'USD 10 -> 10.00';
    cmp_ok financialrounding('amount', 'USD', 10.000001),        '==', 10,        'USD 10.000001 -> 10.00';
    cmp_ok financialrounding('amount', 'EUR', 10.000001),        '==', 10,        'EUR 10.000001 -> 10.00';
    cmp_ok financialrounding('amount', 'JPY', 10.000001),        '==', 10,        'JPY 10.000001 -> 10.00';
    cmp_ok financialrounding('amount', 'AUD', 10.000001),        '==', 10,        'AUD 10.000001 -> 10.00';
    cmp_ok financialrounding('amount', 'BTC', 10),               '==', 10,        'BTC 10 -> 10.00000000';
    cmp_ok financialrounding('amount', 'BTC', 10.000001),        '==', 10.000001, 'BTC 10.000001 -> 10.00000100';
    cmp_ok financialrounding('amount', 'BTC', 10.0000000000001), '==', 10,        'BTC 10.0000000000001 -> 10.00000000';
    cmp_ok financialrounding('amount', 'BTC', 0.0000000650001),  '==', 0.00000007,
        'BTC 0.000000065 -> 0.00000007 changed the number to higher value, need to be careful with this';
    cmp_ok financialrounding('amount', 'ETH', 10),               '==', 10,        'ETH 10 -> 10.00000000';
    cmp_ok financialrounding('amount', 'ETH', 10.000001),        '==', 10.000001, 'ETH 10.000001 -> 10.00000100';
    cmp_ok financialrounding('amount', 'ETH', 10.0000000000001), '==', 10,        'ETH 10.0000000000001 -> 10.00000000';
    cmp_ok financialrounding('amount', 'ETH', 0.0000000650001),  '==', 0.00000007,
        'ETH 0.000000065 -> 0.00000007 changed the number to higher value, need to be careful with this';
    cmp_ok(financialrounding('amount', 'USD', 0.025),  '==', 0.03,  'Correct rounding, round away from zero');
    cmp_ok(financialrounding('amount', 'USD', -0.025), '==', -0.03, 'Correct rounding, round away from zero');
};

subtest 'regression' => sub {
# Now we just want to make sure that it works with all kinds of inputs, so we'll sort of fuzz test it.
    foreach my $i (1 .. 100) {
        my $j = rand() * rand(100000);
        cmp_ok(roundnear(1 / $i, $j), '>=', 0, 'roundnear runs for (' . 1 / $i . ',' . $j . ')');
        ok(commas($j, $i),                'commas runs for (' . $j . ',' . $i . ')');
        ok(to_monetary_number_format($j), 'to_monetary_number_format runs for (' . $j . ')');
    }

    foreach my $i (-100 .. -1) {
        my $j = rand() * rand(-100000);
        cmp_ok(roundnear(1 / $i, $j), '<=', 0, 'roundnear runs for (' . 1 / $i . ',' . $j . ')');
    }
};

subtest 'get_min_unit' => sub {
# Test minimum units
    is get_min_unit('USD'), formatnumber('price', 'USD', 0.01),       'Correct minimum unit for USD';
    is get_min_unit('EUR'), formatnumber('price', 'EUR', 0.01),       'Correct minimum unit for EUR';
    is get_min_unit('GBP'), formatnumber('price', 'GBP', 0.01),       'Correct minimum unit for GBP';
    is get_min_unit('AUD'), formatnumber('price', 'AUD', 0.01),       'Correct minimum unit for AUD';
    is get_min_unit('JPY'), formatnumber('price', 'JPY', 1),          'Correct minimum unit for JPY';
    is get_min_unit('BTC'), formatnumber('price', 'BTC', 0.00000001), 'Correct minimum unit for BTC';
    is get_min_unit('LTC'), formatnumber('price', 'LTC', 0.00000001), 'Correct minimum unit for LTC';
    is get_min_unit('ETH'), formatnumber('price', 'ETH', 0.00000001), 'Correct minimum unit for ETH';
    is get_min_unit('ETC'), formatnumber('price', 'ETC', 0.00000001), 'Correct minimum unit for ETC';
    dies_ok { get_min_unit('nonexistent_currency') }, qr(Currency nonexistent_currency and/or its precision is not defined.), 'Incorrect currency';
};

subtest 'precision' => sub {
# Test default precisions
    my $precisions = Format::Util::Numbers::get_precision_config();

    is $precisions->{amount}->{USD}, '2', 'Correct amount precision for USD';
    is $precisions->{amount}->{EUR}, '2', 'Correct amount precision for EUR';
    is $precisions->{amount}->{GBP}, '2', 'Correct amount precision for GBP';
    is $precisions->{amount}->{AUD}, '2', 'Correct amount precision for AUD';
    is $precisions->{amount}->{JPY}, '2', 'Correct amount precision for JPY';
    is $precisions->{amount}->{BTC}, '8', 'Correct amount precision for BTC';
    is $precisions->{amount}->{LTC}, '8', 'Correct amount precision for LTC';
    is $precisions->{amount}->{ETH}, '8', 'Correct amount precision for ETH';
    is $precisions->{amount}->{ETC}, '8', 'Correct amount precision for ETC';

    is $precisions->{price}->{USD}, '2', 'Correct price precision for USD';
    is $precisions->{price}->{EUR}, '2', 'Correct price precision for EUR';
    is $precisions->{price}->{GBP}, '2', 'Correct price precision for GBP';
    is $precisions->{price}->{AUD}, '2', 'Correct price precision for AUD';
    is $precisions->{price}->{JPY}, '0', 'Correct price precision for JPY';
    is $precisions->{price}->{BTC}, '8', 'Correct price precision for BTC';
    is $precisions->{price}->{LTC}, '8', 'Correct price precision for LTC';
    is $precisions->{price}->{ETH}, '8', 'Correct price precision for ETH';
    is $precisions->{price}->{ETC}, '8', 'Correct price precision for ETC';
};
