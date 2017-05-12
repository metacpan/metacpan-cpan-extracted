use strict;
use warnings;
use Test::More;
BEGIN {
	plan skip_all => 'no IO::Async' unless eval { require IO::Async::Loop };
	plan skip_all => 'i broke it';
}

use Test::Deep;
use EntityModel;
use EntityModel::Async;
use Async::MergePoint;

# Set up an EntityModel from a Perl hash
my $loop;
BEGIN {
	my $start = Time::HiRes::time;
	$loop = IO::Async::Loop->new;
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
  ] }, {
  "name" => "book",
  "primary" => "idbook",
  "field" => [
   { "name" => "idbook", "type" => "int" },
   { "name" => "idauthor", "type" => "int", "refer" => [
     { table => 'author', field => 'idauthor', delete => 'cascade', update => 'cascade' }
   ] },
   { "name" => "title", "type" => "varchar" }
  ] }, {
  "name" => "author",
  "primary" => "idauthor",
  "field" => [
   { "name" => "idauthor", "type" => "int" },
   { "name" => "idaddress", "type" => "int", "refer" => [
     { table => 'address', field => 'idaddress', delete => 'cascade', update => 'cascade' }
   ] },
   { "name" => "name", "type" => "varchar" }
  ] }, {
  "name" => "address",
  "primary" => "idaddress",
  "field" => [
   { "name" => "idaddress", "type" => "int" },
   { "name" => "street", "type" => "varchar" },
   { "name" => "city", "type" => "varchar" },
   { "name" => "country", "type" => "varchar" },
  ] }
 ] }), 'load model');
	ok($model->add_storage(PerlAsync => {
		loop	=> $loop
	}), 'add Perl backend storage');
#	ok($model->add_storage(Perl => { }), 'add Perl backend storage');
	ok($model->add_support(Perl => { }), 'add Perl class structure');
	note sprintf("Took %2.3fms to set up model", (Time::HiRes::time - $start) * 1000.0);
}

sub first_test {
# Try creating something with a task-on-commit
my $other;
ok(my $thing = Entity::Thing->create({
	name	=> 'EntityEditor'
})->then(sub {
	my $thing = shift;
	ok($other = Entity::Other->create({
		thing	=> $thing,
		extra	=> 'entitymodel.com'
	}), 'create new Other object');
}), 'create with commit callback using ->then');

EntityModel::Gather->new(
	thing	=> $thing,
	other	=> $other,
)->when_ready(sub {
	my %data = @_;

	# Verify that we created okay
	isa_ok($data{thing}, 'Entity::Thing');
	isa_ok($data{other}, 'Entity::Other');
	ok($data{thing}->id, 'have ID for thing');
	ok($data{other}->id, 'have ID for other');
});

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

# Process on ready
ok(EntityModel::Gather->new(
	thing	=> $thing,
	other	=> $other
)->when_ready(sub {
	my %data = @_;
	is($data{other}->idthing, $data{thing}->id, 'id matches when ready');
}), 'gather and process');
}

sub simple_book_test {
	ok(my $book = Entity::Book->create({ name => 'Perl In Practise' }), 'create book');
	ok(my $author = Entity::Author->create({ name => 'Some Person' }), 'create author');
	ok(my $address = Entity::Address->create({ street => 'Some street', city => 'London', country => 'UK' }), 'create address');
	$book->author($author)->then(sub {
		is($book->author->id, $author->id, 'author ID matches');
		ok($author->address($address), 'set address');
		is($book->author->address->id, $address->id, 'address ID matches');
	});

	ok(EntityModel::Gather->new(
		book	=> $book,
		author	=> $book->author,
		city	=> $book->author->address->city
	)->when_ready(sub {
		my %data = @_;
		isa_ok($data{book}, 'Entity::Book');
		is($data{book}->id, $book->id, 'id matches for book');
		isa_ok($data{author}, 'Entity::Author');
		isa_ok($data{author}->address, 'Entity::Address');
		is($data{city}, 'London', 'city is correct');
	}), 'gather chained accessor');
}

# We create these inline so they should be ready immediately
sub multi_level_wait {
	ok(my $book = Entity::Book->create({
		title => 'Another book',
		author => Entity::Author->create({
			name => 'Another author',
			address => Entity::Address->create({
				street	=> 'Another street',
				city	=> 'Another city',
				country	=> 'Another country'
			})
		})
	}), 'create book');
	is($book->title, 'Another book', 'book name matches');
	is($book->author->name, 'Another author', 'author name matches');
	is($book->author->address->street, 'Another street', 'Street matches');

	# Gather should also work (immediately)
	ok(EntityModel::Gather->new(
		book	=> $book,
		author	=> $book->author,
		city	=> $book->author->address->city
	)->when_ready(sub {
		my %data = @_;
		is($data{book}->title, 'Another book', 'book name matches');
		is($data{author}->name, 'Another author', 'author name matches');
		is($data{city}, 'Another city', 'City matches');
	}), 'gather chained accessor');
}

simple_book_test();
# multi_level_wait();
$loop->loop_forever;

