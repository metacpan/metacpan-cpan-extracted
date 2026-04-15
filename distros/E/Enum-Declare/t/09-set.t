use strict;
use warnings;
use Test::More;

use Enum::Declare;

enum Colour { Red, Green, Blue }

enum Direction :Str { North, South, East, West }

enum Perm :Flags { Read, Write, Execute }

enum Status { OK = 200, NotFound = 404, ServerError = 500 }

enumSet WarmColours :Colour { Red }
enumSet AllColours :Colour { Red, Green, Blue }
enumSet EmptyColour :Colour {}

enumSet ColourSet :Colour;
enumSet DirSet :Direction;
enumSet PermSet :Perm;
enumSet StatusSet :Status;

sub colour_set {
	my $s = ColourSet->clone;
	$s->add(@_) if @_;
	return $s;
}

sub dir_set {
	my $s = DirSet->clone;
	$s->add(@_) if @_;
	return $s;
}

sub perm_set {
	my $s = PermSet->clone;
	$s->add(@_) if @_;
	return $s;
}

sub status_set {
	my $s = StatusSet->clone;
	$s->add(@_) if @_;
	return $s;
}

subtest 'predefined constant set - WarmColours' => sub {
	ok(WarmColours->has(Red),    'WarmColours has Red');
	ok(!WarmColours->has(Green), 'WarmColours does not have Green');
	ok(!WarmColours->has(Blue),  'WarmColours does not have Blue');
	is(WarmColours->count, 1, 'count is 1');
	is_deeply([WarmColours->names], ['Red'], 'names');
};

subtest 'predefined constant set - AllColours' => sub {
	ok(AllColours->has(Red),   'has Red');
	ok(AllColours->has(Green), 'has Green');
	ok(AllColours->has(Blue),  'has Blue');
	is(AllColours->count, 3, 'count is 3');
};

subtest 'predefined constant set - empty' => sub {
	ok(!EmptyColour->has(Red), 'empty set has nothing');
	is(EmptyColour->count, 0, 'count is 0');
	ok(EmptyColour->is_empty, 'is_empty is true');
};

subtest 'frozen set rejects mutation' => sub {
	eval { WarmColours->add(Green) };
	like($@, qr/cannot modify a frozen set/, 'add on frozen dies');
	eval { WarmColours->remove(Red) };
	like($@, qr/cannot modify a frozen set/, 'remove on frozen dies');
	eval { WarmColours->toggle(Red) };
	like($@, qr/cannot modify a frozen set/, 'toggle on frozen dies');
};

subtest 'singleton - basic usage' => sub {
	my $set = colour_set(Red, Blue);
	ok($set->has(Red),    'has Red');
	ok(!$set->has(Green), 'does not have Green');
	ok($set->has(Blue),   'has Blue');
	is($set->count, 2, 'count is 2');
	is_deeply([sort $set->names], ['Blue', 'Red'], 'names');
};

subtest 'singleton - empty clone' => sub {
	my $set = colour_set();
	is($set->count, 0, 'empty set count');
	ok($set->is_empty, 'is_empty');
	ok(!$set, 'empty set is false in bool context');
};

subtest 'singleton - string enum' => sub {
	my $set = dir_set(North, East);
	ok($set->has(North), 'has North');
	ok($set->has(East),  'has East');
	ok(!$set->has(South), 'no South');
	is($set->count, 2, 'count');
};

subtest 'singleton - flags enum' => sub {
	my $set = perm_set(Read, Execute);
	ok($set->has(Read),    'has Read');
	ok(!$set->has(Write),  'no Write');
	ok($set->has(Execute), 'has Execute');
};

subtest 'singleton - explicit values' => sub {
	my $set = status_set(OK, ServerError);
	ok($set->has(OK),          'has OK (200)');
	ok(!$set->has(NotFound),   'no NotFound');
	ok($set->has(ServerError), 'has ServerError (500)');
};

