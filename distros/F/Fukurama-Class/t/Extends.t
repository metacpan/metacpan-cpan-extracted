#!perl -T
use Test::More tests => 19;
use lib qw(./ ./t);
use strict;
use warnings;

my $warnings;
BEGIN {
	close(STDERR);
	open(STDERR, '>', \$warnings);
}
{
	package ParentA;
	sub test {}
	
	package ParentB;
	sub test {}
	
	package Child;
	use Fukurama::Class::Extends('ParentA');
	use Fukurama::Class::Extends('ParentB');
	
}
like($warnings, qr/sub 'test' is defined twice/, 'multi-inheritation warnings');
{
	package MyParent;
	sub new { return 1 }
}
{
	package MyExtendsTest;
	our @ISA;
	BEGIN {
		main::is(scalar(@__PACKAGE__::ISA), 0, 'empty isa');
	}
	use Fukurama::Class::Extends('MyParent');
	main::is(scalar(@MyExtendsTest::ISA), 1, 'filled isa');
	main::is($MyExtendsTest::ISA[0], 'MyParent', 'isa content');
	main::is(__PACKAGE__->new(), 1, 'method inheritance');
	main::is(__PACKAGE__->SUPER::new(), 1, 'method inheritance via SUPER');
}
{
	package MyFailure;
	eval("use Fukurama::Class::Extends('MyNotExistingParent');");
	main::like($@, qr/is empty/, 'non existing parent');
}
{
	package FieldsParent;
	use fields qw(one two);
	sub new {
		my $class = $_[0];
		my FieldsParent $self = fields::new($class);
		$self->{one} = 1;
		$self->{two} = 2;
		return $self;
	}
}
{
	package FieldsChild;
	use Fukurama::Class::Extends('FieldsParent');
	use fields qw(three);
	sub get {
		my __PACKAGE__ $self = $_[0];
		$self->{three} = 'a';
		$self->{two} = 'b';
		$self->{one} = 'c';
		return 1;
	}
}
{
	my FieldsParent $fp = FieldsParent->new();
	is($fp->{one}, 1, 'first field');
	is($fp->{two}, 2, 'second field');
	eval("\$fp->{three}");
	like($@, qr/No such [A-Za-z\-]*? field "three"/, 'disallowed third field');
	
	my FieldsChild $fc = FieldsChild->new();
	is($fc->{one}, 1, 'first field');
	is($fc->{two}, 2, 'second field');
	is($fc->{three}, undef, 'third field');
	is($fc->get(), 1, 'get method');
	is($fc->{one}, 'c', 'first field');
	is($fc->{two}, 'b', 'second field');
	is($fc->{three}, 'a', 'third field');
}
{
	package UseParentDirect;
	use Fukurama::Class::Extends('Extends::LoadedPackage');
	
	sub get {
		my $class = $_[0];
		return $class->SUPER::get() + 1;
	}
	
	main::is(__PACKAGE__->get(), 2, 'use parent via SUPER');
	main::is(Extends::LoadedPackage->get(), 1, 'use parent direct');
}
