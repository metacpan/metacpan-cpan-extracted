#!perl -w

use strict;
use Test::More tests => 3;

use MRO::Compat;

my @tags;

BEGIN{
	package A;
	use Method::Destructor;

	sub new{ bless {}, shift }

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package B;
	use parent -norequire => qw(A);

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package C;
	use parent -norequire => qw(A);

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package D;
	use mro 'c3';
	use parent -norequire => qw(C B);

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}
}


@tags = ();
D->new();
is_deeply \@tags, [qw(D C B A)], 'D' or diag "[@tags]";


#foreach my $c(qw(A B C D)){
#	diag "pkg_gen($c) -> ", mro::get_pkg_gen($c), "\n";
#}

undef *B::DEMOLISH;
delete $C::{DEMOLISH};

mro::method_changed_in('B');
mro::method_changed_in('C');

@tags = ();
D->new();
is_deeply \@tags, [qw(D A)], 'method changed in B and C' or diag "[@tags]";

*B::DEMOLISH = sub{ push @tags, 'B' };
mro::method_changed_in('B');

@tags = ();
D->new();
is_deeply \@tags, [qw(D B A)], 'method changed in B' or diag "[@tags]";
