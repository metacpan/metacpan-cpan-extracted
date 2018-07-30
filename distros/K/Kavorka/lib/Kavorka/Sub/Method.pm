use 5.014;
use strict;
use warnings;

use Kavorka::Parameter ();

package Kavorka::Sub::Method;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo;
with 'Kavorka::Sub';

sub invocation_style { 'method' }

sub default_attributes
{
	return (
		['method'],
	);
}

sub default_invocant
{
	my $self = shift;
	return (
		'Kavorka::Parameter'->new(
			as_string => '$self:',
			name      => '$self',
			traits    => { invocant => 1 },
		),
	);
}

1;
