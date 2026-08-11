#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

plan skip_all => 'Devel::Cover is not installed, so coverage attribution cannot be measured'
  if !eval { require Devel::Cover::DB; 1 };

# _run_instrumented($db, @command)
# Runs one perl command under a private Devel::Cover database, with the outer
# harness instrumentation stripped so the child cannot inherit this suite's own
# coverage options or database.
# Input: absolute database directory, then the perl arguments to run.
# Output: list of captured stdout, captured stderr, and the raw exit status.
sub _run_instrumented {
    my ( $db, @command ) = @_;
    local %ENV = %ENV;
    delete @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT DEVEL_COVER_OPTIONS)};
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, "-MDevel::Cover=-db,$db,-silent,1,-blib,0", @command );
    };
    return ( $stdout, $stderr, $exit );
}

# _subroutine_coverage($db, $file_re, $name)
# Reads back how many times one named subroutine was recorded as covered in a
# Devel::Cover database. The pending run files are merged first, because a
# database that has never been reported on still holds its runs unmerged, and
# the working directory must match the one the run was made from or Devel::Cover
# cannot match a structure to its source.
# Input: database directory, regex matching the file of interest, subroutine name.
# Output: total recorded coverage count, or undef when the subroutine is absent.
sub _subroutine_coverage {
    my ( $db, $file_re, $name ) = @_;
    my $database = Devel::Cover::DB->new( db => $db );
    $database->merge_runs;
    my $cover = $database->cover;
    return undef if !$cover;
    for my $filename ( $cover->items ) {
        next if $filename !~ $file_re;
        my $subroutines = $cover->file($filename)->subroutine;
        next if !$subroutines;
        for my $line ( $subroutines->items ) {
            for my $sub ( @{ $subroutines->location($line) } ) {
                return $sub->covered if $sub->name eq $name;
            }
        }
    }
    return undef;
}

# ---- The hazard itself, reproduced hermetically -----------------------------
# A failed exec is not a no-op for Devel::Cover: it writes the run and stops
# recording, because from its point of view the process is about to be replaced.
# Every statement the process goes on to run is then invisible to the coverage
# gate while still executing and still passing its assertions.
{
    my $sandpit = tempdir( CLEANUP => 1 );
    my $module  = File::Spec->catfile( $sandpit, 'DDExecProbe.pm' );
    open( my $module_fh, '>', $module ) or die "Unable to write $module: $!";
    print {$module_fh} <<'PROBE_MODULE';
package DDExecProbe;
sub before_exec { return 1 }
sub after_exec  { return 2 }
1;
PROBE_MODULE
    close($module_fh) or die "Unable to close $module: $!";

    my $script = File::Spec->catfile( $sandpit, 'probe.pl' );
    open( my $script_fh, '>', $script ) or die "Unable to write $script: $!";
    print {$script_fh} <<'PROBE_SCRIPT';
use strict;
use warnings;
use DDExecProbe;
DDExecProbe::before_exec();
{
    no warnings 'exec';
    my $missing = '/nonexistent/dd428/exec/probe';
    exec { $missing } $missing;
}
DDExecProbe::after_exec();
PROBE_SCRIPT
    close($script_fh) or die "Unable to close $script: $!";

    my $db = File::Spec->catdir( $sandpit, 'cover_db' );
    my $origin = getcwd();
    chdir $sandpit or die "Unable to chdir to $sandpit: $!";
    my ( undef, undef, $exit ) = _run_instrumented( $db, "-I$sandpit", $script );
    is( $exit, 0, 'the exec probe script completes after its exec fails' );

    is( _subroutine_coverage( $db, qr{DDExecProbe\.pm\z}, 'before_exec' ),
        1, 'Devel::Cover records a subroutine called before the failed exec' );
    is( _subroutine_coverage( $db, qr{DDExecProbe\.pm\z}, 'after_exec' ),
        0, 'Devel::Cover records nothing for a subroutine called after the failed exec' );
    chdir $origin or die "Unable to chdir to $origin: $!";
}

# ---- The regression gate ----------------------------------------------------
# t/110 drives the exec-failure path of the saved-Ajax launcher. It must do so
# in a forked child: an exec attempt in the harness process would silently drop
# every later assertion in that file out of the coverage gate, which is exactly
# how PageRuntime's process-group cleanup came to be graded as if its own unit
# test did not exist.
{
    my $sandpit = tempdir( CLEANUP => 1 );
    my $db      = File::Spec->catdir( $sandpit, 'cover_db' );
    my $target  = File::Spec->catfile( $ROOT, 't', '110-saved-ajax-group-coverage.t' );
    ok( -f $target, 'the saved-Ajax process-group test file is present' );

    my $origin = getcwd();
    chdir $ROOT or die "Unable to chdir to $ROOT: $!";
    my ( $stdout, undef, $exit ) = _run_instrumented( $db, "-I" . File::Spec->catdir( $ROOT, 'lib' ), $target );
    is( $exit, 0, 'the saved-Ajax process-group test file passes standalone' );
    like( $stdout, qr/^ok /m, 'the saved-Ajax process-group test file produced assertions' );

    my $covered = _subroutine_coverage( $db, qr{PageRuntime\.pm\z}, '_terminate_saved_ajax_process' );
    ok( defined $covered, 'the saved-Ajax termination helper appears in the coverage database' );
    cmp_ok( $covered || 0, '>', 0,
        'the saved-Ajax termination assertions reach the coverage gate instead of being lost behind a failed exec' );
    chdir $origin or die "Unable to chdir to $origin: $!";
}

done_testing;

__END__

=head1 NAME

t/138-coverage-exec-truncation.t - keep a failed exec from blinding the coverage gate

=head1 PURPOSE

A regression gate for DD-428. It pins that no test in this repository attempts
an C<exec> in the harness process before the assertions that the coverage gate
depends on.

Devel::Cover writes its run and stops recording the moment a process attempts
an C<exec>, because the process is expected to be replaced. When the C<exec>
fails, the process carries on and every statement it runs afterwards executes
normally, passes its assertions, and records zero coverage. The loss is
completely silent: the test file still reports success.

=head1 WHY IT EXISTS

The saved-Ajax process-group unit test drives the real exec-failure path of the
launcher. It used to do so in the harness process, roughly a third of the way
through the file, so the fifteen process-termination assertions that follow it
contributed nothing to the coverage gate. The gate consequently graded
C<Developer::Dashboard::PageRuntime> as if its process-group cleanup had no unit
test at all, and reported an uncovered branch on a line that the suite really
does exercise. A test file that passes while contributing no coverage is the
worst shape this instrument can be in, because it reads as protection that is
not there.

=head1 WHEN TO USE

Run it whenever a test gains an C<exec> call, whenever the saved-Ajax launcher
or its process-group cleanup changes, and after any upgrade of Devel::Cover.

=head1 HOW TO USE

  prove -lv t/138-coverage-exec-truncation.t

=head1 WHAT USES IT

The repository test suite, through C<prove -lr t>, and every coverage run that
depends on the saved-Ajax process-group assertions being counted.

=head1 EXAMPLES

Run the gate on its own:

  prove -lv t/138-coverage-exec-truncation.t

Run it beside the test file whose attribution it protects:

  prove -lv t/110-saved-ajax-group-coverage.t t/138-coverage-exec-truncation.t

Run it beside the other coverage-instrument gates:

  prove -lv t/133-coverage-gate-blib-isolation.t t/138-coverage-exec-truncation.t

=cut
