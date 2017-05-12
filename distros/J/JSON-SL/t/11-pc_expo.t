# copied over from JSON::PC and modified to use JSON::XS
# and modified again to use JSON::SL

use Test::More;
use strict;
use JSON::SL qw(decode_json);

#########################
my ($js,$obj);

$js  = q|[-12.34]|;
$obj = decode_json($js);
is($obj->[0], -12.34, 'digit -12.34');

$js  = q|[-1.234e5]|;
$obj = decode_json($js);
is($obj->[0], -123400, 'digit -1.234e5');

$js  = q|[1.23E-4]|;
$obj = decode_json($js);
is($obj->[0], 0.000123, 'digit 1.23E-4');


$js  = q|[1.01e+30]|;
$obj = decode_json($js);
is($obj->[0], 1.01e+30, 'digit 1.01e+30');

done_testing();