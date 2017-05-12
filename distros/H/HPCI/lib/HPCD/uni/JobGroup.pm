package HPCD::uni::JobGroup;

### INCLUDES ######################################################################################

# safe Perl
use warnings;
use strict;
use Carp;
# use File::Path qw(make_path remove_tree);
# use MooseX::Types::Path::Class qw(Dir File);

use Moose::Role;

with 'HPCI::JobGroup' => { theDriver => 'HPCD::uni' };

1;
