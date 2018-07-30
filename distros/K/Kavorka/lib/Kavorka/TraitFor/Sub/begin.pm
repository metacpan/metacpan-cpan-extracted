use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Sub::begin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;
use namespace::sweep;

around _build__tmp_name => sub
{
	my $next = shift;
	my $self = shift;
	
	return $self->$next(@_)
		unless defined $self->invocation_style;
	
	$self->qualified_name or $self->$next(@_);
};

1;
