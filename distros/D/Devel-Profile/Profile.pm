# -*- perl -*-

# Copyright (c) 2002 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+profile @ tcp4me.com>
# Date: 2002-Jun-21 22:19 (EDT)
# Function: code profiler
#
# $Id: Profile.pm,v 1.22 2007/03/08 02:25:42 jaw Exp $

# Dost thou love life? Then do not squander time
#   -- Benjamin Franklin

# start as:
#   env PERL5DB='BEGIN{require "src/Profile.pm"}' perl -d program.pl
#   or: perl -d:Profile program.pl
# data gets saved in 'prof.out'

# motivation:
#   Devel::DProf appears to have issues. when it is used
#     9 times out of 10 it produces output that is unusable by dprofpp (even with -F)
#     the statistics are often obviously wrong
#     it causes crashage
# of course, this code isn't really any better....

=head1 NAME

Devel::Profile - tell me why my perl program runs so slowly

=head1 SYNOPSIS

    perl -d:Profile program.pl
    less prof.out

=head1 DESCRIPTION

The Devel::Profile package is a Perl code profiler.
This will collect information on the execution time of a Perl script and of the subs in that script.
This information can be used to determine which subroutines are using the most time and which
subroutines are being called most often.

To profile a Perl script, run the perl interpreter with the -d debugging switch.
The profiler uses the debugging hooks.
So to profile script test.pl the following command should be used:

	perl -d:Profile test.pl  

When the script terminates (or periodicly while running, see ENVIRONMENT) the profiler will dump
the profile information to a file called F<prof.out>. This file is human-readable, no
additional tool is required to read it.

Note: Statistics are kept per sub, not per line.

=head1 ENVIRONMENT

=over 4

=item C<PERL_PROFILE_SAVETIME>

How often to save profile data while running, in seconds, 0 to save only at exit.
The default is every 2 minutes.

=item C<PERL_PROFILE_FILENAME>

Filename to save profile data to, default is F<prof.out>

=item C<PERL_PROFILE_DONT_OTHER>

Time spent running code not in 'subs' (such as naked code in main) won\'t
get accounted for in the normal manner. By default, we account for this time
in the sub '<other>'. With this variable set, we leave it as 'missing' time.
This reduces the effective runtime of the program, and the calculated percentages.

=back

=cut
    ;
# more POD at end

package Devel::Profile;
$VERSION = "1.05";

package DB;
BEGIN {
    sub DB {}
    require Time::HiRes; Time::HiRes->import('time');
}

my $t0     = time();	# start time
my $tsav   = $t0;	# time of last save
my $tacc   = 0;		# total time accumulated
my $tacc0  = 0;		# total time accumulated at start (or reset)
my $call   = 0;		# total number of calls
my $except = 0;		# total number of exceptions handled (est)
my $saving = 0;		# save in progress
my $tprof_save = 0;	# time spent saving data
my %prof_calls = ();	# number of calls per sub
my %prof_times = ();	# total time per sub
my %prof_flags = ();	# flags
my @prof_stack = ();	# call stack, to account for subs that haven't returned
my $want_reset = 0;	# reset request pending
my $prof_pid   = $$;	# process id

my $TSAVE = defined($ENV{PERL_PROFILE_SAVETIME}) ? $ENV{PERL_PROFILE_SAVETIME} : 120; 
my $NCALOOP = 1000;

$SIG{USR2} = \&reset;

sub sub {

    my $ti = time();	# wall time at start
    # save first, keeps timing calculations simpler
    if( !$saving && $TSAVE && ($ti - $tsav) > $TSAVE ){
	save();
	$ti = time();	# update to account for save
    }
    
    my $st = $tacc;	# accum time at start
    my $sx = $sub;
    if( ref $sx ){
	my @c = caller;
	# was 0, now 1
	# nb: @c = (pkg, file, line, ...)
	$sx = "<anon>:$c[1]:$c[2]";
    }
    push @prof_stack, [$sx, $ti, $st];
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

    if( $ss < @prof_stack ){
	# we took an exception - account for aborted subs
	# print STDERR "exception detected!\n";
	
	while( $ss < @prof_stack ){
	    my $sk = pop @prof_stack;
	    my $sn = $sk->[0];
	    my $t  = time() - $sk->[1] - ($tacc - $sk->[2]);
	    $tacc += $t;
	    $prof_times{$sn} += $t;
	    $prof_calls{$sn} ++;
	    $prof_flags{$sn} |= 2;
	    $call ++;
	}
	$except++;
	$prof_flags{$sx} |= 4;
    }
    
    if( pop @prof_stack ){		# do not update if reset
	my $t = time() - $ti		# total time of called sub
	    - ($tacc - $st);		# minus time of subs it called
	$tacc += $t;
	$prof_times{$sx} += $t;		# We take no note of time
	$prof_calls{$sx} ++;		# But from its loss
	$call ++;			#   -- Edward Young, Night Thoughts
    }

    if( $wa ){
	@r;
    }else{
	$r;
    }
}

