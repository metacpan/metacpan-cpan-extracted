#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PathRegistry;
use Template;

# A path registry stand-in whose bookmark roots deliberately do not exist on
# disk, so the template-engine fallback chain has to discard every root before
# it reaches the project-root attempt.
{
    package Local::GhostDashboardPaths;

    sub new {
        my ( $class, @roots ) = @_;
        return bless { roots => [@roots] }, $class;
    }

    sub dashboards_roots { return @{ $_[0]{roots} }; }
}

# Hermetic runtime rooted in a throwaway home, with the deepest runtime layer
# resolved from the current working directory.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths            = Developer::Dashboard::PathRegistry->new( home => $home );
my $runtime          = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $runtime_no_paths = Developer::Dashboard::PageRuntime->new();

# The real constructor (inherited from Template::Base), resolved through can()
# so the reference survives shadowing Template::new, and kept so the fallback
# attempts can build working engines while the first attempt is forced to fail.
my $real_template_new = Template->can('new') or die 'Template cannot construct';

# fail_first_template_new(\@include_paths)
# Builds a Template::new replacement that snapshots the include roots of every
# construction attempt and fails only the first one. The snapshot matters because
# the runtime hands over its own live root array and then filters it in place.
# Input: array reference that collects one include-root copy per attempt.
# Output: code reference suitable for a localized Template::new.
sub fail_first_template_new {
    my ($include_paths) = @_;
    return sub {
        my ( $class, @rest ) = @_;
        push @{$include_paths}, [ @{ $rest[0]{INCLUDE_PATH} } ];
        return undef if @{$include_paths} == 1;
        return $real_template_new->( $class, @rest );
    };
}

# ---- L198/L199/L200/L203/L206: engine construction failure and recovery ------
{
    # First construction fails, the cwd root survives the -d filter, and the
    # retry with the filtered roots produces a working engine (L200 taken,
    # L203 left side already true, L206 not taken).
    my @include_paths;
    no warnings 'redefine';
    local *Template::new = fail_first_template_new( \@include_paths );

    my $page = Developer::Dashboard::PageDocument->new(
        id     => 'tt-filtered-roots',
        state  => { who => 'Retry' },
        layout => { body => 'Hi [% who %]' },
    );
    $runtime_no_paths->_render_templates( page => $page, runtime_context => {} );

    is( scalar(@include_paths), 2, '_render_templates retries the template engine once when the first construction fails' );
    is_deeply(
        $include_paths[1],
        ['.'],
        '_render_templates retries with only the include roots that exist on disk',
    );
    is( $page->{layout}{body}, 'Hi Retry', '_render_templates renders the body through the retried engine' );
    is_deeply( $page->{meta}{runtime_errors}, undef, '_render_templates records no runtime error when the retry succeeds' );
}

{
    # Every bookmark root is missing, so the -d filter empties the list, the
    # filtered retry is skipped (L200 not taken) and the project-root fallback
    # on L203 builds the engine instead.
    my $ghost_a = File::Spec->catdir( $home, 'ghost-dashboards-a' );
    my $ghost_b = File::Spec->catdir( $home, 'ghost-dashboards-b' );
    ok( !-d $ghost_a && !-d $ghost_b, 'the ghost bookmark roots are absent before the fallback runs' );

    my $ghost_runtime = Developer::Dashboard::PageRuntime->new(
        paths => Local::GhostDashboardPaths->new( $ghost_a, $ghost_b ),
    );

    my @include_paths;
    no warnings 'redefine';
    local *Template::new = fail_first_template_new( \@include_paths );

    my $page = Developer::Dashboard::PageDocument->new(
        id     => 'tt-project-root',
        state  => { who => 'Fallback' },
        layout => { body => 'Ghost [% who %]' },
    );
    $ghost_runtime->_render_templates( page => $page, runtime_context => {} );

    is( scalar(@include_paths), 2, '_render_templates skips the filtered retry when no bookmark root exists' );
    is_deeply(
        $include_paths[0],
        [ $ghost_a, $ghost_b ],
        '_render_templates first tries the inherited bookmark roots',
    );
    is_deeply( $include_paths[1], ['.'], '_render_templates falls back to the project root' );
    is( $page->{layout}{body}, 'Ghost Fallback', '_render_templates renders the body through the project-root engine' );
}

