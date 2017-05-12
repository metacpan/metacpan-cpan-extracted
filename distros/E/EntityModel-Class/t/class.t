use strict;
use warnings;
use 5.10.0;
use Test::More;

package EMClass::Test::Sub;
use EntityModel::Class {
	name => { type => 'string' },
};

package EMClass::Test;
use EntityModel::Class {
	string => { type => 'string' },
	number => { type => 'data' },
	array => { type => 'array', subclass => 'string' },
	hash => { type => 'hash', subclass => 'string' },
	subtype => { type => 'EMClass::Test::Sub' },
	watcher => { type => 'hash', scope => 'private', watch => { array => '' } }
};

package main;
use Test::More tests => 22;
use EntityModel::Class;

my $em = new_ok('EMClass::Test');
can_ok($em, 'string');
ok($em->string('test'), 'set string');
is($em->string, 'test', 'string matches');
can_ok($em, 'number');
is($em->number(23), $em, 'set number');
is($em->number, 23, 'number matches');
can_ok($em, 'array');
isa_ok($em->array, 'EntityModel::Array');
ok($em->array->push('test'), 'push value');
is($em->array->join(','), 'test', 'list is correct');
ok($em->array->push('second'), 'push another value');
is($em->array->join(','), 'test,second', '2-element list is correct');
can_ok($em, 'hash');
isa_ok($em->hash, 'EntityModel::Hash');
ok($em->hash->{test} = 1, 'set key');
is($em->hash->get('test'), 1, 'key is correct');
ok(!$em->watcher->get('watchedval'), 'no watched val to start with');
ok($em->array->push('watchedval'), 'push value');
ok($em->watcher->get('watchedval'), 'now have watched val');
ok($em->array->pop, 'pop value');
ok(!$em->watcher->get('watchedval'), 'no longer have watched val');

