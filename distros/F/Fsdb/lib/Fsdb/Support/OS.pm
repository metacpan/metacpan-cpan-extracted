#!/usr/bin/perl -w

#
# Fsdb::Support::OS.pm
# Copyright (C) 2013 by John Heidemann <johnh@ficus.cs.ucla.edu>
# $Id: d0eb3c7879eb9a5375ee0c177598e2663e364792 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Support::OS;


=head1 NAME

Fsdb::Support::OS - operating-system-specific support functions

=head1 SYNOPSIS

    use Fsdb::Support::OS;

=cut
#'


use Exporter 'import';
@EXPORT = qw();
@EXPORT_OK = qw($max_parallelism $parallelism_available);
$VERSION = 1.0;

use Carp qw(croak);

# Track parallelism here.
# it's shared across all instances of dbmerge, but that's a feature.
our $parallelism_available : shared = undef;

my $max_parallelism_cache = undef;

=head2 max_parallelism

    $cores = Fsdb::Support::OS::max_parallism()

Finds the number of cores in the current computer,
or some other plausible value of parallelism for CPU-intensive tasks.

=cut
sub max_parallelism() {
    return $max_parallelism_cache
	if (defined($max_parallelism_cache));

    # If no clue what os, so pick a plausible value for 2013.
    my $max_parallelism = 4;

    #
    # Poke around in os-specific ways to see if we can do better than
    # the default.
    #
    if (-f "/proc/cpuinfo") {
	# Linux
	open(INFO, "/proc/cpuinfo") or die "exists, but cannot open /proc/cpuinfo\n";
	while (<INFO>) {
	    if (/^processor\s+:\s+(\d+)/) {
		$max_parallelism = $1 + 1;  # add one because cpus number from 0
	    };
	};
	close INFO;
    } elsif (-f "/var/run/dmesg.boot") {
	# FreeBSD:
	#
	# Ted Faber tells me:
	# $ grep -i CPU /var/run/dmesg.boot/var/run/dmesg.boot | grep Detected
	# FreeBSD/SMP: Multiprocessor System Detected: 4 CPUs
	open(INFO, "/var/run/dmesg.boot") or die "exists, but cannot open /var/run/dmesg.boot\n";
	while (<INFO>) {
	    if (/Multiprocessor.*\s(\d+)\sCPU/) {
		$max_parallelism = $1;
		last;
	    };
	};
    };

    return $max_parallelism_cache = $max_parallelism;
}

1;
