#!perl -w

use strict;
use Test::More tests => 24;

sub XXX{
	require Data::Dumper;
	diag(Data::Dumper::Dumper(@_));
}

BEGIN{
	package InsideOut;
	use Hash::FieldHash qw(:all);

	fieldhash my %foo, 'foo';
	fieldhash my %bar, 'bar';

	sub new{
		my $class = shift;
		my $obj = bless do{ \my $o }, $class;
		return from_hash($obj, @_);
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

	isa_ok $x, 'InsideOut';
	isa_ok $y, 'InsideOut';

	$x->foo(42);
	is $x->foo, 42 or XXX(InsideOut->registry);
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

	is_deeply $x->to_hash, { foo => 'x.foo', bar => 'x.bar' };
	is_deeply $y->to_hash, { foo => 'y.foo', bar => 'y.bar' };
}

{
	my $x = InsideOut->new(foo => 42, bar => 52);
	my $y = InsideOut->new(foo => 10, bar => 20);

	is_deeply $x->to_hash, { foo => 42, bar => 52 } or XXX($x->dump);
	is_deeply $y->to_hash, { foo => 10, bar => 20 } or XXX($x->dump);
}


is_deeply $registry, [{}, {}];


eval{
	InsideOut->new([]);
};
like $@, qr/must be a HASH reference/;

eval{
	InsideOut->new(1, 2, 3);
};
like $@, qr/Odd number of parameters/;

eval{
	InsideOut->new(xxx => 42);
};
like $@, qr/No such field "xxx"/;

eval{
	InsideOut->new({xxx => 42});
};
like $@, qr/No such field "xxx"/;

eval{
	InsideOut->foo;
};
like $@, qr/The foo\(\) method must be called as an instance method/;

eval{
	Hash::FieldHash::from_hash([]);
};

ok $@;

eval{
	Hash::FieldHash::to_hash([]);
};
ok $@;

is_deeply $registry, [{}, {}];
