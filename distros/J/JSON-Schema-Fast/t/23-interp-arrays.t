use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

my $it = V({ type => 'array', items => { type => 'integer' } });
ok( $it->is_valid(J('[1,2,3]')), 'items all integer');
ok(!$it->is_valid(J('[1,"x"]')), 'items reject string');

my $pf = V({ prefixItems => [ { type => 'integer' }, { type => 'string' } ] });
ok( $pf->is_valid(J('[1,"x"]')), 'prefixItems positional');
ok(!$pf->is_valid(J('[1,2]')),   'prefixItems second must be string');
ok( $pf->is_valid(J('[1]')),     'prefixItems only checks present positions');

my $mm = V({ minItems => 2, maxItems => 3 });
ok(!$mm->is_valid(J('[1]')),       'below minItems');
ok( $mm->is_valid(J('[1,2]')),     'minItems ok');
ok(!$mm->is_valid(J('[1,2,3,4]')), 'above maxItems');

my $uq = V({ uniqueItems => JSON::Schema::Fast->can('compile') ? \1 : 1 });
$uq = V({ uniqueItems => 1 });
ok( $uq->is_valid(J('[1,2,3]')),          'unique ok');
ok(!$uq->is_valid(J('[1,2,2]')),          'duplicate scalars');
ok(!$uq->is_valid(J('[{"a":1},{"a":1}]')),'duplicate objects');

my $ct = V({ contains => { type => 'integer' }, minContains => 2 });
ok( $ct->is_valid(J('["x",3,4]')), 'contains >= minContains');
ok(!$ct->is_valid(J('["x",3]')),   'contains below minContains');

done_testing;
