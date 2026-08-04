use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }

my $s = V({ type => 'string' });
ok( $s->is_valid(J('"hi"')), 'string ok');
ok(!$s->is_valid(J('5')),    'number not string');
ok(!$s->is_valid(J('null')), 'null not string');

my $mt = V({ type => ['string','null'] });
ok( $mt->is_valid(J('"x"')),  'union string');
ok( $mt->is_valid(J('null')), 'union null');
ok(!$mt->is_valid(J('5')),    'union rejects number');

my $int = V({ type => 'integer' });
ok( $int->is_valid(J('5')),   'integer 5');
ok(!$int->is_valid(J('5.5')), 'integer rejects 5.5');
my $num = V({ type => 'number' });
ok( $num->is_valid(J('5')),   'number accepts integer');
ok( $num->is_valid(J('5.5')), 'number accepts 5.5');

my $b = V({ type => 'boolean' });
ok( $b->is_valid(J('true')),  'boolean true');
ok(!$b->is_valid(J('1')),     'integer 1 is not boolean');

my $e = V({ enum => [1, 2, 'three'] });
ok( $e->is_valid(J('2')),       'enum number');
ok( $e->is_valid(J('"three"')), 'enum string');
ok(!$e->is_valid(J('4')),       'enum miss');

my $c = V({ const => { a => 1 } });
ok( $c->is_valid(J('{"a":1}')), 'const object match');
ok(!$c->is_valid(J('{"a":2}')), 'const object mismatch');

done_testing;
