package JSON::YAJL::Generator;
use strict;
use warnings;
our $VERSION = '0.10';

require XSLoader;
XSLoader::load( 'JSON::YAJL::Generator', $VERSION );

1;

=head1 NAME

JSON::YAJL::Generator - JSON generation with YAJL

=head1 SYNOPSIS

  use JSON::YAJL;
  my $generator = JSON::YAJL::Generator->new();
  # or to beautify (indent):
  # my $generator = JSON::YAJL::Generator->new( 1, '    ' );
  $generator->map_open();
  $generator->string("integer");
  $generator->integer(123);
  $generator->string("double");
  $generator->double("1.23");
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
  print $generator->get_buf;
  $generator->clear;

  # This prints non-beautified:
  {"integer":123,"double":1.2299999999999999822,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}
  # or beautified:
  {
     "integer": 123,
     "double": 1.2299999999999999822,
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

=head1 DESCRIPTION

This module allows you to generate JSON with YAJL. This is quite a low-level
interface for generating JSON and it accumulates JSON in an internal buffer
until you fetch it.

If you create certain invalid JSON constructs then this module throws an
exception.

This is a very early release to see how cross-platform the underlying code is.
The API may change in future.

=head1 METHODS

=head2 new

The constructor. You can pass in a flag on whether to generate indented
(beautiful) output and if so how many spaces to use:

  my $generator = JSON::YAJL::Generator->new();
  # or to beautify (indent):
  # my $generator = JSON::YAJL::Generator->new( 1, '    ' );

=head2 null

Generate a null:

  $generator->null();

=head2 bool

Generate a boolean value:

  $generator->bool(1);
  $generator->bool(0);

=head2 integer

Generate an integer:

  $generator->integer(123);

=head2 double

Generate a floating point number:

  $generator->double("1.23");

=head2 number

Generate a generic number. The underlying C library has to specify numeric
types, but in Perl this is unnecessary so you probably just want to use this
method:

  $generator->number("3.141");

=head2 string

Generate a string:

  $generator->string("a string");

=head2 map_open

Begins a hash:

  $generator->map_open();

=head2 map_close

Ends a hash:

  $generator->map_close();

=head2 array_open

Begins an array:

  $generator->array_open();

=head2 array_close

Ends an array:

  $generator->array_close();

=head2 get_buf

Access the null terminated generator buffer. If incrementally outputing JSON,
one should call clear to clear the buffer. This allows stream generation.

  print $generator->get_buf;

=head2 clear

Clear the output buffer, but maintain all internal generation state. This
function will not "reset" the generator state, and is intended to enable
incremental JSON outputing:

  $generator->clear;

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<JSON::YAJL>, L<JSON::YAJL::Parser>
