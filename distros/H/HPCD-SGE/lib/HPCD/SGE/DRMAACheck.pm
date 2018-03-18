package HPCD::SGE::DRMAACheck;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Module::Load::Conditional qw(can_load);
# use Schedule::DRMAAc qw( :all );

our $using_DRMAA;
our @JobGroupWith;
our @RunWith;

BEGIN {
    if (!$ENV{HPCI_NO_DRMAA}
		    and $using_DRMAA = can_load( modules => { 'Schedule::DRMAAc' => undef })) {
        push @RunWith, "HPCD::SGE::DRMAARun";
        push @JobGroupWith, "HPCD::SGE::DRMAAJobGroup";
    }
}

1;
