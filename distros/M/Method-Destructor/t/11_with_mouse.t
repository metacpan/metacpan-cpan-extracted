#!perl -w

use strict;
use constant HAS_MOUSE => eval{ require Mouse; Mouse->VERSION(0.16) };

use Test::More HAS_MOUSE ? (tests => 12) : (skip_all => 'require Mouse (0.16)');

use constant VERBOSE => !!$ENV{TEST_VERBOSE};

my @tags;

BEGIN{
	package M;
	use Mouse;
	use Method::Destructor;

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package M_immutable;
	use Mouse;
	use Method::Destructor;

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}
	__PACKAGE__->meta->make_immutable(inline_destructor => 1);

	package M_immutable_no_inline_destructor;
	use Mouse;
	use Method::Destructor;

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}
	__PACKAGE__->meta->make_immutable(inline_destructor => 0);

	package M_derived;
	use Mouse;

	extends 'M';

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package M_immutable_derived;
	use Mouse;

	extends 'M_immutable';

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}
	__PACKAGE__->meta->make_immutable(inline_destructor => 1);

	package M_immutable_no_inline_destructor_derived;
	use Mouse;

	extends 'M_immutable_no_inline_destructor';

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}
	__PACKAGE__->meta->make_immutable(inline_destructor => 0);
}

for(1 .. 2){
	@tags = ();
	M->new();
	is_deeply \@tags, [qw(M)];

	@tags = ();
	M_immutable->new();
	is_deeply \@tags, [qw(M_immutable)];

	@tags = ();
	M_immutable_no_inline_destructor->new();
	is_deeply \@tags, [qw(M_immutable_no_inline_destructor)];
}

for(1 .. 2){
	@tags = ();
	M_derived->new();
	is_deeply \@tags, [qw(M_derived M)];

	@tags = ();
	M_immutable_derived->new();
	is_deeply \@tags, [qw(M_immutable_derived M_immutable)];

	@tags = ();
	M_immutable_no_inline_destructor_derived->new();
	is_deeply \@tags, [qw(M_immutable_no_inline_destructor_derived M_immutable_no_inline_destructor)];
}


if(VERBOSE){
	require Devel::Peek;

	diag 'M';
	diag Devel::Peek::CvGV( M->can('DESTROY') );

	diag 'M_immutable';
	diag Devel::Peek::CvGV( M_immutable->can('DESTROY') );

	diag 'M_immutable_no_inline_destructor';
	diag Devel::Peek::CvGV( M_immutable_no_inline_destructor->can('DESTROY') );

	diag 'M_derived';
	diag Devel::Peek::CvGV( M_derived->can('DESTROY') );

	diag 'M_immutable_derived';
	diag Devel::Peek::CvGV( M_immutable_derived->can('DESTROY') );

	diag 'M_immutable_no_inline_destructor_derived';
	diag Devel::Peek::CvGV( M_immutable_no_inline_destructor_derived->can('DESTROY') );

}