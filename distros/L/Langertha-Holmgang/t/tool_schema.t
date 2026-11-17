#!/usr/bin/env perl
# Langertha::Holmgang::ToolSchema. Claims: the load check refuses what lies
# outside the JSON Schema subset, with the field path, recursively; per call
# every violation is reported with its path, integers and numbers may come as
# text, enum and const compare like the expectations do (const per call since
# k31; a const that is no scalar is refused at load), a type may be a list
# of types (k48: fits when one fits; refused at load when empty, unknown or
# doubled), a null in enum matches a null, and the texts are the German ones
# the model gets.
use strict;
use warnings;
use utf8;
use Test::More;

use Langertha::Holmgang::Error;
use Langertha::Holmgang::ToolSchema qw( check_schema schema_errors );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

sub refused {
  my ( $schema, $field, $re, $name ) = @_;
  my $e = Langertha::Holmgang::Error->caught( eval { check_schema( $schema, 'p' ); 1 } ? undef : $@ );
  ok( $e && $e->field eq $field && $e->reason =~ $re, $name ) or diag( $e ? "$e" : 'accepted' );
}

my $S = { type => 'object', required => [qw( name count )], properties => {
  name  => { type => 'string', minLength => 2, maxLength => 5, pattern => '^[a-z]+$' },
  count => { type => 'integer', minimum => 1, maximum => 9 },
  ratio => { type => 'number' },
  mode  => { type => 'string', enum => [qw( on off )] },
  on    => { type => 'boolean' },
  list  => { type => 'array', minItems => 1, maxItems => 2, items => { type => 'string' } },
  none  => { type => 'null' },
  fixed => { const => 'x' },
  three => { type => 'integer', const => 3 },
  yes   => { const => JSON::MaybeXS::true() },
  iban  => { type => [ 'string', 'null' ], pattern => '^[A-Z]{2}' },
  num   => { type => [qw( integer boolean )] },
  pick  => { type => [ 'string', 'null' ], enum => [ 'a', undef ] },
  pick2 => { type => [ 'string', 'null' ], enum => [ 'a' ] },
} };

is( check_schema( $S, 'p' ), $S, 'a schema in the subset passes and comes back' );
refused( { type => 'object', additionalProperties => 0 }, 'p.additionalProperties', qr/unknown key/, 'key outside the subset' );
refused( { type => 'tuple' }, 'p.type', qr/unknown type/, 'unknown type' );
refused( { properties => { a => { pattern => '(' } } }, 'p.properties.a.pattern', qr/invalid regular expression/, 'broken pattern, nested' );
refused( { properties => [] }, 'p.properties', qr/not a hash/, 'properties not a hash' );
refused( { items => { format => 'x' } }, 'p.items.format', qr/unknown key/, 'items checked too' );
refused( { required => 'a' }, 'p.required', qr/not a list/, 'required not a list' );
refused( { enum => 'a' }, 'p.enum', qr/not a list/, 'enum not a list' );
refused( { type => [] }, 'p.type', qr/empty list/, 'type list empty' );
refused( { type => [ 'string', 'text' ] }, 'p.type[1]', qr/unknown type/, 'type list with an unknown type' );
refused( { type => [ 'string', undef ] }, 'p.type[1]', qr/unknown type/, 'type list with a null (not "null")' );
refused( { type => [ 'string', [ 'null' ] ] }, 'p.type[1]', qr/unknown type/, 'type list nested' );
refused( { type => [ 'null', 'null' ] }, 'p.type[1]', qr/named twice/, 'type list with a type twice' );
refused( { properties => { a => { type => { x => 1 } } } }, 'p.properties.a.type', qr/unknown type/, 'type a hash, nested' );
refused( { const => [ 'a' ] }, 'p.const', qr/not a scalar/, 'const a list' );
refused( { properties => { a => { const => undef } } }, 'p.properties.a.const', qr/not a scalar/, 'const null, nested' );

is_deeply( [ schema_errors( { name => 'abc', count => 3 }, $S ) ], [], 'fitting arguments' );
is_deeply( [ schema_errors( { name => 'abc', count => '3', ratio => '0.5' }, $S ) ], [], 'integer and number as text' );
is_deeply( [ schema_errors( {}, $S ) ], [ '$.name: fehlt', '$.count: fehlt' ], 'required, in schema order' );
is_deeply( [ schema_errors( 'x', $S ) ], ['$: erwartet object'], 'wrong type stops at its level' );
is_deeply( [ schema_errors( { name => 'a', count => 0 }, $S ) ], [ '$.count: kleiner als 1', '$.name: zu kurz' ], 'minimum, minLength' );
is_deeply( [ schema_errors( { name => 'abcdef', count => 10 }, $S ) ], [ '$.count: größer als 9', '$.name: zu lang' ], 'maximum, maxLength' );
is_deeply( [ schema_errors( { name => 'AB', count => 1 }, $S ) ], ['$.name: passt nicht zu ^[a-z]+$'], 'pattern' );
is_deeply( [ schema_errors( { name => 'ab', count => 1.5 }, $S ) ], ['$.count: erwartet integer'], 'integer' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, mode => 'auto' }, $S ) ], ['$.mode: erlaubt sind on, off'], 'enum' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, on => 'yes' }, $S ) ], ['$.on: erwartet boolean'], 'boolean needs a JSON boolean' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, on => JSON::MaybeXS::true() }, $S ) ], [], '... and takes one' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, list => [] }, $S ) ], ['$.list: zu wenige Einträge'], 'minItems' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, list => [ 'a', 'b', 'c' ] }, $S ) ], ['$.list: zu viele Einträge'], 'maxItems' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, list => [ 'a', {} ] }, $S ) ], ['$.list[1]: erwartet string'], 'items with index' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, none => 0 }, $S ) ], ['$.none: erwartet null'], 'null' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, fixed => 'y' }, $S ) ], ['$.fixed: erlaubt ist x'], 'const is checked per call (k31)' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, fixed => 'x', three => '3', yes => 'true' }, $S ) ], [],
  '... and compares like enum: number as text, boolean as text' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, three => 4 }, $S ) ], ['$.three: erlaubt ist 3'], '... a number' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, yes => JSON::MaybeXS::false() }, $S ) ], ['$.yes: erlaubt ist true'], '... a boolean' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, iban => 'DE12', num => 3, pick => 'a' }, $S ) ], [],
  'type list: a string, an integer (k48)' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, iban => undef, num => JSON::MaybeXS::true(), pick => undef }, $S ) ], [],
  '... null, a boolean, null in enum' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, iban => [], num => 'x' }, $S ) ],
  [ '$.iban: erwartet string oder null', '$.num: erwartet integer oder boolean' ], '... none fits: all types named, in order' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, iban => 'de12' }, $S ) ], ['$.iban: passt nicht zu ^[A-Z]{2}'],
  '... the other keys still hold for a fitting type' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, pick2 => undef }, $S ) ], ['$.pick2: erlaubt sind a'],
  '... a null not listed in enum does not pass (JSON Schema)' );
is_deeply( [ schema_errors( { name => 'ab', count => 1, pick => 'b' }, $S ) ], ['$.pick: erlaubt sind a, null'],
  '... a null in enum is shown as null' );
is_deeply( [ schema_errors( { anything => 1 }, undef ) ], [], 'no schema: nothing to check' );

done_testing;
