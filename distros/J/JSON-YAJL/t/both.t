#!perl
use strict;
use warnings;
use ExtUtils::testlib;
use JSON::YAJL;
use Test::Exception;
use Test::More;

my $generator = JSON::YAJL::Generator->new();

my $text;
my $parser = JSON::YAJL::Parser->new(
    0, 0,
    [   sub { $generator->null },
        sub { $generator->bool(shift) },
        undef,
        undef,
        sub { $generator->number(shift) },
        sub { $generator->string(shift) },
        sub { $generator->map_open },
        sub { $generator->string(shift) },
        sub { $generator->map_close },
        sub { $generator->array_open },
        sub { $generator->array_close },
    ]
);
isa_ok( $parser, 'JSON::YAJL::Parser' );
my $json
    = '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}';
$parser->parse($json);
$parser->parse_complete();
is( $generator->get_buf, $json );
done_testing();
