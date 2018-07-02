use 5.014;
use strict;
use warnings;

package Kavorka::Sub::Override;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.038';

use Moo;
with 'Kavorka::MethodModifier';

sub method_modifier { 'override' }

1;