sub save {
    return if $saving;
    unless( $call ){
	# nothing to report
	$tsav = time();
	return;
    }
    $saving = 1;

    # only parent process
    return unless $$ == $prof_pid;
    
    my $tnow = time();
    my $ttwall = $tnow - $t0;
    my $f = $ENV{PERL_PROFILE_FILENAME} || 'prof.out';
    open( F, "> $f" ) || die "open failed, $f $!\n";

    # calc. an estimate of Tadj (overhead of DB::sub)
    # Tadj = 3/4 of the fastest sub
    my $tadj;
    foreach my $s (keys %prof_times){
	next unless $prof_calls{$s} >= 10;
	my $t = $prof_times{$s} / $prof_calls{$s};
	$tadj = $t if !defined($tadj) || $t < $tadj;
    }
    $tadj *= .75;
    
    # adjust run times
    my( %times, %calls, %flags );
    %calls = %prof_calls;
    %flags = %prof_flags;
    foreach (keys %prof_times){
	$times{$_} = $prof_times{$_} - $tadj * $prof_calls{$_};
    }
    
    # calculate profiling overhead, and hide our droppings
    my $calladj = 0;
    my $tprof = $tadj * $call + $times{Devel::Profile::__db_calibrate_adj} + $tprof_save;
    delete $times{Devel::Profile::__db_calibrate_adj};
    $calladj = 0 - $prof_calls{Devel::Profile::__db_calibrate_adj};
    
    # calc time of subs that never finished, by unwinding the saved call stack
    my $xend = $tnow;
    my $xacc = $tacc;
    foreach my $sk (reverse @prof_stack){
	# since it didn't return, we only adjust by half of Tadj
	my $sn = $sk->[0];
	my $t = $xend - $sk->[1] - ($xacc - $sk->[2]);
	$times{ $sn } += $t - $tadj/2;
	$calls{ $sn } ++;
	# and since we are using different math, and a different estimate of
	# the profiling overhead, we display a flag alerting the user
	$flags{ $sn } |= 2;
	$xend = $sk->[1];
	$xacc = $sk->[2];
	$tprof += $tadj/2;
	$calladj ++;
    }
    
    # calc time for other: "naked" code, ???
    unless( $ENV{PERL_PROFILE_DONT_OTHER} ){
	my $tnaked = $xend - $t0 - ($tacc - $tacc0);
	if( $tnaked < 0 ){
	    # dang! mis-estimates threw our numbers off by too much
	    # print STDERR "dang: $tnaked = $xend - $t0 - ($tacc - $tacc0)\n";
	    $tnaked = 0;
	}
	$times{'<other>'} = $tnaked;
	$calls{'<other>'} = 0;
	$flags{'<other>'} |= 1;
    }

    # total run time of program
    my $tt;
    foreach (values %times){$tt += $_}

    # dreams are very curious and unaccountable things
    #   -- Homer, Odyssey
    # unaccounted for "missing" time
    my $tmissing = $ttwall - $tt - $tprof;
    
    printf F "time elapsed (wall):   %.4f\n",           $ttwall;
    printf F "time running program:  %.4f  (%.2f%%)\n", $tt,       100 * $tt / $ttwall;
    printf F "time profiling (est.): %.4f  (%.2f%%)\n", $tprof,    100 * $tprof / $ttwall;
    printf F "missing time:          %.4f  (%.2f%%)\n", $tmissing, 100 * $tmissing / $ttwall
	if( $tmissing / $ttwall > 0.0001 );
    print F "number of calls:       ", $call + $calladj, "\n";
    print F "number of exceptions:  $except\n" if $except;
    
    print F "\n%Time    Sec.     \#calls   sec/call  F  name\n";
    foreach my $s (sort {$times{$b} <=> $times{$a}} keys %times){
	my $c = $calls{$s};
	my $t = $times{$s};
	my $tpc = $t / ($c || 1);
	my $pct = $t * 100 / $tt;
	my $sp = $s;

	if( substr($sp, 0, 6) eq '<anon>' ){
	    # make prettier
	    if( length($sp) > 35 ){
		$sp = '<anon>:...' . substr($sp, -28, 28);
	    }
	}
	
	printf F "%5.2f %9.4f  %7d  %9.6f %2s  $sp\n", 
	$pct, $t, $c, $tpc, F($flags{$s});
    }
    close F;

    # Let every man be master of his time
    #   -- Shakespeare, Macbeth
    # account for time spent saving data
    $tsav = time();
    my $telap = $tsav - $tnow;
    $tacc += $telap;
    $tprof_save += $telap;
    
    $saving = 0;
    reset() if $want_reset;
}

