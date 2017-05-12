#!perl
use strict;
use warnings;
use ExtUtils::testlib;
use JSON::YAJL;
use Test::Exception;
use Test::More;

my $text;
my $parser_callbacks = JSON::YAJL::Parser->new(
    0, 0,
    [   sub { $text .= "null\n" },
        sub { $text .= "bool: @_\n" },
        undef,
        undef,
        sub { $text .= "number: @_\n" },
        sub { $text .= "string: @_\n" },
        sub { $text .= "map_open\n" },
        sub { $text .= "map_key: @_\n" },
        sub { $text .= "map_close\n" },
        sub { $text .= "array_open\n" },
        sub { $text .= "array_close\n" },
    ]
);
isa_ok( $parser_callbacks, 'JSON::YAJL::Parser' );
my $json
    = '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}';
$parser_callbacks->parse($json);
$parser_callbacks->parse_complete();
is( $text, 'map_open
map_key: integer
number: 123
map_key: double
number: 4
map_key: number
number: 3.141
map_key: string
string: a string
map_key: string2
string: another string
map_key: null
null
map_key: true
bool: 1
map_key: false
bool: 0
map_key: map
map_open
map_key: key
string: value
map_key: array
array_open
number: 1
number: 2
number: 3
array_close
map_close
map_close
'
);

my $parser = JSON::YAJL::Parser->new( 0, 0, [] );
isa_ok( $parser, 'JSON::YAJL::Parser' );
$parser->parse($json);
$parser->parse_complete();

my $parser_empty = JSON::YAJL::Parser->new( 0, 0, [] );
isa_ok( $parser_empty, 'JSON::YAJL::Parser' );
throws_ok { $parser_empty->parse_complete() } qr/premature EOF/;

my $parser_incomplete = JSON::YAJL::Parser->new( 0, 0, [] );
isa_ok( $parser_incomplete, 'JSON::YAJL::Parser' );
$parser_incomplete->parse('{"a": 3');
throws_ok { $parser_incomplete->parse_complete() } qr/premature EOF/;

my $parser_unallowed_token = JSON::YAJL::Parser->new( 0, 0, [] );
isa_ok( $parser_unallowed_token, 'JSON::YAJL::Parser' );
throws_ok { $parser_unallowed_token->parse('}') } qr/unallowed token/;

my $parser_invalid_object_key = JSON::YAJL::Parser->new( 0, 0, [] );
isa_ok( $parser_invalid_object_key, 'JSON::YAJL::Parser' );
throws_ok { $parser_invalid_object_key->parse('{ 3: 3}') }
qr/invalid object key/;

done_testing();
