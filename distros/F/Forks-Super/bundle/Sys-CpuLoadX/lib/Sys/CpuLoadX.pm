package Sys::CpuLoadX;

# Copyright (c) 1999-2002 Clinton Wong. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself. 
# (This copyright notice is from the original Sys::CpuLoad package)

use strict;
use warnings;

require Exporter;
require DynaLoader;
require AutoLoader;

our @ISA = qw(Exporter AutoLoader DynaLoader);

our @EXPORT = qw();
our @EXPORT_OK = qw(load get_cpu_load);
our $VERSION = '0.04';
our $WIN32_INTERVAL = 1000; # milliseconds to run to get CPU usage

{
    local $@;
    eval { bootstrap Sys::CpuLoadX $VERSION };
    if ($@) {
	warn "bootstrap Sys::CpuLoadX call failed.\n";
    }
}

use IO::File;

my $cache = 'unknown';

sub load {

    # handle bsd getloadavg().  Read the README about why it is freebsd/openbsd.
    if ($cache eq 'getloadavg()' 
	or lc $^O eq 'freebsd'
	or lc $^O eq 'openbsd' ) {

	$cache = 'getloadavg()';
	return xs_getbsdload()
    }

    # handle linux proc filesystem
    if ($cache eq 'unknown' or $cache eq 'linux') {
	my $fh = new IO::File('/proc/loadavg', 'r');
	if (defined $fh) {
	    my $line = <$fh>;
	    $fh->close();
	    if ($line =~ /^(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/) {
		$cache = 'linux';
		return ($1, $2, $3);
	    }              # if we can parse /proc/loadavg contents
	}                  # if we could load /proc/loadavg 
    }                      # if linux or not cached
    
    # last resort...

    $cache = 'uptimepipe';
    local %ENV = %ENV;
    $ENV{'LC_NUMERIC'}='POSIX';    # ensure that decimal separator is a dot

    my $uptime_cmd = _configExternalProgram('uptime');
    if ($uptime_cmd) {
	my $uptime_result = qx($uptime_cmd 2> /dev/null);
	$uptime_result =~ s/\s+$//;
	my @uptime = (split /\s*,?\s+/, $uptime_result)[-3 .. -1];
	if (@uptime == 3) {
	    return @uptime;
	}
    }
    return (undef, undef, undef);
}

sub get_cpu_load {

    if ( (lc $^O eq 'freebsd' || lc $^O eq 'openbsd')
	 && defined &xs_getbsdload) {

	my @bsdload = xs_getbsdload();
	_debug("load from bsdload: @bsdload");
	if (@bsdload >= 3) {
	    return sprintf '%.2f', $bsdload[0];
	}
    }

    if (defined &xs_getCpuUsage) {
	my $cpuUsage = xs_getCpuUsage($WIN32_INTERVAL);
	_debug("load from xs_getCpuUsage: $cpuUsage");
	return $cpuUsage > 0 ? $cpuUsage * 0.01 : "0.00";
    }

    if (-r '/proc/loadavg' && $^O ne 'cygwin') {
	open my $loadavg_fh, '<', '/proc/loadavg';
	my $line = <$loadavg_fh>;
	close $loadavg_fh;
	_debug("load from /proc/loadavg: $line");
	if ($line =~ /^(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/) {
	    return $1;
	}
    }

    my $uptime_cmd = _configExternalProgram('uptime');
    if ($uptime_cmd && $^O ne 'cygwin') {
	my $uptime_result = qx($uptime_cmd 2> /dev/null);
	$uptime_result =~ s/\s+$//;
	_debug("load from 'uptime': $uptime_result");
	my @uptime = (split /\s*,?\s+/, $uptime_result)[-3 .. -1];
	if (@uptime == 3) {
	    return $uptime[0];
	}
    }

    _debug("no load result: returning -1");
    return -1.0;
}

############################################################################# 

our %PROGRAM = ();
our @PATH = ();

sub _configExternalProgram {
    my $program = shift;
    return $PROGRAM{$program} if defined $PROGRAM{$program};
    if (-x $program) {
	_debug("Program $program is available in $program");
	return $PROGRAM{$program} = $program;
    }

    my $which = qx(which $program 2>/dev/null);
    $which =~ s/\s+$//;
    if ($which) {
	_debug("Program $program is available in $which");
	return $PROGRAM{$program} = $which;
    }

    # poor man's which
    if (@PATH == 0) {
	@PATH = split /:/, $ENV{PATH};
	push @PATH, split /;/, $ENV{PATH};
	push @PATH, ".";
	push @PATH, "/sbin", "/usr/sbin";
    }
    foreach my $dir (@PATH) {
	if (-x "$dir/$program") {
	    _debug("Program $program is available in $dir/$program");
	    $PROGRAM{$program} = "$dir/$program";
	}
    }
    return $PROGRAM{$program} = 0;
}

our $DEBUG = $ENV{DEBUG} || 0;
sub _debug {
    if ($DEBUG) {
	print STDERR @_,"\n";
    }
}

1;




=head1 NAME

Sys::CpuLoadX - a module to retrieve system load averages.

=head1 SYNOPSIS

    use Sys::CpuLoadX;
    print '1 min, 5 min, 15 min load average: ',
         join(',', Sys::CpuLoadX::load()), "\n";
    print "Best estimate of current load = ", Sys::CpuLoadX::get_cpu_load(), "\n";

=head1 FUNCTIONS

=over 4

=item C<@loads = Sys::CpuLoadX::load()>

Retrieves the 1 minute, 5 minute, and 15 minute load average
of a machine.

=item C<$load = Sys::CpuLoadX::get_cpu_load()>

Returns the best estimate of the current system load.
For Unix like systems, this is the 1 minute load average like
the one returned from C<uptime(1)>, and measures the average
number of active processes that are competing for CPU time. 
For Windows machines (include Cygwin), it is computed 
from a one second sample of the CPU load, and is a value
between 0 and 1 representing the fraction of CPU utilization
during that second.

This function will return -1 if it cannot determine a
suitable method for finding the CPU load on the system.

=back

=head1 AUTHOR

Original Sys::CpuLoad module by Clinton Wong, 
E<lt> http://search.cpan.org/search?mode=author&query=CLINTDW E<gt>

Original Win32::SystemInfo::CpuUsage by Jing Kang,
E<lt> kxj@hotmail.com E<gt>.

Updates by Marty O'Brien, E<lt> mob@cpan.org E<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 1999-2002, 2010 Clinton Wong and Marty O'Brien.
All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut





=cut
