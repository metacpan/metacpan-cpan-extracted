#!perl -w

use strict;
use Test::More tests => 10;

use Hash::FieldHash qw(:all);

BEGIN{
	package InsideOut;
	use Hash::FieldHash qw(fieldhashes);

	fieldhashes \my(%foo, %bar);

	sub new{
		bless {}, shift;
	}

	sub foo{
		my $self = shift;
		$foo{$self} = shift if @_;
		return $foo{$self};
	}
	sub bar{
		my $self = shift;
		$bar{$self} = shift if @_;
		return $bar{$self};
	}

	sub registry{
		[\(%foo, %bar)];
	}
}
my $registry = InsideOut->registry();

is_deeply $registry, [{}, {}];

{
	my $x = InsideOut->new();
	my $y = InsideOut->new();

	$x->foo(42);
	is $x->foo, 42;
	is $x->bar, undef;
	is $y->foo, undef;
	is $y->bar, undef;

	$x->foo('x.foo');
	$x->bar('x.bar');
	$y->foo('y.foo');
	$y->bar('y.bar');
	is $x->foo, 'x.foo';
	is $x->bar, 'x.bar';
	is $y->foo, 'y.foo';
	is $y->bar, 'y.bar';
}
#use Data::Dumper; diag(Dumper $registry);

is_deeply $registry, [{}, {}];

