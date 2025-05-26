use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT explain is isa_ok is_deeply like note ok plan subtest use_ok ) ], tests => 4;
use Test::Fatal qw( exception );

use JSON::PP    qw( decode_json );
use URI::Escape qw( uri_unescape );

my $class;

BEGIN {
  $class = 'JSON::Pointer::Marpa';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

subtest 'JSON to Perl decode' => sub {
  plan tests => 7;

  my $json_document = '{"name": "Alice", "age": 25}';
  is_deeply decode_json( $json_document ), { name => 'Alice', age => 25 }, 'object';
  $json_document = '["bar", "baz"]';
  is_deeply decode_json( $json_document ), [ qw( bar baz ) ], 'array';
  $json_document = 'null';
  is decode_json( $json_document ), undef, 'null';
  $json_document = 'true';
  isa_ok my $perl_document = decode_json( $json_document ), 'JSON::PP::Boolean';
  ok $perl_document, 'true';
  $json_document = 'false';
  isa_ok $perl_document = decode_json( $json_document ), 'JSON::PP::Boolean';
  ok not( $perl_document ), 'false'; ## no critic (RequireTestLabels)
};

# double quotes in JSON have to be escaped with a single backslash: \"
# backslashes in JSON have to be escaped with a single backslash: \\
my $json_object = <<'JSON_OBJECT';
  {
   "foo": ["bar", "baz"],
   "": 0,
   "a/b": 1,
   "c%d": 2,
   "e^f": 3,
   "g|h": 4,
   "i\\j": 5,
   "k\"l": 6,
   " ": 7,
   "m~1n": 8
  }
JSON_OBJECT

note explain $json_object;

my $perl_hashref = decode_json( $json_object );

note explain $perl_hashref;

like exception { $class->get( $perl_hashref, '/foo/-' ) }, qr/Handling of '-' array index not implemented!\n\z/, ## no critic (RequireExtendedFormatting)
  'not implemented';

subtest 'JSON Pointer RFC6901 examples from section 5 and section 6' => sub {
  plan tests => 19;

  my $json_string = '""';                          # JSON string representation of a JSON pointer (RFC6901 section 5)
  my $perl_string = decode_json( $json_string );
  note 'JSON string: ', $json_string, ' PERL string: ', $perl_string;
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref, 'the whole JSON object';

  $json_string = '"/foo"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ foo }, $perl_string;

  $json_string = '"/foo/0"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ foo }->[ 0 ], $perl_string;

  $json_string = '"/"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ '' }, $perl_string;

  $json_string = '"/a~1b"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'a/b' }, $perl_string;

  $json_string = '"/c%d"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'c%d' }, $perl_string;
  is uri_unescape( $perl_string ), $perl_string, "$perl_string (nothing to unescape)";
  $perl_string = '#/c%25d';    # URI fragment identifier representation of a JSON pointer (RFC6901 section 6)
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'c%d' }, $perl_string;

  $json_string = '"/e^f"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'e^f' }, $perl_string;
  $perl_string = '#/e%5Ef';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'e^f' }, $perl_string;

  $json_string = '"/g|h"';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'g|h' }, $perl_string;
  $perl_string = '#/g%7Ch';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'g|h' }, $perl_string;

  $json_string = '"/i\\\j"';
  #$json_string = '"/i\u005Cj"'; # will work too
  $perl_string = decode_json( $json_string );
  note 'JSON string: ', $json_string, ' PERL string: ', $perl_string;
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'i\j' }, $perl_string;
  $perl_string = '#/i%5Cj';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'i\j' }, $perl_string;

  $json_string = '"/k\"l"';
  $perl_string = decode_json( $json_string );
  note 'JSON string: ', $json_string, ' PERL string: ', $perl_string;
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'k"l' }, $perl_string;
  $perl_string = '#/k%22l';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'k"l' }, $perl_string;

  $json_string = '"/ "';
  $perl_string = decode_json( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ ' ' }, $perl_string;
  $perl_string = '#/%20';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ ' ' }, $perl_string;

  $perl_string = '/m~01n';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'm~1n' }, $perl_string;
};
