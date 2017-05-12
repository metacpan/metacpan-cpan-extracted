# -*- perl -*-

# Copyright (c) 2006 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+dprof @ tcp4me.com>
# Created: 2006-Mar-11 22:16 (EST)
# Function: code profiler
#
# $Id: DProfLB.pm,v 1.3 2006/05/27 17:39:48 jaw Exp jaw $

package Devel::DProfLB;
# use strict; - does not play well with the debugger
our $VERSION = '0.01';

=head1 NAME

Devel::DProfLB - tell me why my perl program runs so slowly

=head1 SYNOPSIS

    perl -d:DProfLB program.pl
    dprofpp

=head1 DESCRIPTION

The Devel::DProfLB package is a Perl code profiler.

It is intended to produce output similar to, and
compatible with, Devel::DProf, but be 'Less Bad'.

This will collect information on the execution time of a Perl
script and of the subs in that script.  This information
can be used to determine which subroutines are using the
most time and which subroutines are being called most
often.  This information can also be used to create an
execution graph of the script, showing subroutine
relationships.

To profile a Perl script run the perl interpreter with the
-d debugging switch.  The profiler uses the debugging
hooks.  So to profile script test.pl the following command
should be used:

    perl5 -d:DProfLB test.pl

When the script terminates the profiler will dump the profile information to
a file called tmon.out.  A tool like dprofpp can be used
to interpret the information which is in that profile.
The following command will print the top 15 subroutines
which used the most time:

    dprofpp

To print an execution graph of the subroutines in the
script use the following command:

    dprofpp -T

Consult the dprofpp manpage for other options.

=head1 ENVIRONMENT

=over 4

=item C<PERL_DPROF_OUT_FILE_NAME>

Filename to save profile data to, default is F<tmon.out>

=back

=head1 BUGS

Valid profiling data is not saved until the application
terminates and runs this modules END{} block. Applications
which cause END{} blocks not to run (such as call _exit
or exec) will leave a corrupt and/or incomplete temporary data file.

On most systems, the timing data recorded by this profiler has
a granularity of 0.01 second. This may or may not be precise
enough for your application.

If the program being profiled contains subroutines which do
not return in a normal manner (such as by throwing an exception),
the timing data is estimated and may be attributed incorrectly.

Et cetera.

=head1 SECURITY ISSUES

The standard dprofpp program blindly C<eval>s portions
of the tmon.out datafile.

=head1 SEE ALSO

    Devel::Profile
    Devel::DProf
    dprofpp
    Yellowstone National Park
    
=head1 AUTHOR

    Jeff Weisberg - http://www.tcp4me.com/
    
=cut
    ;

package DB;

use POSIX 'times',	# different than the builtin times
    'sysconf', '_SC_CLK_TCK';

my @prof_stack = ();	# call stack, to account for subs that haven't returned
my $realtime_adj;	# because it overflows an int32
my $hz;			# clock ticks per second
my $prof_pid;		# process id of process being profiled
my @overhead;		# calibration overhead
my $tmpfile;		# temporary data file
my $monfile    = $ENV{PERL_DPROF_OUT_FILE_NAME} || 'tmon.out';
my $NCALOOP    = 1000;
my $calibrated = 0;
our $sub;

sub DB {}

BEGIN {

    $prof_pid = $$;
    $tmpfile  = "tmon$$.out";
    open(PROF, ">$tmpfile") || die "cannot open $tmpfile: $!\n";
    
    # calculate hertz
    eval { $hz = sysconf( _SC_CLK_TCK ) };
    unless( $hz ){
	# if unavailable, estimate
	my($st) = times();
	sleep 1;
	my($et) = times();
	$hz = $et - $st;
    }
    
    ($realtime_adj) = times();

}
END {

    # original process only, if we fork()
    return unless $$ == $prof_pid;
    
    my($rt, $ut, $st) = prof_times();

    # generate data for any unfinished subs 
    if( @prof_stack ){
	print PROF "# the following did not return, due to program termination\n";
	for my $asx (reverse @prof_stack){
	    print PROF "- $ut $st $rt $asx\n";
	}
    }
    
    close PROF;

    # reopen data, add headers, output new file
    open(TMP, $tmpfile)     || warn "cannot open $tmpfile: $!\n";
    open(PROF, ">$monfile") || warn "cannot open $monfile: $!\n";
    
    # output header
    print PROF "#fOrTyTwO\n";
    # this portion of the header is blindly evaled by dprofpp
    # any valid perl may be placed here
    # print PR0F "`echo pwned, rm -rf /`;\n"; # Yikes!
    # print PROF 'warn "SECURITY WARNING: this version of $0 may be unsafe. upgrade?\n";', "\n";
    print PROF "\$hz=$hz;\n\$XS_VERSION='DProfLB-$Devel::DProfLB::VERSION';\n";
    print PROF "# All timing values are given in HZ\n";
    print PROF "\$over_utime=$overhead[1]; \$over_stime=$overhead[2]; \$over_rtime=$overhead[0];\n";
    print PROF "\$over_tests=$NCALOOP;\n";    
    print PROF "\$rrun_utime=$ut; \$rrun_stime=$st; \$rrun_rtime=$rt;\n";
    print PROF "PART2\n";

    # remove calibration artifacts
    while(<TMP>){ last if /^\#CALIBRATED/ }
    # copy the rest
    while(<TMP>){ print PROF }
	
    close TMP;
    close PROF;
    unlink $tmpfile;
    $prof_pid = undef;
}

sub prof_times {
    my @t = times;

    # NB: ^T * HZ > MAX_INT32
    # => force positive
    $t[0] -= $realtime_adj;
    @t;
}

sub sub {

    my($rt, $ut, $st) = prof_times();
    
    my $sx = $sub;
    if( ref $sx ){
	my @c = caller;
	# was 0, now 1
	# nb: @c = (pkg, file, line, ...)
	$sx = "<anon>:$c[1]:$c[2]";
    }

    # do not corrupt data on fork()
    my $noprof = $$ != $prof_pid;
    if( $noprof ){
	close PROF;
    }
    
    print PROF "+ $ut $st $rt $sx\n" unless $noprof;
    
    push @prof_stack, $sx;
    my $ss = @prof_stack;
    
    my( $wa, $r, @r );
    $wa = wantarray;
    if( $wa ){
	@r = &$sub;
    }elsif( defined $wa ){
	$r = &$sub;
    }else{
	&$sub;
    }

    ($rt, $ut, $st) = prof_times();
    
    if( $ss < @prof_stack ){
	# we took an exception - account for aborted subs

	while( $ss < @prof_stack ){
	    my $asx = pop @prof_stack;
	    next if $noprof;
	    print PROF "# $asx did not return normally\n";
	    print PROF "- $ut $st $rt $asx\n";
	}
    }
    
    pop @prof_stack;
    print PROF "- $ut $st $rt $sx\n" unless $noprof;

    if( $wa ){
	@r;
    }else{
	$r;
    }
}

# calculate (estimate) profiler overhead
package Devel::DProfLB;
use strict;
my @st = DB::prof_times();
sub __db_calibrate_adj {
    my $x = shift;
}
for my $i (1..$NCALOOP){
    __db_calibrate_adj();
}
my @et = DB::prof_times();
for my $i (0..2){ $overhead[$i] = $et[$i] - $st[$i] }
print DB::PROF "#CALIBRATED\n";

1;
