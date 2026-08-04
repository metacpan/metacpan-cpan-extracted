use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

my $r = V({ type => 'number', minimum => 0, maximum => 10 });
ok( $r->is_valid(J('0')),  'min inclusive');
ok( $r->is_valid(J('10')), 'max inclusive');
ok(!$r->is_valid(J('-1')), 'below min');
ok(!$r->is_valid(J('11')), 'above max');

my $x = V({ exclusiveMinimum => 0, exclusiveMaximum => 5 });
ok(!$x->is_valid(J('0')),   'exclusive min rejects boundary');
ok( $x->is_valid(J('0.1')), 'exclusive min ok above');
ok(!$x->is_valid(J('5')),   'exclusive max rejects boundary');

my $m = V({ multipleOf => 3 });
ok( $m->is_valid(J('9')),  '9 is multiple of 3');
ok(!$m->is_valid(J('10')), '10 is not');

my $mf = V({ multipleOf => 0.5 });
ok( $mf->is_valid(J('1.5')), '1.5 is multiple of 0.5');
ok(!$mf->is_valid(J('1.2')), '1.2 is not');

done_testing;
