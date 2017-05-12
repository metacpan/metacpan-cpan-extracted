package JSON::YAJL::Parser;
use strict;
use warnings;
our $VERSION = '0.10';

require XSLoader;
XSLoader::load( 'JSON::YAJL::Parser', $VERSION );

1;

=head1 NAME

JSON::YAJL::Parser - JSON parsing with YAJL

=head1 SYNOPSIS

  use JSON::YAJL;
  my $text;
  my $parser = JSON::YAJL::Parser->new(
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
  my $json
      = '{"integer":123,"double":4,"number":3.141,"string":"a string","string2":"another string","null":null,"true":true,"false":false,"map":{"key":"value","array":[1,2,3]}}';
  $parser->parse($json);
  $parser->parse_complete();
  # $text is now:
  # map_open
  # map_key: integer
  # number: 123
  # map_key: double
  # number: 4
  # map_key: number
  # number: 3.141
  # map_key: string
  # string: a string
  # map_key: string2
  # string: another string
  # map_key: null
  # null
  # map_key: true
  # bool: 1
  # map_key: false
  # bool: 0
  # map_key: map
  # map_open
  # map_key: key
  # string: value
  # map_key: array
  # array_open
  # number: 1
  # number: 2
  # number: 3
  # array_close
  # map_close
  # map_close

=head1 DESCRIPTION

This module allows you to parse JSON with YAJL. This is quite a low-level
interface for parsing JSON.

You pass callbacks which are called whenever a small token of JSON is parsed.

This is a very early release to see how cross-platform the underlying code is.
The API may change in future.

=head1 METHODS

=head2 new

The constructor. You pass in if JavaScript style comments will be allowed in
the JSON input (both slash star and slash slash) and if invalid UTF8 strings
should cause a parse error. You also pass in callbacks. The missing callbacks
below are for integer and double - as there is no difference in Perl they are
both sent through the number callback instead.

  my $parser = JSON::YAJL::Parser->new(
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

=head2 parse

Parses some JSON. You can call this multiple times:

  $parser->parse($json);

=head2 parse_complete

Parse any remaining buffered JSON. Since YAJL is a stream-based parser,
without an explicit end of input, yajl sometimes can't decide if content
at the end of the stream is valid or not. For example, if "1" has been
fed in, yajl can't know whether another digit is next or some character
that would terminate the integer token:

  $parser->parse_complete();

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<JSON::YAJL>, L<JSON::YAJL::Generator>
