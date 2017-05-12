#!perl -T

use warnings;
use strict;
use Test::More tests => 20;
use Homer;

# let's create a prototype
my $person = Homer->new(
	say_hi => sub { "Hi, my name is ".$_[0]->first_name.' '.$_[0]->last_name.', '.$_[0]->catch_phrase }
);

ok($person, 'received person object');
ok($person->can('say_hi'), 'person object can say hi');

# now let's create a real person
my $homer = $person->extend(
	first_name => 'Homer',
	last_name => 'Simpson',
	catch_phrase => "D'Oh!!",
	say_something_else => sub { "Kids, you tried your best and you failed miserably. The lesson is, never try." }
);

ok($homer, 'received homer object');
ok($homer->can('catch_phrase'), 'homer object has catch_phrase accessor');
is($homer->catch_phrase, "D'Oh!!", 'homer object has catch_phrase attribute');
is($homer->say_hi, 'Hi, my name is Homer Simpson, D\'Oh!!', 'method on homer object called ok');

# now let's extend homer
my $bart = $homer->extend(
	first_name => 'Bart',
	catch_phrase => 'Ay Caramba!!',
	add_numbers => sub {
		my ($self, $one, $two) = @_;

		return ($one - 1) + ($two + 2);
	},
	say_something_else => sub { "My father once said: ".shift->prot->say_something_else }
);

ok($bart, 'received bart object');
ok($bart->can('catch_phrase'), 'bart object has catch_phrase accessor');
is($bart->catch_phrase, 'Ay Caramba!!', 'bart object has catch phrase attribute');
is($bart->say_hi, 'Hi, my name is Bart Simpson, Ay Caramba!!', 'method on bart object called ok');
ok($bart->can('add_numbers'), 'bart can add numbers');
is($bart->add_numbers(2, 2), 5, 'bart adds numbers correctly (well, not really)');
ok(!$homer->can('add_numbers'), 'homer can\'t add numbers');

# can we access prototypes?
is($bart->prot->first_name, 'Homer', 'bart\'s prototype is Homer');

# now let's check some setters
$homer->first_name('Homer Drunk');
is($homer->first_name, 'Homer Drunk', 'homer\'s first name changed ok');
is($bart->catch_phrase('Eat My Shorts'), 'Eat My Shorts', 'bart\'s catch phrase changed ok');

is($bart->say_something_else, "My father once said: Kids, you tried your best and you failed miserably. The lesson is, never try.", 'calling method on prototype works');

# let's see if we can add methods to an existing object
$homer->add_method('jump' => sub { "no way man" });
ok($homer->can('jump'), 'homer can jump, maybe');

# can bart also jump now?
ok($bart->can('jump'), 'bart can jump too');
is($bart->jump, 'no way man', 'bart doesn\'t want to jump');

done_testing();
