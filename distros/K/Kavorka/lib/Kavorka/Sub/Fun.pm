use 5.014;
use strict;
use warnings;

package Kavorka::Sub::Fun;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo;
with 'Kavorka::Sub';

sub invocation_style { 'fun' }

sub forward_declare
{
	my $self = shift;
	my $name = $self->qualified_name;
	eval sprintf("sub %s %s;", $name, $self->inject_prototype) if defined $name;
}

1;
