package HPCD::SGE::Group;

### INCLUDES ##############################################################################

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;
use namespace::autoclean;

use HPCD::SGE::Stage;


with
	'HPCI::Group'    => { theDriver => 'HPCD::SGE' },
	'HPCD::SGE::JobGroup',
	HPCI::get_extra_roles('SGE', 'group');

1;

