package HPCD::SGE::JobGroup;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
# use File::Path qw(make_path remove_tree);
# use DateTime;
# use MooseX::Types::Path::Class qw(Dir File);
use HPCD::SGE::DRMAACheck;

use Moose::Role;

with 'HPCI::JobGroup' => { theDriver => 'HPCD::SGE' }, @HPCD::SGE::DRMAACheck::JobGroupWith;

after 'BUILD' => sub {
    my $self = shift;
    $self->info(
        "SGE job submission will use: "
        . ($HPCD::SGE::DRMAACheck::using_DRMAA ? 'DRMAA' : 'qsub') . "\n"
    );
};

1;
