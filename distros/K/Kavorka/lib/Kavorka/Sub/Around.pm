use 5.014;
use strict;
use warnings;

package Kavorka::Sub::Around;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo;
with 'Kavorka::MethodModifier';

sub default_invocant
{
	my $self = shift;
	return (
		'Kavorka::Parameter'->new(
			name      => '$next',
			traits    => { invocant => 1 },
		),
		'Kavorka::Parameter'->new(
			name      => '$self',
			traits    => { invocant => 1 },
		),
	);
}

sub method_modifier { 'around' }

around inject_prelude => sub
{
	my $next = shift;
	my $self = shift;
	return join '' => (
		'*{^NEXT} = \\$_[0];',
		$self->$next(@_),
	);
};

1;
