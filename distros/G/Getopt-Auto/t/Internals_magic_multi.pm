#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  02-internals_magic_multi.pm
#
#  DESCRIPTION:  Test the construction of internal data structures
#                which result from the "magic" mode of Getopt::Auto
#                when running multiple files
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.8
#      CREATED:  07/06/2009 03:27:58 PM PDT
#===============================================================================

use strict;
use warnings;

use Test::Output;

package Internals_magic_multi;
use Getopt::Auto;

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireCheckedSyscalls)

sub internals_magic_multi_pm {
    print "did Internals_magic_multi_pm\n";
    return;
}

1;
