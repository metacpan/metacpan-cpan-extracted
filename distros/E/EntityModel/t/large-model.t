use strict;
use warnings;
use Test::More skip_all => 'pointless test, skip for now';
use Test::Deep;
use EntityModel::Storage;
use EntityModel;
use Async::MergePoint;

# Set up an EntityModel from a Perl hash
BEGIN {
	my $start = Time::HiRes::time;
	my $model = new_ok('EntityModel');
	ok($model->load_from(
	Perl	=> {
 "name" => "mymodel",
 "entity" => [ {
  "name" => "thing",
  "primary" => "idthing",
  "field" => [
   { "name" => "idthing", "type" => "int" },
   { "name" => "name", "type" => "varchar" }
  ] }, {
  "name" => "other",
  "primary" => "idother",
  "field" => [
   { "name" => "idother", "type" => "int" },
   { "name" => "idthing", "type" => "int", "refer" => [
     { table => 'thing', field => 'idthing', delete => 'cascade', update => 'cascade' }
   ] },
   { "name" => "extra", "type" => "varchar" }
  ] }
 ] }), 'load model');
	ok($model->add_storage(Perl => {}), 'add Perl backend storage');
	ok($model->add_support(Perl => {}), 'add Perl class structure');
	note sprintf("Took %2.3fms to set up model", (Time::HiRes::time - $start) * 1000.0);
}

# Try creating something with a task-on-commit
my $other;
ok(my $thing = Entity::Thing->create({
	name	=> 'EntityEditor'
})->then(sub {
	my $thing = shift;
	$other = Entity::Other->create({
		thing	=> $thing,
		extra	=> 'entitymodel.com'
	});
}), 'create with commit callback using ->then');

# Verify that we created okay
isa_ok($thing, 'Entity::Thing');
isa_ok($other, 'Entity::Other');
ok($thing->id, 'have ID for thing');
ok($other->id, 'have ID for other');
is($other->thing->id, $thing->id, 'ref matches');
Entity::Thing->new($thing->id)->then(sub {
	my $t = shift;
	is($t->id, $thing->id, 'Thing id matches after instantiation');
});
Entity::Other->new($other->id)->then(sub {
	my $o = shift;
	is($o->id, $other->id, 'Other id matches after instantiation');
	is($o->thing->id, $thing->id, 'ref matches');
});

# Now try some updates
$thing->name('renamed')->then(sub {
	my $thing = shift;
	is($thing->name, 'renamed', 'have renamed successfully');
	is($other->thing->name, 'renamed', 'object linked through ref was also updated');
});

$thing->other->each(sub {
	my $other = shift;
	$other->remove;
});

# 1:N refs
my $populate = Async::MergePoint->new;
my $check = Async::MergePoint->new;
foreach my $idx (0..8) {
	$populate->needs($idx);
	$check->needs($idx);
	note "queue $idx for creation";
	Entity::Other->create({
		thing	=> $thing,
		extra	=> $idx
	})->then(sub {
		$populate->done($idx);
		pass("mark $idx as created");
	});
}

# Add a callback for when we've finished population
$populate->close(
	on_finished	=> sub {
		# Check all the items in the returned list
		$thing->other->each(sub {
			my $other = shift;
			$check->done($other->extra);
			pass("mark " . $other->extra . " as found");
		});
	}
);

# And the callback to pick up when we've reported existence of all expected items
$check->close(
	on_finished	=> sub {
		pass('was able to find all items');
	}
);

# Now try some of the array-based access to the 1:N mappings
$thing->other->grep(sub { $_[0]->extra & 1 })->each(sub {
	my $item = shift;
	ok($item->extra & 1, 'item is odd');
});
$thing->other->grep(sub { !($_[0]->extra & 1) })->each(sub {
	my $item = shift;
	ok($item->extra % 2 == 0, 'item is not odd');
});
$thing->other->grep(sub { $_[0]->extra == 3 })->first(sub {
	my $item = shift;
	is($item->extra, 3, 'find item 3');
})->count(sub {
	my $count = shift;
	is($count, 1, 'have correct count');
});
$thing->other->first(sub {
	my $item = shift;
})->count(sub {
	my $count = shift;
	is($count, 9, 'have correct count');
});


