package Clean::Down;

use strict;
use warnings;

use Clean qw/not_okay/, { clean => 1 };

sub not { not_okay() }

sub okay { 1 }

1;
