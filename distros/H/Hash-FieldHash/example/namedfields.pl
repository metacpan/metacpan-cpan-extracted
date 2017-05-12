#!perl -w
use strict;

package MyClass;
use Hash::FieldHash qw(:all);

fieldhash my %foo => 'foo';

sub new{
	my $class = shift;
	my $self  = bless {}, $class;
	return from_hash($self, @_);
}

package MyDerivedClass;
use parent -norequire => 'MyClass';
use Hash::FieldHash qw(:all);

fieldhash my %bar => 'bar';

package main;

my $o = MyDerivedClass->new(foo => 10, bar => 20);
my $p = MyDerivedClass->new('MyClass::foo' => 10, 'MyDerivedClass::bar' => 20);

use Data::Dumper;
print Dumper($o->to_hash()); 
# $VAR1 = { foo => 10, bar => 20 }

print Dumper($o->to_hash(-fully_qualify));
# $VAR1 = { 'MyClass::foo' => 10, 'MyDerived::bar' => 20 }

