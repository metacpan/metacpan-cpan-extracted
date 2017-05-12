#!perl -w

use strict;
use Test::More tests => 40;

eval <<'CODE';
#line 8 in_eval.t

BEGIN{ require MRO::Compat if $] < 5.010 }
my @tags;
{
	package A;
	use parent qw(Method::Cumulative);

	sub new{ bless {}, shift }

	sub foo{
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}

	sub bar{
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}

	package B;
	use parent -norequire => qw(A);

	sub foo :CUMULATIVE{
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}

	package C;
	use parent -norequire => qw(A);

	sub foo :CUMULATIVE{
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}

	package D;
	use parent -norequire => qw(C B);
	use mro 'c3';

	sub foo :CUMULATIVE{
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		my($self, $x) = @_;
		push @tags, $x.__PACKAGE__;
	}
}

for my $i(1 .. 5){
	@tags = ();
	B->foo('!');
	is_deeply \@tags, [qw(!B !A)], 'B->foo (derived first)';
	@tags = ();
	B->new->foo('?');
	is_deeply \@tags, [qw(?B ?A)];

	@tags = ();
	B->bar('!');
	is_deeply \@tags, [qw(!A !B)], 'B->bar (base first)';
	@tags = ();
	B->new->bar('?');
	is_deeply \@tags, [qw(?A ?B)];

	@tags = ();
	D->foo('!');
	is_deeply \@tags, [qw(!D !C !B !A)], 'D->foo (derived first)';
	@tags = ();
	D->new->foo('?');
	is_deeply \@tags, [qw(?D ?C ?B ?A)];

	@tags = ();
	D->bar('!');
	is_deeply \@tags, [qw(!A !B !C !D)], 'D->bar (base first)';
	@tags = ();
	D->new->bar('?');
	is_deeply \@tags, [qw(?A ?B ?C ?D)];

	if($i == 2){
		mro::method_changed_in('D');
	}
	elsif($i == 4){
		mro::method_changed_in('A');
	}
}
CODE
