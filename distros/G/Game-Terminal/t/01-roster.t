#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal;

my @rows = Game::Terminal::games();
is scalar @rows, 23, 'twenty-three rows';

my (%seen, @names);
for my $row (@rows) {
	subtest $row->{key} => sub {
		plan tests => 10;
		like $row->{key}, qr/^[a-z0-9]+$/, 'the key is lowercase letters and digits';
		ok !$seen{$row->{key}}++, 'and unique';
		like $row->{module}, qr/^(?:Game|Term)::\w+$/, 'the module is a Game:: or Term:: name';
		like $row->{class}, qr/^(?:Game|Term)::\w+(?:::Terminal)?$/, 'and so is the class';
		ok length $row->{blurb}, 'there is a blurb';
		like $row->{family}, qr/^(?:board|card|tile|puzzle|arcade)$/, 'the family is one of five';
		like $row->{players}, qr/^\d(?:-\d)?$/, 'players is a number or a range';
		is ref $row->{args}, 'ARRAY', 'args is a list';
		is ref $row->{aliases}, 'ARRAY', 'aliases is a list';
		is ref $row->{flags}, 'HASH', 'flags is a hash';
	};
	push @names, $row->{key}, @{$row->{aliases}};
}

my %dup;
$dup{$_}++ for @names;
is_deeply [ grep { $dup{$_} > 1 } sort keys %dup ], [], 'no key or alias names two games';

is_deeply [ Game::Terminal::names() ], [ map { $_->{key} } @rows ], 'names are the keys in order';
is_deeply [ sort(Game::Terminal::names()) ], [ Game::Terminal::names() ], 'and the keys are sorted';

my ($schnapsen) = grep { $_->{key} eq 'schnapsen' } @rows;
my ($sixtysix) = grep { $_->{key} eq 'sixtysix' } @rows;
is $schnapsen->{class}, $sixtysix->{class}, 'schnapsen and sixtysix share a class';
is_deeply $schnapsen->{args}, ['--variant', 'schnapsen'], 'schnapsen carries its variant';
is_deeply $sixtysix->{args}, ['--variant', 'sixtysix'], 'and so does sixtysix';

my ($maze) = grep { $_->{key} eq 'maze' } @rows;
is_deeply $maze->{flags}, {}, 'maze has no flags to translate';
is $maze->{class}, 'Term::Maze', 'and its class is Term::Maze itself';

done_testing;
