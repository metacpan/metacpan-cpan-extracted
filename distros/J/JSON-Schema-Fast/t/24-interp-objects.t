use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

my $o = V({ type => 'object', properties => { a => { type => 'integer' } }, required => ['a'] });
ok( $o->is_valid(J('{"a":1}')),      'property + required ok');
ok(!$o->is_valid(J('{}')),           'missing required');
ok(!$o->is_valid(J('{"a":"x"}')),    'property type mismatch');

my $af = V({ properties => { a => {} }, additionalProperties => 0 });
ok( $af->is_valid(J('{"a":1}')),       'no additional');
ok(!$af->is_valid(J('{"a":1,"b":2}')), 'additionalProperties:false rejects b');

my $as = V({ properties => { a => {} }, additionalProperties => { type => 'string' } });
ok( $as->is_valid(J('{"a":1,"b":"x"}')), 'additional matches schema');
ok(!$as->is_valid(J('{"a":1,"b":2}')),   'additional violates schema');

my $pp = V({ patternProperties => { '^s_' => { type => 'string' } } });
ok( $pp->is_valid(J('{"s_x":"y"}')), 'patternProperties ok');
ok(!$pp->is_valid(J('{"s_x":1}')),   'patternProperties type mismatch');

my $pn = V({ propertyNames => { minLength => 3 } });
ok( $pn->is_valid(J('{"abc":1}')), 'propertyNames ok');
ok(!$pn->is_valid(J('{"ab":1}')),  'propertyNames too short');

my $mp = V({ minProperties => 1, maxProperties => 2 });
ok(!$mp->is_valid(J('{}')),                 'below minProperties');
ok( $mp->is_valid(J('{"a":1}')),            'minProperties ok');
ok(!$mp->is_valid(J('{"a":1,"b":2,"c":3}')),'above maxProperties');

my $dr = V({ dependentRequired => { a => ['b'] } });
ok( $dr->is_valid(J('{"a":1,"b":2}')), 'dependentRequired satisfied');
ok(!$dr->is_valid(J('{"a":1}')),       'dependentRequired missing b');
ok( $dr->is_valid(J('{"c":1}')),       'dependentRequired inactive when a absent');

done_testing;