subtest 'add/remove/toggle' => sub {
	my $set = colour_set(Red);
	$set->add(Green);
	ok($set->has(Green), 'add works');
	is($set->count, 2, 'count after add');

	$set->remove(Red);
	ok(!$set->has(Red), 'remove works');
	is($set->count, 1, 'count after remove');

	$set->toggle(Green);
	ok(!$set->has(Green), 'toggle off');
	$set->toggle(Blue);
	ok($set->has(Blue), 'toggle on');
};

subtest 'members and names in declaration order' => sub {
	my $set = colour_set(Blue, Red);
	is_deeply([$set->names], ['Red', 'Blue'], 'names in declaration order');
	is_deeply([$set->members], [Red, Blue], 'members in declaration order');
};

subtest 'union' => sub {
	my $a = colour_set(Red);
	my $b = colour_set(Green, Blue);
	my $u = $a->union($b);
	is($u->count, 3, 'union has all');
	ok(!$u->frozen, 'union result is mutable');
};

subtest 'intersection' => sub {
	my $a = colour_set(Red, Green);
	my $b = colour_set(Green, Blue);
	my $i = $a->intersection($b);
	is($i->count, 1, 'intersection count');
	ok($i->has(Green), 'intersection has Green');
};

subtest 'difference' => sub {
	my $a = colour_set(Red, Green, Blue);
	my $b = colour_set(Green);
	my $d = $a->difference($b);
	is($d->count, 2, 'difference count');
	ok($d->has(Red), 'has Red');
	ok(!$d->has(Green), 'no Green');
	ok($d->has(Blue), 'has Blue');
};

subtest 'symmetric_difference' => sub {
	my $a = colour_set(Red, Green);
	my $b = colour_set(Green, Blue);
	my $s = $a->symmetric_difference($b);
	is($s->count, 2, 'sym diff count');
	ok($s->has(Red), 'has Red');
	ok(!$s->has(Green), 'no Green');
	ok($s->has(Blue), 'has Blue');
};

subtest 'subset/superset' => sub {
	my $a = colour_set(Red);
	my $b = colour_set(Red, Green, Blue);
	ok($a->is_subset($b), 'a is subset of b');
	ok(!$b->is_subset($a), 'b is not subset of a');
	ok($b->is_superset($a), 'b is superset of a');
};

subtest 'disjoint' => sub {
	my $a = colour_set(Red);
	my $b = colour_set(Green, Blue);
	ok($a->is_disjoint($b), 'disjoint');
	$b->add(Red);
	ok(!$a->is_disjoint($b), 'not disjoint after overlap');
};

subtest 'equals' => sub {
	my $a = colour_set(Red, Blue);
	my $b = colour_set(Blue, Red);
	ok($a->equals($b), 'equals regardless of construction order');
	ok($a == $b, '== overload');
	my $c = colour_set(Red);
	ok(!($a == $c), '!= when different');
	ok($a != $c, '!= overload');
};

subtest 'clone' => sub {
	my $clone = WarmColours->clone;
	ok(!$clone->frozen, 'clone is mutable');
	ok($clone->has(Red), 'clone has same members');
	$clone->add(Green);
	ok($clone->has(Green), 'clone can be mutated');
	ok(!WarmColours->has(Green), 'original unchanged');
};

subtest 'stringify' => sub {
	my $set = colour_set(Red, Blue);
	like("$set", qr/ColourSet\(Red, Blue\)/, 'stringify');

	my $empty = colour_set();
	like("$empty", qr/ColourSet\(\)/, 'stringify empty');
};

subtest 'bool' => sub {
	my $set = colour_set(Red);
	ok($set, 'non-empty is true');
	my $empty = colour_set();
	ok(!$empty, 'empty is false');
};

subtest 'rejects invalid values' => sub {
	my $set = colour_set();
	eval { $set->add(999) };
	like($@, qr/Invalid enum value/, 'bad value on add');
};

subtest 'rejects mixing different enums' => sub {
	my $colours = colour_set(Red);
	my $dirs = dir_set(North);
	eval { $colours->union($dirs) };
	like($@, qr/different enums/, 'union rejects different enums');
};

done_testing;
