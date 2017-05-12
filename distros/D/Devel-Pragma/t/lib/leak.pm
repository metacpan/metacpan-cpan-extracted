package leak;

use strict;
use warnings;

use vars qw($HH);

BEGIN { $HH = \%^H }

sub hh { $HH }

1;
