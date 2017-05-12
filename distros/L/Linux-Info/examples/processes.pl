#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Linux::Info;
use Linux::Info::Processes;

# the default value for the following keys are pages:
#   size, resident, share, trs, drs, lrs, dtp
#
# set PAGES_TO_BYTES to the pagesize of your system if
# you want bytes instead of pages
$Linux::Info::Processes::PAGES_TO_BYTES = 4096;

my $sys = Linux::Info->new( processes => 1 );
sleep 1;
my $stat = $sys->get();

print Dumper( $stat->{processes} );
