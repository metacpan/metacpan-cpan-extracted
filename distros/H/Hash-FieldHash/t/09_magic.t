#!perl -w

use strict;
use constant HUF => eval{ require Hash::Util::FieldHash };
use Test::More HUF ? (tests => 8) : (skip_all => 'require Hash::Util::FieldHash');

use Hash::FieldHash;

Hash::FieldHash::fieldhash       my %x;
Hash::Util::FieldHash::fieldhash my %y;


{
	my $o = [];

	$x{$o} = 100;
	$y{$o} = 200;

	is_deeply [values %x], [100];
	is_deeply [values %y], [200];

	is $x{$o}, 100;
	is $y{$o}, 200;

	$x{$o}++;
	$y{$o}++;

	is $x{$o}, 101;
	is $y{$o}, 201;
}

is_deeply \%x, {};
is_deeply \%y, {};
