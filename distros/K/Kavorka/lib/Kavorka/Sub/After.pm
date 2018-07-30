use 5.014;
use strict;
use warnings;

package Kavorka::Sub::After;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo;
with 'Kavorka::MethodModifier';

sub method_modifier { 'after' }

1;
