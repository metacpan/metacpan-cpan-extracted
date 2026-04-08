use strict;
use warnings;
use Test::More;
use JSON::YY ':doc';

my $doc = jdoc '{"s":"hi","n":42,"f":3.14,"t":true,"fa":false,"nu":null,"a":[1],"o":{"x":1}}';

# positive tests
ok jis_str  $doc, "/s",  'jis_str positive';
ok jis_num  $doc, "/n",  'jis_num positive (int)';
ok jis_num  $doc, "/f",  'jis_num positive (float)';
ok jis_int  $doc, "/n",  'jis_int positive';
ok jis_real $doc, "/f",  'jis_real positive';
ok jis_bool $doc, "/t",  'jis_bool positive (true)';
ok jis_bool $doc, "/fa", 'jis_bool positive (false)';
ok jis_null $doc, "/nu", 'jis_null positive';
ok jis_arr  $doc, "/a",  'jis_arr positive';
ok jis_obj  $doc, "/o",  'jis_obj positive';

# negative tests
ok !jis_str  $doc, "/n",  'jis_str negative (number)';
ok !jis_num  $doc, "/s",  'jis_num negative (string)';
ok !jis_int  $doc, "/f",  'jis_int negative (float)';
ok !jis_real $doc, "/n",  'jis_real negative (int)';
ok !jis_bool $doc, "/n",  'jis_bool negative (number)';
ok !jis_null $doc, "/n",  'jis_null negative (number)';
ok !jis_arr  $doc, "/o",  'jis_arr negative (object)';
ok !jis_obj  $doc, "/a",  'jis_obj negative (array)';

# missing path returns false
ok !jis_str  $doc, "/nope", 'jis_str missing path';
ok !jis_obj  $doc, "/nope", 'jis_obj missing path';

# root
ok jis_obj  $doc, "",  'jis_obj root';
ok !jis_arr $doc, "",  'jis_arr root negative';

# jpp
{
    my $pretty = jpp $doc, "/o";
    like $pretty, qr/\n/, 'jpp has newlines';
    like $pretty, qr/"x"/, 'jpp has content';
}

# jraw
{
    my $d = jdoc '{}';
    jraw $d, "/data", '[1,2,{"nested":true}]';
    is jtype $d, "/data", "array", 'jraw creates array';
    is jlen $d, "/data", 3, 'jraw array length';
    ok jis_bool $d, "/data/2/nested", 'jraw nested bool';

    # jraw at root
    jraw $d, "", '{"replaced":1}';
    is jencode $d, "", '{"replaced":1}', 'jraw root replacement';

    # jraw with append
    $d = jdoc '{"arr":[1]}';
    jraw $d, "/arr/-", '{"x":2}';
    is jencode $d, "/arr", '[1,{"x":2}]', 'jraw append';
}

# decode_doc
{
    my $coder = JSON::YY->new(utf8 => 1);
    my $doc = $coder->decode_doc('{"a":1}');
    is ref $doc, 'JSON::YY::Doc', 'decode_doc returns Doc';
    is jgetp $doc, "/a", 1, 'decode_doc content';
    jset $doc, "/b", 2;
    is jencode $doc, "", '{"a":1,"b":2}', 'decode_doc mutable';
}

done_testing;
