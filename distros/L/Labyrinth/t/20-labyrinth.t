#!/usr/bin/perl -w
use strict;

use Test::More tests => 3;

{
	use Labyrinth;
	my $labyrinth = Labyrinth->new();
	isa_ok($labyrinth, 'Labyrinth');
	eval { $labyrinth->run() };
	like($@,qr/Cannot read settings file/);

    eval { $labyrinth->run('bogus.file') };
	like($@,qr/Cannot read settings file/);
}
