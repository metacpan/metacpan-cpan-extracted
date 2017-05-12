#!/usr/bin/perl
use strict;
use warnings;
use Linux::Info;
use Linux::Info::DiskUsage;
$Linux::Info::DiskUsage::DF_CMD = 'df -hP';

my $sys = Linux::Info->new( diskusage => 1 );
my $stat = $sys->get;

# $stat->diskusage returns the first level keys of the
# statistic hash as a array. The first level keys are
# the disk names.
foreach my $disk ( $stat->diskusage ) {    # Gimme the disk names

    print "Statistics for disk $disk:\n";

    # $stat->diskusage($disk) returns the seconds level keys of
    # the statistics. The second level keys are the statistic keys
    # for the passed disk.
    foreach my $key ( sort $stat->diskusage($disk) )
    {    # Gimme the statistic keys

        # $stat->diskusage($disk, $key) returns the value for the passed
        # disk and key.
        printf "   %-20s %s\n", $key, $stat->diskusage( $disk, $key );

    }

}

