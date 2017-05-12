package My::Example::Role::Katniss;

use strict;
use warnings;

# this class should never be loaded as it's not required!
die 'BOOM';

## no critic(ControlStructures::ProhibitUnreachableCode)
1;
