use strict;
use warnings;
use Test::More;

eval { require Test::LeakTrace };
plan skip_all => 'Test::LeakTrace required' if $@;

use Test::LeakTrace;
use JSON::YY qw(encode_json decode_json decode_json_ro);
use JSON::YY ':doc';

# functional API
no_leaks_ok { encode_json({a => 1, b => [2, 3]}) } 'encode_json no leak';
no_leaks_ok { decode_json('{"a":1,"b":[2,3]}') } 'decode_json no leak';
no_leaks_ok { decode_json_ro('{"a":1,"b":[2,3]}') } 'decode_json_ro no leak';

# OO API
no_leaks_ok {
    my $c = JSON::YY->new(utf8 => 1);
    $c->encode({x => 1});
} 'OO encode no leak';
no_leaks_ok {
    my $c = JSON::YY->new(utf8 => 1);
    $c->decode('{"x":1}');
} 'OO decode no leak';

# Doc API
no_leaks_ok { my $d = jdoc '{"a":1}' } 'jdoc no leak';
no_leaks_ok { my $d = jfrom {a => 1} } 'jfrom no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    jgetp $d, "/a";
} 'jgetp no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    jset $d, "/b", 2;
} 'jset no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    my $sub = jget $d, "/a";
} 'jget (borrow) no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1,"b":2}';
    jdel $d, "/a";
} 'jdel no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    jclone $d, "";
} 'jclone no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    jencode $d, "";
} 'jencode no leak';

# iterator
no_leaks_ok {
    my $d = jdoc '[1,2,3]';
    my $it = jiter $d, "";
    while (defined(my $v = jnext $it)) {}
} 'iterator no leak';

# value constructors
no_leaks_ok { jstr "hello" } 'jstr no leak';
no_leaks_ok { jnum 42 } 'jnum no leak';
no_leaks_ok { jbool 1 } 'jbool no leak';
no_leaks_ok { jnull } 'jnull no leak';
no_leaks_ok { jarr } 'jarr no leak';
no_leaks_ok { jobj } 'jobj no leak';

# jpatch / jmerge
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    my $p = jdoc '[{"op":"add","path":"/b","value":2}]';
    jpatch $d, $p;
} 'jpatch no leak';
no_leaks_ok {
    my $d = jdoc '{"a":1}';
    my $p = jdoc '{"b":2}';
    jmerge $d, $p;
} 'jmerge no leak';

# decode_json_ro scalar root
no_leaks_ok { decode_json_ro('"hello"') } 'decode_json_ro string root no leak';
no_leaks_ok { decode_json_ro('42') } 'decode_json_ro number root no leak';
no_leaks_ok { decode_json_ro('true') } 'decode_json_ro bool root no leak';
no_leaks_ok { decode_json_ro('null') } 'decode_json_ro null root no leak';

done_testing;
