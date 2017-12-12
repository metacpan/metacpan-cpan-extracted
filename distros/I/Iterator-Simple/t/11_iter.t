use Test::More tests => 14;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

#1-2 iarray($arrayref)
{
	ok(($itr = iarray [10,2,3,'foo',5]), 'iarray creation');
	my @res;
	while(<$itr>) {
		push @res, $_;
	}
	is_deeply \@res => [10,2,3,'foo',5], 'iarray result';
}

#3-4 iter($arrayref)
{
	ok(($itr = iter([10,'foo','bar','buz'])), 'arrayref iter creation');
	is_deeply list($itr) => [10, 'foo', 'bar', 'buz'], 'arrayref iter result';
}

#5-6 iter($iohandle)
{
	use IO::Handle;
	ok(($itr = iter(\*DATA)), 'GLOB iter creation');
	is_deeply list($itr) => ["foo\n", "bar\n", "10\n", "who\n"], 'GLOB iter result';
}

#7-8 iter($__iter__implemented_object)
{
	my $foo = Foo->new(1,2,'three',4,5);
	ok(($itr = iter($foo)), '__iter__ method iter creation');
	is_deeply list($itr) => ['1_', '2_', 'three_', '4_', '5_'], '__iter__ method iter creation';
}

#9-10 iter($<>overloaded_object)
{
	my $bar = Bar->new('bow-wow', 'oink', 'quack');
	ok(($itr = iter($bar)), '"<>" overload iter creation' );
	is_deeply list($itr) => ['bow-wow', 'oink', 'quack'], '"<>" overload iter creation';
}

#11-12 iter($code);
{
	my @array = ('a','b','c');
	my $foo = sub { shift @array; };
	ok(($itr = iter($foo)), 'code ref iter creation');
	is_deeply list($itr) => ['a', 'b', 'c'] , 'code ref iter result';
}

#13-14 iter()
{
	ok(($itr = eval{iter()}), 'empty iter creation');
	is_deeply list($itr) => [], 'empty iter result';
}

{
	package Foo;
	use Iterator::Simple qw(iterator);

	sub new {
		my $class = shift;
		bless [@_], $class;
	}

	sub __iter__ {
		my($self) = @_;
		my $idx =0;
		iterator {
			return unless exists $self->[$idx];
			return $self->[$idx++] . '_';
		}
	}
}

{
	package Bar;

	my $i = 0;
	use overload (
		'<>' => sub { my $s = shift; $s->{events}[$s->{pointer}++] }
	);
	sub new {
		my $class =shift;
		bless { events => [@_], pointer => 0 }, $class;
	}
}

__DATA__
foo
bar
10
who
