#!perl -w

use strict;
use Test::More tests => 8;

use constant VERBOSE => !!$ENV{TEST_VERBOSE};

sub XXX{
	require Data::Dumper;
	my $ddx = Data::Dumper->new(\@_);
	$ddx->Indent(1);
	$ddx->Sortkeys(1);
	diag($ddx->Dump);
}

BEGIN{
	package A;
	use Hash::FieldHash qw(:all);

	fieldhash my %foo, 'foo';
	fieldhash my %bar, 'bar';

	sub new{
		my $class = shift;
		my $obj = bless do{ \my $o }, $class;
		return Hash::FieldHash::from_hash($obj, @_);
	}

	sub dump{
		my($self, $fully_qualify) = @_;
		return $self->to_hash($fully_qualify ? -fully_qualify : undef);
	}

	package B;
	use Hash::FieldHash qw(:all);
	our @ISA = qw(A);

	fieldhash my %baz, 'baz';

	package C;
	use Hash::FieldHash qw(:all);
	our @ISA = qw(B);
}

{
	my $x = B->new('A::foo' => 10, 'A::bar' => 20, 'B::baz' => 30);

	is_deeply $x->dump,    { foo => 10, bar => 20, baz => 30 };
	is_deeply $x->dump(1), { 'A::foo' => 10, 'A::bar' => 20, 'B::baz' => 30 };
}

{
	my $x = C->new('A::foo' => 10, 'A::bar' => 20, 'B::baz' => 30);

	is_deeply $x->dump,    { foo => 10, bar => 20, baz => 30 };
	is_deeply $x->dump(1), { 'A::foo' => 10, 'A::bar' => 20, 'B::baz' => 30 };

	is_deeply $x->dump(0), C->new($x->dump(0))->dump(0);
	is_deeply $x->dump(0), C->new($x->dump(1))->dump(0);
	is_deeply $x->dump(1), C->new($x->dump(0))->dump(1);
	is_deeply $x->dump(1), C->new($x->dump(1))->dump(1);
}

if(VERBOSE){
	if(defined &Hash::FieldHash::_name_registry){
		XXX( Hash::FieldHash::_name_registry() );
	}
}
