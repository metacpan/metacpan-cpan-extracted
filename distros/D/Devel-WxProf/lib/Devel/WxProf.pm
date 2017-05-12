package Devel::WxProf;
BEGIN {
    # begin block to make sure we don't profile yet...
    use strict; use warnings;
    use version; our $VERSION = qv(0.0.1);
}

package DB;
no strict;
use Time::HiRes qw(time gettimeofday tv_interval);

my @prof_stack =    (); # call stack, to account for subs that haven't returned
my $prof_pid;           # process id of process being profiled
my $tmpfile;            # temporary data file

my $monfile = $ENV{PERL_DPROF_OUT_FILE_NAME} || 'tmon.out';

my $resolution;         # tick resolution
my $overhead;

my %sub_id_of =     (); # associate sub names with IDs
my $sub_id_counter = 0; # ID counter

my $last_real_time;     # records the last time

our $sub;               # needs to be defined

my $hz;                 # clock ticks per second
my $start;              # debugging start time

my $wall_ticks;         # wall clock ticks

sub DB {}
sub sub {}
sub get_time () {
    int( ( time() - $start) * $hz );
}

sub _prof {
    $wall_ticks = get_time();
}

sub calibrate {
    my $start = time();
    for (1..10000) {
        _prof();
        _prof();
    }
    my $end = time();
    $overhead = int( ($end - $start) / 10000 * $hz);
}

BEGIN {
    # profile
    # 0x01    Debug subroutine enter/exit.
    # 0x02    Line-by-line debugging.
    # 0x04    Switch off optimizations.
    # 0x08    Preserve more data for future interactive inspections.
    # 0x10    Keep info about source lines on which a subroutine is defined.
    # 0x20    Start with single-step on.
    # 0x40    Use subroutine address instead of name when reporting.
    # 0x80    Report goto &subroutine as well.
    # 0x100   Provide informative "file" names for evals based on the place they were compiled.
    # 0x200   Provide informative names to anonymous subroutines based on the place they were compiled.
    # 0x400   Debug assertion subroutines enter/exit.

    $^P = 0x311;

    $prof_pid = $$;
    $tmpfile  = "wxmon$$.out";
    open(PROF, ">$tmpfile") || die "cannot open $tmpfile: $!\n";

    # calculate hertz
    $resolution = Time::HiRes::clock_getres();
    $hz = 1/$resolution;

    $start = time();
    # TODO: replace with better calibration
    calibrate();

    $start = time();

    $last_real_time = get_time();
    no warnings qw(redefine);
    *DB::sub = \&_sub;
}

END {
    # original process only, if we fork()
    return unless $$ == $prof_pid;

    $wall_ticks = get_time();

    # generate data for any unfinished subs
    if( @prof_stack ){
        print PROF "# the following did not return, due to program termination\n";
        for my $asx (reverse @prof_stack){
            print PROF "- $sub_id_of{$asx}\n";
        }
    }

    {
        # wipe out DB::sub to stop profiling here.
        no warnings qw(redefine);
        *DB::sub = sub {};
    }
    close PROF;

    my $elapsed = int( ( time()-$start) * $hz );

    open(my $fh, ">", $monfile) || die "cannot open $monfile: $!\n";

    # output header
    print $fh "#fOrTyTwO\n";
    # this portion of the header is blindly evaled by dprofpp
    # any valid perl may be placed here
    print $fh "# Devel::WxProf";
    print $fh "# All timing values are given in \n";
    print $fh "\$hz = $hz;\n";
    print $fh "# Estimated profiling overhead per call:\n";
    print $fh "\$over_utime=$overhead; \$over_stime=0; \$over_rtime=$overhead;
\$over_tests=1;
\$rrun_utime=$elapsed; \$rrun_stime=0; \$rrun_rtime=$elapsed;
\$total_marks=$elapsed;

";

    print $fh "PART2\n";

    open my $tmp_fh, "<", $tmpfile;
    while (my $line = <$tmp_fh>) {
        print $fh $line;
    }
    close $tmp_fh;
    close $fh;

    unlink $tmpfile;

    $prof_pid = undef;
}

