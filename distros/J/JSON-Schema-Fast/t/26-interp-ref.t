use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }

# a recursive (linked-list) schema drives the interpreter through $ref
my $v = JSON::Schema::Fast->compile({
    '$defs' => {
        Node => {
            type       => 'object',
            required   => ['val'],
            properties => {
                val  => { type => 'integer' },
                next => { '$ref' => '#/$defs/Node' },
            },
        },
    },
    '$ref' => '#/$defs/Node',
});

ok( $v->is_valid(J('{"val":1,"next":{"val":2,"next":{"val":3}}}')),
    'valid nested list');
ok(!$v->is_valid(J('{"val":1,"next":{"val":"x"}}')),
    'nested val wrong type');
ok(!$v->is_valid(J('{"next":{"val":1}}')),
    'missing required val at top');

# a legitimately deep-but-finite structure does not trip the depth guard
my $deep = '{"val":0';
$deep .= ',"next":{"val":0' for 1 .. 100;
$deep .= '}' x 101;
ok( $v->is_valid(J($deep)), 'deep-but-finite (100 levels) validates');

done_testing;
