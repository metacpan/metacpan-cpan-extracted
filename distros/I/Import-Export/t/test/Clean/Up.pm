package Clean::Up;

use strict;
use warnings;

sub import {
	require Clean;
	Clean->import(qw/not_okay/, { clean => 'import', -caller => 'Clean::Up' });
}

sub not { not_okay() }

sub okay { 1 }

1;