sub _sub {
    my( $wa, $r, @r );
    my $elapsed;

    $wall_ticks = get_time();
    $elapsed = $wall_ticks - $last_real_time;
    $last_real_time = $wall_ticks;

    my $sx = $sub;
    if( ref $sx ) {
        my @caller_from = caller(0);
        if ($caller_from[0] ne 'DB') {
            my @caller_from = caller(1);
            if (defined($caller_from[3]) && $caller_from[3] eq '(eval)') {
                if (defined($caller_from[7]) && $caller_from[7]==1) {
                    $sx = undef; # a eval from a require
                }
                else {
                    if (!$caller_from[0]) {
                        $sx = undef; # a eval from main - hard to profile, might be "use"
                    }
                    else {
                        $sx = $caller_from[0] . "::__ANON__[$caller_from[2]]";
                    }
                }
            }
            else {
                $sx = undef;
            }
        }
        else {
            $sx = undef;
        }
    }

    if ($sx) {
        if (! exists ($sub_id_of{ $sx })) {
            $sub_id_of{ $sx } = $sub_id_counter++;
            my ($package, $sub_name) = $sx =~m{ (.+)*::(.+) $}x;
            warn $sx if not $package;
            print PROF "& $sub_id_of{ $sx } $package $sub_name\n";
        }

        # do not corrupt data on fork()
        $prof_pid ||= 0;
        my $noprof = $$ != $prof_pid;
        if( $noprof ){
            close PROF;
        }

        # print PROF "+ $wall_ticks $sx\n" unless $noprof;
        print PROF "\@ $elapsed 0 $elapsed\n+ $sub_id_of{ $sx }\n";

        push @prof_stack, $sx;
        my $ss = @prof_stack;

        $wa = wantarray;
        if( $wa ){
            @r = &$sub;
        }
        elsif( defined $wa ){
            $r = &$sub;
        }
        else {
            &$sub;
        }

        if( $ss < @prof_stack ){
            # we took an exception - account for aborted subs

            while( $ss < @prof_stack ){
                my $asx = pop @prof_stack;
                next if $noprof;
                print PROF "\@ $elapsed 0 $elapsed\n- $sub_id_of{ $sx }\n";
            }
        }

        pop @prof_stack;
        print PROF "\@ $elapsed 0 $elapsed\n- $sub_id_of{ $sx }\n";

    }
    else {
        $wa = wantarray;
        if( $wa ){
            @r = &$sub;
        }
        elsif( defined $wa ){
            $r = &$sub;
        }
        else {
            &$sub;
        }
    }

    if( $wa ){
        @r;
    } else {
        $r;
    }

}

1;

__END__

=head1 NAME

Devel::WxProf - heavy-weight subroutine profiler and graphical profile analyzer

=head1 SYNOPSIS

    perl -d:WxProf program.pl
    wxprofile tmon.out

    # or if you like it better:
    dprofpp

    # or even
    perl -d:DProf program.pl
    wxprofile tmon.out

=head1 DESCRIPTION

Devel::WxProf package is a heavy-weight subroutine profiler for perl.

It collects information on the execution time of a Perl script - more
specifically: on the subs called from that script.

To profile a Perl script run the perl interpreter with the
-d debugging switch. The profiler uses the debugging
hooks.  So to profile script test.pl the following command
should be used:

    perl -d:WxProf test.pl

When the script terminates the profiler will dump the profile information to
a file called wxmon.out.

Use L<wxprofile|wxprofile> to display the information collected.

Devel::WxProf uses the (new) output format of L<Devel::DProf|Devel::DProf>.
You may thus use dprofpp to analyze the data, or analyze data collected using
L<Devel::DProf|Devel::DProf>.

Note that real (wall) time is reported as user time, and system tyme is not
reported at all, which means that dprofpp is likely to produce slightly
different output for profile data created by Devel::WxProf and
L<Devel::DProf|Devel::DProf>.

L<Devel::DProf|Devel::DProf> usually reports times at 1/100s granularity, so
one-shot data collected by L<Devel::DProf|Devel::DProf> is likely to be
useless (and results largely random).

=head1 ENVIRONMENT

=over 4

=item C<PERL_DPROF_OUT_FILE_NAME>

Filename to save profile data to, default is F<tmon.out>

=back

=head1 BUGS AND LIMITATIONS

Many.

Devel::WxProf measures wall clock times. These may be happily inaccurate -
especially if run under a system with heavy load, or a program using
interactive dialogs. Wall clock (also called stopwatch) times do not
nesseccarily represnt the processing time required to run a program.

Devel::WxProf does not profile anonymous subroutines (yet).

Valid profiling data is not saved until the application terminates and runs
this modules END{} block. Applications which cause END{} blocks not to run
(such as call _exit or exec) will leave a corrupt and/or incomplete temporary
data file.

WxProf reports time in your system's high resolution timer's clock ticks -
usually micro- or nanoseconds. The exact times reported by WxProf are
badly inaccurate.

If the program being profiled contains subroutines which do not return in a
normal manner (such as by throwing an exception), the timing data is
estimated and may be attributed incorrectly. The time data might even get
corrupted.

WxProf (and wxprofile) are heavy-weight tools. Use with care. You should
not try to profile benchmarks with WxProf - try it on single runs instead.

=head1 SEE ALSO

    Devel::Profile
    Devel::DProfLB
    Devel::DProf
    dprofpp

=head1 DEVELOPEMENT

I wrote Devel::WxProf because I needed a fine-grained one-shot profiler
(and because I saw that cool treemap in kcachegrind). I actually wrote it
for myself. I'd be pleased if you find it useful, but I probably won't put
much time into bugfixes. Send me a test and a patch if you want to speed
things up. If you're really out for boosting development, I'll set up a
repository I can open up...

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Martin Kutter.

Based on L<Devel::DProfLB|Devel::DProfLB> by Jeff Weisberg

This library is free software. You may distribute/modify it under
the same terms as perl itself

=head1 AUTHOR

Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: 583 $
 $LastChangedBy: kutterma $
 $Id: $
 $HeadURL: $

=cut
