package Devel::GDB::Reflect::MessageMethod;

# Based on http://perldesignpatterns.com/?AnonymousSubroutineObjects

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(anon);

sub new
{
	my $type = shift;
	return $type->new(@_) if ref $type eq __PACKAGE__;
	my $ref = shift; ref $ref eq 'CODE' or die;
	bless $ref, $type;
}

sub AUTOLOAD
{
	my $me = shift;
	(my $method = our $AUTOLOAD) =~ s/.*:://;
	return undef if $method eq 'DESTROY';
	return wantarray ? ($me->($method, @_)) : scalar $me->($method, @_);
}

sub anon
{
    my $sub = shift;

	return new Devel::GDB::Reflect::MessageMethod sub
	{
		my $arg = shift;
		($sub->{$arg} || sub { die "Unknown request: $arg()" })->(@_);
	};
}

1;
