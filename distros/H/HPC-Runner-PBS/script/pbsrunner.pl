#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  testlogging.pl
#
#        USAGE:  ./testlogging.pl
#
#  DESCRIPTION:
#      VERSION:  1.0
#      CREATED:  22/12/14 10:15:02
#     REVISION:  ---
#===============================================================================

package Main;

use Carp::Always;
use Moose;
use namespace::autoclean;
extends 'HPC::Runner::PBS';

Main->new_with_options->run;

__PACKAGE__->meta->make_immutable;
1;
