## no critic (ProhibitComplexRegexes)

use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT explain is isa_ok is_deeply like note ok plan subtest use_ok ) ], tests => 5;
use Test::Fatal qw( exception );

use JSON::PP    ();
use URI::Escape qw( uri_unescape );

my $class;

BEGIN {
  $class = 'JSON::Pointer::Marpa';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

my $json_pp = JSON::PP->new->utf8->allow_nonref( 1 );

subtest 'JSON to Perl decode' => sub {
  plan tests => 7;

  # JSON can represent four primitive types (strings, numbers, booleans,
  # and null) and two structured types (objects and arrays).
  my $json_document = '{"name": "Alice", "age": 25}';
  is_deeply $json_pp->decode( $json_document ), { name => 'Alice', age => 25 }, 'object';
  $json_document = '["bar", "baz"]';
  is_deeply $json_pp->decode( $json_document ), [ qw( bar baz ) ], 'array';
  $json_document = 'null';
  is $json_pp->decode( $json_document ), undef, 'null';
  $json_document = 'true';
  # https://metacpan.org/dist/Types-Bool/view/lib/Types/Bool.pod#DESCRIPTION
  isa_ok my $perl_document = $json_pp->decode( $json_document ), 'JSON::PP::Boolean';
  ok $perl_document, 'true';
  $json_document = 'false';
  isa_ok $perl_document = $json_pp->decode( $json_document ), 'JSON::PP::Boolean';
  ok not( $perl_document ), 'false' ## no critic (RequireTestLabels)
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
    "m~1n": 8,
    "qux": {
      "corge": "grault",
      "thud": "fred"
    },
    "boolean": {
       "updated": true,
       "paid": false
    },
    "unknown": null
  }
JSON_OBJECT

note explain $json_object;

my $perl_hashref = $json_pp->decode( $json_object );

note explain $perl_hashref;

subtest 'Error handling described in section 7' => sub {
  plan tests => 6;

  like exception { $class->get( $perl_hashref, '/foo/string' ) },
    qr/Currently referenced type 'ARRAY' isn't a JSON object!\n\z/,
    'array is referenced with a non-numeric token that not even refers to an object member';

  like exception { $class->get( $perl_hashref, '/a~1b/666' ) },
    qr/Currently referenced type '' isn't a JSON structured type \(array or object\)!\n\z/,
    'value is referenced with a numeric token';

  like exception { $class->get( $perl_hashref, '/foo/2' ) },
    qr/JSON array has been accessed with an index \d+ that is greater than or equal to the size of the array!\n\z/,
    'array index out of bounds';

  like exception { $class->get( $perl_hashref, '/47' ) },
    qr/JSON object has been accessed with a member .* that does not exist!\n\z/, ##
    'object member does not exist';

  like exception { $class->get( $perl_hashref, '/qux/' ) },
    qr/JSON object has been accessed with a member .* that does not exist!\n\z/, ##
    'empty string object member does not exist';

  like exception { $class->get( $perl_hashref, '/foo/-' ) }, qr/Handling of '-' array index isn't implemented!\n\z/,
    'not implemented'
};

subtest 'JSON Pointer RFC6901 examples from section 5 and section 6' => sub {
  plan tests => 20;

  my $json_string = '""';                             # JSON string representation of a JSON pointer (RFC6901 section 5)
  my $perl_string = $json_pp->decode( $json_string );
  note 'JSON string: ', $json_string, ' PERL string: ', $perl_string;
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref, 'the whole JSON object';

  $json_string = '"/foo"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ foo }, $perl_string;

  $json_string = '"/foo/0"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ foo }->[ 0 ], $perl_string;

  $json_string = '"/foo/1"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ foo }->[ 1 ], $perl_string;

  $json_string = '"/"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ '' }, $perl_string;

  $json_string = '"/a~1b"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'a/b' }, $perl_string;

  $json_string = '"/c%d"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'c%d' }, $perl_string;
  is uri_unescape( $perl_string ), $perl_string, "$perl_string (nothing to unescape)";
  $perl_string = '#/c%25d';    # URI fragment identifier representation of a JSON pointer (RFC6901 section 6)
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'c%d' }, $perl_string;

  $json_string = '"/e^f"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'e^f' }, $perl_string;
  $perl_string = '#/e%5Ef';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'e^f' }, $perl_string;

  $json_string = '"/g|h"';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'g|h' }, $perl_string;
  $perl_string = '#/g%7Ch';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'g|h' }, $perl_string;

  $json_string = '"/i\\\j"';
  #$json_string = '"/i\u005Cj"'; # will work too
  $perl_string = $json_pp->decode( $json_string );
  note 'JSON string: ', $json_string, ' PERL string: ', $perl_string;
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'i\j' }, $perl_string;
  $perl_string = '#/i%5Cj';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'i\j' }, $perl_string;

  $json_string = '"/k\"l"';
  $perl_string = $json_pp->decode( $json_string );
  note 'JSON string: ', $json_string, ' PERL string: ', $perl_string;
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'k"l' }, $perl_string;
  $perl_string = '#/k%22l';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'k"l' }, $perl_string;

  $json_string = '"/ "';
  $perl_string = $json_pp->decode( $json_string );
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ ' ' }, $perl_string;
  $perl_string = '#/%20';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ ' ' }, $perl_string;

  $perl_string = '/m~01n';
  is_deeply $class->get( $perl_hashref, $perl_string ), $perl_hashref->{ 'm~1n' }, $perl_string
};

subtest 'Point to JSON primitives' => sub {
  plan tests => 5;

  my $json_string = '"/boolean/updated"';
  my $perl_string = $json_pp->decode( $json_string );
  isa_ok my $perl_boolean = $class->get( $perl_hashref, $perl_string ), 'JSON::PP::Boolean';
  ok $perl_boolean, 'true';
  $json_string = '"/boolean/paid"';
  $perl_string = $json_pp->decode( $json_string );
  isa_ok $perl_boolean = $class->get( $perl_hashref, $perl_string ), 'JSON::PP::Boolean';
  ok not( $perl_boolean ), 'false'; ## no critic (RequireTestLabels)
  $json_string = '"/unknown"';
  $perl_string = $json_pp->decode( $json_string );
  ok not( defined $class->get( $perl_hashref, $perl_string ) ), 'null' ## no critic (RequireTestLabels)
}
