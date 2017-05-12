#!perl -w

use strict;
use Test::More tests => 1;

use MRO::Compat;

my @tags;

BEGIN{
	package A;
	use Method::Destructor -optional;

	sub new{ bless {}, shift }

	sub DEMOLISH{
		::fail __PACKAGE__;
	}

	package B;
	use Method::Destructor -optional;
	use parent -norequire => qw(A);

	sub DEMOLISH{
		::fail __PACKAGE__;
	}

	package C;
	use Method::Destructor -optional;
	use parent -norequire => qw(A);

	sub DEMOLISH{
		::fail __PACKAGE__;
	}

	package D;
	use Method::Destructor -optional;
	use mro 'c3';
	use parent -norequire => qw(C B);

	sub DEMOLISH{
		::fail __PACKAGE__;
	}
}

our @global;
for(1 .. 2){
	push @global, A->new();
	push @global, B->new();
	push @global, C->new();
	push @global, D->new();
}

pass 'optional destructors must be skipped';
