use 5.014;
use strict;
use warnings;

use Kavorka::Parameter ();
use Types::Standard ();

package Kavorka::Sub::ClassMethod;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo;
extends 'Kavorka::Sub::Method';

sub default_invocant
{
	my $self = shift;
	return (
		'Kavorka::Parameter'->new(
			name      => '$class',
			traits    => { invocant => 1 },
			type      => Types::Standard::Str,
		),
	);
}

1;
