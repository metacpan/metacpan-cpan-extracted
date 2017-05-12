use Test::More;

# copied over from JSON::PC and modified to use JSON::XS
# and modified yet again to use JSON::SL

use strict;
use JSON::SL qw(decode_json);

my ($js,$obj);

$js  = q|{}|;



$js  = q|{"foo":"bar"}|;
$obj = decode_json($js);
is($obj->{foo},'bar');


$js  = q|[1,2,3]|;
$obj = decode_json($js);
is($obj->[1],2);

$js = q|{"foo":{"bar":"hoge"}}|;
$obj = decode_json($js);
is($obj->{foo}->{bar},'hoge');

$js = '["\\u0001"]';
$obj = decode_json($js);
is($obj->[0],"\x01");

$js = q|["\\u001b"]|;
$obj = decode_json($js);
is($obj->[0],"\e");

$js = '{"id":"}';
eval q{ decode_json($js) };
ok($@);
like($@, qr/incomplete/i);

done_testing();