{
    # No engine can be constructed at all, so _render_templates gives up before
    # touching the layout (L206 taken).
    my $attempts = 0;
    no warnings 'redefine';
    local *Template::new = sub { $attempts++; return undef };

    my $page = Developer::Dashboard::PageDocument->new(
        id     => 'tt-unconstructable',
        state  => { who => 'Nobody' },
        layout => { body => 'Body [% who %]' },
    );
    my $rv = $runtime_no_paths->_render_templates( page => $page, runtime_context => {} );

    is( $attempts, 3, '_render_templates tries the inherited roots, the filtered roots, and the project root' );
    is( $rv, undef, '_render_templates returns nothing when no template engine can be constructed' );
    is( $page->{layout}{body}, 'Body [% who %]', '_render_templates leaves the raw body in place when no engine exists' );
    is_deeply( $page->{meta}{runtime_errors}, undef, '_render_templates records no runtime error when it cannot build an engine' );
}

# ---- L657/L662/L666: group-owning termination of an already-gone worker ------
{
    my $reaped = fork();
    die "fork failed: $!" if !defined $reaped;
    if ( !$reaped ) { POSIX::_exit(0); }
    waitpid( $reaped, 0 );
    ok( !kill( 0, $reaped ), 'the throwaway worker pid is gone before termination runs' );

    # Owning a process group skips the early "already dead" return, so the wait
    # loop sees the missing pid immediately (L662 taken) and the SIGKILL escalation
    # is skipped (L666 not taken).
    is(
        $runtime->_terminate_saved_ajax_process( $reaped, $reaped ),
        1,
        '_terminate_saved_ajax_process stops early when a group-owned worker has already gone',
    );

    # A zero process group is defined and numeric but not a real group, so the
    # group-ownership condition fails on its final operand (L657 right side false).
    is(
        $runtime->_terminate_saved_ajax_process( $reaped, 0 ),
        1,
        '_terminate_saved_ajax_process treats a zero process group as unowned',
    );
}

# ---- L940: the saved-Ajax launcher reports a failed exec --------------------
{
    # '0 but true' keeps the isolation guard satisfied without detaching this test
    # from the harness process group, and the warn trap swallows perl's mandatory
    # failed-exec warning so the run stays output-clean.
    local $Developer::Dashboard::PageRuntime::SETPGID = sub { return '0 but true' };
    my $missing = File::Spec->catfile( $home, 'no-such-saved-ajax-worker' );
    ok( !-e $missing, 'the launcher target does not exist' );

    my @warnings;
    my $error = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0]; return 1 };
        eval {
            Developer::Dashboard::PageRuntime->_exec_saved_ajax_command($missing);
            1;
        } ? '' : $@;
    };
    like(
        $error,
        qr/\AUnable to exec saved ajax command \Q$missing\E: /,
        '_exec_saved_ajax_command dies when the worker command cannot be executed',
    );
    like(
        join( '', @warnings ),
        qr/Can't exec/,
        '_exec_saved_ajax_command really attempted the exec before reporting the failure',
    );
}

done_testing;

__END__

=head1 NAME

t/116-pageruntime-coverage-2.t - second-wave branch and condition closure for the page runtime

=head1 PURPOSE

This test closes the remaining branch and condition edges of
C<Developer::Dashboard::PageRuntime> that the rest of the suite never reaches:
the template-engine construction fallback chain, the process-group ownership
condition used when cancelling a saved-Ajax worker, the wait loop that finds the
worker already gone, and the launcher's failed-exec report.

=head1 WHY IT EXISTS

It exists because those edges only appear in degraded conditions - a Template
Toolkit engine that refuses to build for the inherited bookmark roots, a worker
that has already exited by the time cancellation starts, and an unexecutable
worker command. Normal browser and CLI flows always take the healthy side, so
without a dedicated test the recovery code would ship unexercised while the
coverage gate quietly slipped below 100 percent on branch and condition.

=head1 WHEN TO USE

Use this file when changing how the page runtime builds its Template Toolkit
engine or resolves bookmark include roots, how it terminates saved-Ajax workers
and their process groups, or how the in-module launcher establishes process-group
ownership and execs the worker command.

=head1 HOW TO USE

Run it on its own with C<prove -lv t/116-pageruntime-coverage-2.t> while
iterating, then keep it green under C<prove -lr t> and under the Devel::Cover
gate. The test is hermetic: it roots a throwaway home, changes into it so the
deepest runtime layer resolves from the working directory, builds path registries
explicitly, and only ever signals process ids it forked itself.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> run, and the all-metric coverage
gate rely on this file together with the first page-runtime coverage test to keep
the module at 100 percent on statement, subroutine, branch, and condition.

=head1 EXAMPLES

Example 1:

  prove -lv t/116-pageruntime-coverage-2.t

Run this coverage closure test by itself while iterating on the page runtime.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/116-pageruntime-coverage-2.t

Collect coverage for the page runtime while running only these cases.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before release.

=cut
