#!perl -w

use strict;

use constant HAS_LEAKTRACE => eval q{use Test::LeakTrace 0.07; 1};
use Test::More HAS_LEAKTRACE ? (tests => 5) : (skip_all => 'require Test::LeakTrace');

use Hash::FieldHash qw(:all);

my %hash;
{
	package A;
	use Hash::FieldHash qw(:all);

	fieldhash %hash, 'foo';

	sub new{
		my $class = shift;
		my $obj = bless do{ \my $o }, $class;
		return Hash::FieldHash::from_hash($obj, {@_});
	}
}


no_leaks_ok{
	my $x = A->new();
	my $y = A->new();

	$hash{$x} = 'Hello';
	$hash{$y} = 0.5;
	$hash{$y}++ for 1 .. 10;
};

is_deeply \%hash, {};

no_leaks_ok{
	my $x = A->new(foo => 10);
	my $y = A->new(foo => 100);

	$x->foo($x->foo+1);
	$y->foo($y->foo+1);
};
is_deeply \%hash, {};


no_leaks_ok{
	fieldhash my %h;

	for(1){
		my $o = [42];
		my $p = [3.14];
		$h{$o} = 100;
		$h{$p} = 200;
	}
};

