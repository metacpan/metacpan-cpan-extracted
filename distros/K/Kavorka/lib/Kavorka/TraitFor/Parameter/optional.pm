use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Parameter::optional;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;

around _injection_default_value => sub
{
	my $next = shift;
	my $self = shift;
	@_ = ('undef') unless @_;
	$self->$next(@_);
};


after sanity_check => sub
{
	my $self = shift;
	my $name = $self->name;
	croak("Bad parameter $name") if $self->invocant;
};

1;
