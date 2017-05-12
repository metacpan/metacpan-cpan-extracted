#!/usr/bin/perl

use Heap::Fibonacci;
use Heap::Fibonacci::Fast;
use Heap::Binary;
use Heap::Binomial;
use Heap::Elem::Num(NumElem);
use Heap::Simple::XS;

use Benchmark qw/cmpthese/;

sub COUNT()	{ 100 }

cmpthese(-3, {
	xs_fib	=> sub {
		my $z = Heap::Fibonacci::Fast->new();
		$z->key_insert(int(rand() * 10000), $_) for (1..COUNT);
		$z->extract_top() for (1..COUNT);
		undef $z;
	},
	perl_fib	=> sub {
		my $z = Heap::Fibonacci->new();
		$z->add(NumElem(int(rand() * 10000))) for (1..COUNT);
		$z->extract_top() for (1..COUNT);
		undef $z;
	},
	perl_bino	=> sub {
		my $z = Heap::Binomial->new();
		$z->add(NumElem(int(rand() * 10000))) for (1..COUNT);
		$z->extract_top() for (1..COUNT);
		undef $z;
	},
	perl_bin	=> sub {
		my $z = Heap::Binary->new();
		$z->add(NumElem(int(rand() * 10000))) for (1..COUNT);
		$z->extract_top() for (1..COUNT);
		undef $z;
	},
	xs_simple	=> sub {
		my $z = new Heap::Simple::XS(elements => "Any");
		$z->key_insert(int(rand() * 10000), $_) for (1..COUNT);
		$z->extract_top() for (1..COUNT);
		undef $z;
	},
});

