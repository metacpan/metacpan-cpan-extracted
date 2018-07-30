use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Sub::override;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;
use Types::Standard qw(Any);
use Carp qw(croak);
use namespace::sweep;

before install_sub => sub
{
	my $self = shift;
	
	croak("The 'override' trait cannot be applied to lexical methods")
		if $self->is_lexical;
	
	croak("The 'override' trait cannot be applied to anonymous methods")
		if $self->is_anonymous;
	
	croak("The 'override' trait may only be applied to methods")
		if $self->invocation_style ne 'method';
	
	my ($pkg, $name) = ($self->qualified_name =~ /^(.+)::(\w+)$/);
	return if $pkg->can($name);
	
	croak("Method '$name' does not exist in inheritance hierarchy; cannot override");
};

1;
