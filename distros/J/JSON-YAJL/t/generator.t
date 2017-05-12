#!perl
use strict;
use warnings;
use ExtUtils::testlib;
use JSON::YAJL;
use Test::Exception;
use Test::More;

my $generator_default = JSON::YAJL::Generator->new();
isa_ok( $generator_default, 'JSON::YAJL::Generator' );
is( create($generator_default),
    '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}'
);

my $generator_pretty = JSON::YAJL::Generator->new( 1, '   ' );
isa_ok( $generator_pretty, 'JSON::YAJL::Generator' );
is( create($generator_pretty), '{
   "integer": 123,
   "double": 4,
   "number": 3.141,
   "string": "a string",
   "string2": "another string",
   "null": null,
   "true": true,
   "false": false,
   "map": {
      "key": "value",
      "array": [
         1,
         2,
         3
      ]
   }
}
'
);

my $generator_keys_must_be_strings = JSON::YAJL::Generator->new();
$generator_keys_must_be_strings->map_open();
throws_ok { $generator_keys_must_be_strings->integer(1) }
qr/Keys must be strings/;

my $generator_generation_complete = JSON::YAJL::Generator->new();
$generator_generation_complete->map_open();
$generator_generation_complete->map_close();
throws_ok { $generator_generation_complete->map_open() }
qr/Generation complete/;

my $generator_max_depth = JSON::YAJL::Generator->new();
foreach my $i ( 1 .. 127 ) {
    $generator_max_depth->map_open();
    $generator_max_depth->string("a$i");
}
throws_ok { $generator_max_depth->map_open() } qr/Max depth exceeded/;

# Only works in 5.8.8 and later (and not Windows or MirOS BSD)
if ( $] > 5.008008 && $^O ne 'MSWin32' && $^O ne 'mirbsd' ) {
    my $generator_invalid_number = JSON::YAJL::Generator->new();
    $generator_invalid_number->map_open();
    $generator_invalid_number->string('number');
    throws_ok { $generator_invalid_number->double( 0 + "inf" ); }
    qr/Invalid number/;
    throws_ok { $generator_invalid_number->double( 0 + "nan" ); }
    qr/Invalid number/;
}

done_testing();

sub create {
    my $generator = shift;
    $generator->map_open();
    $generator->string("integer");
    $generator->integer(123);
    $generator->string("double");
    $generator->double("4");    # we can't test this in a cross-platform way
    $generator->string("number");
    $generator->number("3.141");
    $generator->string("string");
    $generator->string("a string");
    $generator->string("string2");
    $generator->string("another string");
    $generator->string("null");
    $generator->null();
    $generator->string("true");
    $generator->bool(1);
    $generator->string("false");
    $generator->bool(0);
    $generator->string("map");
    $generator->map_open();
    $generator->string("key");
    $generator->string("value");
    $generator->string("array");
    $generator->array_open();
    $generator->integer(1);
    $generator->integer(2);
    $generator->integer(3);
    $generator->array_close();
    $generator->map_close();
    $generator->map_close();
    return $generator->get_buf;
}

