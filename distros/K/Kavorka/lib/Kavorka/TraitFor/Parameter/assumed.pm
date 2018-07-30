use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Parameter::assumed;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;

around _injection_conditional_type_check => sub { q() };

1;
