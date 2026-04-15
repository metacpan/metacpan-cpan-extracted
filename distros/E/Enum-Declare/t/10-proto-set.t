use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require Object::Proto }
		or plan skip_all => 'Object::Proto not installed';
}

use Enum::Declare;
use Object::Proto;

enum Colour :Type { Red, Green, Blue }

enumSet ColourSet :Type :Colour;
enumSet WarmColours :Type :Colour { Red }

object 'Palette',
	'name:Str:required',
	'colours:ColourSet:required';

ColourSet->add(Red, Blue);

subtest 'typed slot accepts bare enum value in set' => sub {
	my $p = Palette->new(name => 'test', colours => Red);
	is($p->colours, Red, 'slot stores bare enum value');
};

subtest 'typed slot accepts another value in set' => sub {
	my $p = Palette->new(name => 'blue', colours => Blue);
	is($p->colours, Blue, 'Blue accepted — in ColourSet');
};

subtest 'typed slot rejects value not in set' => sub {
	eval { Palette->new(name => 'bad', colours => Green) };
	like($@, qr/colours/, 'Green rejected — not in ColourSet');
};

object 'WarmPalette',
	'name:Str:required',
	'colour:WarmColours:required';

subtest 'predefined set accepts member value' => sub {
	my $p = WarmPalette->new(name => 'warm', colour => Red);
	is($p->colour, Red, 'Red accepted — in WarmColours');
};

subtest 'predefined set rejects non-member' => sub {
	eval { WarmPalette->new(name => 'cold', colour => Green) };
	like($@, qr/colour/, 'Green rejected — not in WarmColours');

	eval { WarmPalette->new(name => 'cold', colour => Blue) };
	like($@, qr/colour/, 'Blue rejected — not in WarmColours');
};

subtest 'typed slot rejects Set object' => sub {
	my $set = Enum::Declare::Set->new(
		meta => Colour, name => 'tmp', values => [Red],
	);
	eval { Palette->new(name => 'set-obj', colours => $set) };
	like($@, qr/colours/, 'Set object rejected for ColourSet slot');
};

enum Perm :Type :Flags { Read, Write, Execute }

enumSet PermSet :Type :Perm;
PermSet->add(Read, Execute);

object 'FileEntry',
	'path:Str:required',
	'colour:ColourSet',
	'perm:PermSet';

subtest 'multiple set types in one object' => sub {
	my $f = FileEntry->new(
		path   => '/tmp/test',
		colour => Red,
		perm   => Read,
	);
	is($f->colour, Red,  'colour slot holds Red');
	is($f->perm,   Read, 'perm slot holds Read');
};

subtest 'cross-type rejection' => sub {
	eval { FileEntry->new(path => '/tmp', perm => Red) };
	like($@, qr/perm/, 'Red rejected for PermSet slot');

	eval { FileEntry->new(path => '/tmp', colour => Read) };
	like($@, qr/colour/, 'Read rejected for ColourSet slot');
};

subtest 'adding to singleton expands allowed values' => sub {
	# Green is currently not in ColourSet — rejected above
	ColourSet->add(Green);
	my $p = Palette->new(name => 'expanded', colours => Green);
	is($p->colours, Green, 'Green now accepted after add');

	# Clean up for subsequent tests
	ColourSet->remove(Green);
};

subtest 'removing from singleton restricts allowed values' => sub {
	ColourSet->remove(Blue);
	eval { Palette->new(name => 'shrunk', colours => Blue) };
	like($@, qr/colours/, 'Blue rejected after removal from ColourSet');

	# Restore
	ColourSet->add(Blue);
};

subtest 'invalid enum value rejected' => sub {
	eval { Palette->new(name => 'bad', colours => 999) };
	like($@, qr/colours/, 'non-enum value 999 rejected');
};

done_testing;
