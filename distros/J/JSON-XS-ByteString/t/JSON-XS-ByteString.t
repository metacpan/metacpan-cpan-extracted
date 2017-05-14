# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl gutil-JSON2-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 24;
BEGIN { use_ok('JSON::XS::ByteString') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $data = ['Cindy 好漂亮', { Cindy => '最漂亮了' }];
my $json = JSON::XS::ByteString::encode_json($data);
is($json, '["Cindy 好漂亮",{"Cindy":"最漂亮了"}]', 'encode_json');
my $data2 = JSON::XS::ByteString::decode_json($json);
my $data3 = JSON::XS::ByteString::decode_json_safe($json);
is_deeply($data2, $data, 'decode_json');
is_deeply($data3, $data, 'decode_json');
is_deeply(JSON::XS::ByteString::decode_json(JSON::XS::ByteString::encode_json([undef])), [undef], 'encode/decode undef');

{
    my $o = [1];
    $o->[0] = undef;
    is_deeply(JSON::XS::ByteString::decode_json(JSON::XS::ByteString::encode_json($o)), [undef], 'encode/decode dirty undef');
}

is(JSON::XS::ByteString::encode_json({"Cindy 好漂亮"=>1}), '{"Cindy 好漂亮":"1"}', 'encode utf8 hash key');
is_deeply(JSON::XS::ByteString::decode_json('{"Cindy 好漂亮":1}'), {"Cindy 好漂亮"=>1}, 'decode utf8 hash key');

{
    my $data = ["\x80"];
    is(JSON::XS::ByteString::encode_json($data), qq(["\x80"]), 'encode wrongly utf8');
    is_deeply($data, ["\x80"], 'wrongly utf8 back');
}

is(JSON::XS::ByteString::encode_json([join '', map { chr hex $_ } qw(C0 A2)]), qq(["\xC0\xA2"]), "codepoint shoud be shorter");
is(JSON::XS::ByteString::encode_json([join '', map { chr hex $_ } qw(F5 84 81 B9)]), qq(["\xF5\x84\x81\xB9"]), "codepoint after U+10FFFF");

{
    my $data = ['a',\2,3,\'12a'];
    is(JSON::XS::ByteString::encode_json($data), '["a",2,"3",12]', "scalar ref as number hint");
    is(JSON::XS::ByteString::encode_json($data), '["a",2,"3",12]', "scalar ref as number hint twice");
}

{
    my $array_obj = bless [3], 'array';
    my $hash_obj = bless {a => 2}, 'hash';
    my $data = ['a', $array_obj, '4', $hash_obj, \5];
    my $before_json = Dumper($data);
    is(JSON::XS::ByteString::encode_json_unblessed($data), qq(["a","$array_obj","4","$hash_obj",5]));
    my $after_json = Dumper($data);
    is($before_json, $after_json);
}
{
    my $hash = {'now' => 1.123};
    my $before_json = Dumper($hash);
    is(JSON::XS::ByteString::encode_json($hash), qq({"now":"1.123"}));
    my $after_json = Dumper($hash);
    is($before_json, $after_json);
}

{
    my @a;
    $a[1] = 1;
    is(JSON::XS::ByteString::encode_json(\@a), qq([null,"1"]));
}

sub f {
    JSON::XS::ByteString::encode_json(\@_);
}
{
    is(f('Cindy 最漂亮了', 3), qq(["Cindy 最漂亮了","3"]));
    is(JSON::XS::ByteString::encode_json('Cindy 最漂亮了'), qq("Cindy 最漂亮了"));
}
{
    is(JSON::XS::ByteString::decode_json('"漂亮的 Cindy \/\/\k\""'), '漂亮的 Cindy //\\k"');
    is(JSON::XS::ByteString::encode_json('"漂亮的 Cindy //\k</script>'), '"\"漂亮的 Cindy //\\\\k<\\/script>"');
}
{
    my $data = [1, 2, 3];
    push @$data, $data;
    is(JSON::XS::ByteString::encode_json($data), '["1","2","3",null]');
}
