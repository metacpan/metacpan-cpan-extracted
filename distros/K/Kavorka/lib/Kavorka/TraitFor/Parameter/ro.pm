use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Parameter::ro;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;

around _injection_assignment => sub
{
	my $next = shift;
	my $self = shift;
	my ($sig, $var, $val) = @_;
	
	my $str = $self->$next(@_);
	
	$str .= sprintf(
		'&Internals::SvREADONLY(\\%s, 1);',
		$var,
	);
	
	return $str;
};

after sanity_check => sub
{
	my $self = shift;
	
	my $traits = $self->traits;
	my $name   = $self->name;
	
	croak("Parameter $name cannot be rw and ro") if $traits->{rw};
};

1;
