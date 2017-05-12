#!perl -w

use strict;
use Test::More tests => 24;

#use Hash::Util::FieldHash::Compat qw(fieldhash fieldhashes);
use Hash::FieldHash qw(:all);

fieldhash my %hash;
fieldhash our %ghash;

ok !scalar(%hash);

my $r = {};
$hash{$r} = 'r';
$ghash{$r} = 'g';

ok scalar(%hash);

is_deeply [values %hash],  ['r'];
is_deeply [values %ghash], ['g'];

{
	my $o = bless {foo => 'bar'};
	my $x = ['baz'];

	$hash{$o} = 10;

	is $hash{$o}, 10;

	$hash{$x} = 42;

	is $hash{$o}, 10;
	is $hash{$x}, 42;

	$ghash{$o} = 10;
	$ghash{$x} = 42;

	is_deeply [sort values %hash],  [sort('r', 10, 42)];
	is_deeply [sort values %ghash], [sort('g', 10, 42)];

	is_deeply $o, {foo => 'bar'};
	is_deeply $x, ['baz'];

	is ref($o), __PACKAGE__;
	is ref($x), 'ARRAY';
}

is_deeply [values %hash],  ['r'];
is_deeply [values %ghash], ['g'];

{
	my $o = bless {};

	$hash{$o} = 10;

	is $hash{$o}, 10;

	$hash{$o}++;

	is $hash{$o}, 11;
}

is_deeply [values %hash],  ['r'];
is_deeply [values %ghash], ['g'];

undef $r;

is_deeply \%hash,  {};
is_deeply \%ghash, {};

{
	my %hash = (foo => 'bar');
	fieldhash %hash;

	is_deeply \%hash, {};
}

eval{
	my %hash;
	foreach (1 .. 10){
		fieldhash %hash;
	}
};
is $@, '';

my $o = do{ fieldhash my %hash; bless \%hash };
is ref($o), __PACKAGE__;

#use Data::Dumper;
#print Dumper *{$Hash::FieldHash::{'::OBJECT_REGISTRY'}}{ARRAY};
