package Clean;

use strict;
use warnings;

use base qw/Import::Export/;

our %EX = (
	not_okay => [qw/all/],
);

sub not_okay { 0 }

1;
