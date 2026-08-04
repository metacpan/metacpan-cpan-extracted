use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

my $all = V({ allOf => [ { type => 'integer' }, { minimum => 0 } ] });
ok( $all->is_valid(J('5')),   'allOf both');
ok(!$all->is_valid(J('-1')),  'allOf fails minimum');
ok(!$all->is_valid(J('"x"')), 'allOf fails type');

my $any = V({ anyOf => [ { type => 'integer' }, { type => 'string' } ] });
ok( $any->is_valid(J('5')),    'anyOf integer');
ok( $any->is_valid(J('"x"')),  'anyOf string');
ok(!$any->is_valid(J('true')), 'anyOf neither');

my $one = V({ oneOf => [ { multipleOf => 2 }, { multipleOf => 3 } ] });
ok( $one->is_valid(J('2')), 'oneOf exactly first');
ok( $one->is_valid(J('3')), 'oneOf exactly second');
ok(!$one->is_valid(J('6')), 'oneOf both -> fail');
ok(!$one->is_valid(J('5')), 'oneOf neither -> fail');

my $not = V({ not => { type => 'string' } });
ok( $not->is_valid(J('5')),   'not string ok');
ok(!$not->is_valid(J('"x"')), 'not string fails on string');

my $ite = V({ if => { type => 'integer' }, then => { minimum => 0 }, else => { type => 'string' } });
ok( $ite->is_valid(J('5')),    'if/then satisfied');
ok(!$ite->is_valid(J('-1')),   'if/then violated');
ok( $ite->is_valid(J('"x"')),  'else branch satisfied');
ok(!$ite->is_valid(J('true')), 'else branch violated');

done_testing;
