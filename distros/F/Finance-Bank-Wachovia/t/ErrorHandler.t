use strict;
use Test::More tests => 5;

use_ok('Finance::Bank::Wachovia::ErrorHandler');

package Foo;
our @ISA = ('Finance::Bank::Wachovia::ErrorHandler');

sub new { 
	my($class, $arg) = @_;
	return Foo->Error("new crapped out") unless $arg;
	return bless [], $class;
};

sub crap_out {
	my $self = shift;
	return $self->Error( 'crap_out crapped out' );	
}

sub AUTOLOAD{
	my $self = shift;
	our $AUTOLOAD;
	return if $AUTOLOAD eq 'Error';
	return $self->Error( "Not a valid attribute" );	
}

package main;
my $foo;
$foo = Foo->new();
is( Foo->ErrStr(), 'new crapped out' );
ok( ! defined $foo, 'Class error works' );
$foo = Foo->new(1);
ok( ! defined $foo->crap_out, 'Object error returns undef');
is( $foo->ErrStr(), 'crap_out crapped out', 'Error sets error string' );