# 1=> *, 2=>?, 4=>x
sub F {
    ('', '*', '?', '?*', 'x', 'x*', 'x?', 'X?')[shift || 0];
}

sub reset {
    if( $saving ){
	$want_reset = 1;
	return;
    }
    save();
    $t0     = time();
    $tacc0  = $tacc;
    $call   = 0;
    $except = 0;
    %prof_calls = ();
    %prof_times = ();
    %prof_flags = ();
    @prof_stack = ();
    $want_reset = 0;
}

END {
    save();
}

################################################################
package Devel::Profile;
use strict;
sub __db_calibrate_adj {
    my $x = shift;
}
for my $i (1..$NCALOOP){
    __db_calibrate_adj();
}

################################################################

#	o   When execution of the program reaches a subroutine
#	    call, a call to "&DB::sub"(args) is made instead, with
#	    "$DB::sub" holding the name of the called subroutine.
#	    This doesn't happen if the subroutine was compiled in
#	    the "DB" package.)

################################################################

=head1 OUTPUT FORMAT

example ouput:
    
    time elapsed (wall):   86.8212
    time running program:  65.7657  (75.75%)
    time profiling (est.): 21.0556  (24.25%)
    number of calls:       647248
    
    %Time    Sec.     #calls   sec/call  F  name
    31.74   20.8770     2306   0.009053     Configable::init_from_config
    20.09   13.2116   144638   0.000091     Configable::init_field_from_config
    17.49   11.5043   297997   0.000039     Configable::has_attr
     8.22    5.4028      312   0.017317     MonEl::recycle
     7.54    4.9570    64239   0.000077     Configable::inherit
     5.02    3.3042   101289   0.000033     MonEl::unique
    [...]

This is a small summary, followed by one line per sub.

=over 4
  
=item time elapsed (wall)

This is the total time elapsed.

=item time running program

This is the amount of time spent running your program.

=item time profiling

This is the amount of time wasted due to profiler overhead.

=item number of calls

This is the total number of subroutine calls your program made.

=back

Followed by one line per subroutine.

=over 4

=item name

The name of the subroutine.

=item %Time

The percentage of the total program runtime used by this subroutine.

=item Sec.

The total number of seconds used by this subroutine.
    
=item #calls

The number of times this subroutine was called.
    
=item sec/call

The average number of seconds this subroutines takes each time it is called.
    
=item F

Flags.

=over 4

=item C<*>

pseudo-function to account for otherwise unacounted for time.
    
=item C<?>

At least one call of this subroutine did not return (typically because
of an C<exit>, or C<die>). The statistics for it may be slightly off.

=item C<x>

At least one call of this subroutine trapped an exception. 
The statistics for it may be slightly off.
    
=back
    
=back

=head1 LONG RUNNING PROGRAMS

This module was written so that the author could profile a large long-running
(daemon) program. Since normally, this program never exited, saving profiling
data only at program exit was not an interesting option. This module will save
profiling data periodically based on $PERL_PROFILE_SAVETIME, or the program
being profiled can call C<DB::save()> at any time. This allows you to watch
your profiling data while the program is running.

The above program also had a very large startup phase (reading config files,
building data structures, etc), the author wanted to see profiling data
for the startup phase, and for the running phase seperately. The running
program can call C<DB::reset()> to save the profiling data and reset the
statistics. Once reset, only "stuff" that happens from that point on will be
reflected in the profile data file.

By default, reset is attached to the signal handler for C<SIGUSR2>.
Using a perl built with "safe signal handling" (5.8.0 and higher),
you may safely send this signal to control profiling.

=head1 BUT I WANT INCLUSIVE TIMES NOT EXCLUSIVE TIMES

Please see the spin-off module Devel::DProfLB.    

=head1 BUGS

Some buggy XS based perl modules can behave erroneously when
run under the perl debugger. Since Devel::Profile uses the perl
debugger interfaces, these modules will also behave erroneously
when being profiled.
    
There are no known bugs in this module.

=head1 LICENSE
    
This software may be copied and distributed under the terms
found in the Perl "Artistic License".

A copy of the "Artistic License" may be found in the standard
Perl distribution.

=head1 SEE ALSO

    Yellowstone National Park.
    Devel::DProfLB
    
=head1 AUTHOR

Jeff Weisberg - http://www.tcp4me.com/

=cut
    ;

1;
