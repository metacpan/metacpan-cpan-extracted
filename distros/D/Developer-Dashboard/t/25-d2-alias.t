#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Cwd ();

use lib 'lib';

use Developer::Dashboard::PathRegistry;

# AC-1: ~/.d2 alone is recognised as the home runtime layer.
{
    my $home = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $home, '.d2' ) );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->home_runtime_path,
        File::Spec->catdir( $home, '.d2' ),
        'AC-1: home_runtime_path resolves to .d2 when only .d2 exists'
    );
}

# AC-2: $PWD/.d2 alone is recognised as a project-local runtime layer.
{
    my $home    = tempdir( CLEANUP => 1 );
    my $project = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $project, '.git' ) );
    make_path( File::Spec->catdir( $project, '.d2' ) );
    my $orig_cwd = Cwd::getcwd();
    chdir $project or die "Unable to chdir to $project: $!";
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->project_runtime_root,
        File::Spec->catdir( $project, '.d2' ),
        'AC-2: project_runtime_root resolves to .d2 when only $PWD/.d2 exists'
    );
    chdir $orig_cwd or die "Unable to chdir back to $orig_cwd: $!";
}

# AC-3: when both exist at the home layer, .developer-dashboard wins (Q-146).
{
    my $home = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $home, '.d2' ) );
    make_path( File::Spec->catdir( $home, '.developer-dashboard' ) );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->home_runtime_path,
        File::Spec->catdir( $home, '.developer-dashboard' ),
        'AC-3: .developer-dashboard is checked before .d2 when both exist (home layer)'
    );
}

# AC-3, project layer: same precedence.
{
    my $home    = tempdir( CLEANUP => 1 );
    my $project = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $project, '.git' ) );
    make_path( File::Spec->catdir( $project, '.d2' ) );
    make_path( File::Spec->catdir( $project, '.developer-dashboard' ) );
    my $orig_cwd = Cwd::getcwd();
    chdir $project or die "Unable to chdir to $project: $!";
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->project_runtime_root,
        File::Spec->catdir( $project, '.developer-dashboard' ),
        'AC-3: .developer-dashboard is checked before .d2 when both exist (project layer)'
    );
    chdir $orig_cwd or die "Unable to chdir back to $orig_cwd: $!";
}

# Fresh write: neither name exists yet, so the canonical (long) name is what
# gets created - home_runtime_path names it even though nothing is on disk.
{
    my $home  = tempdir( CLEANUP => 1 );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->home_runtime_path,
        File::Spec->catdir( $home, '.developer-dashboard' ),
        'fresh write: home_runtime_path names .developer-dashboard when neither exists'
    );
}

done_testing;

__END__

=head1 NAME

t/25-d2-alias.t - .d2 alias resolution for the runtime layer directory

=head1 PURPOSE

Verifies that C<.d2> is recognised as a shorter alias for
C<.developer-dashboard> at both the home and project runtime layers, that
C<.developer-dashboard> takes precedence when both exist, and that a fresh
(neither-exists-yet) layer is still named C<.developer-dashboard>.

=head1 WHY IT EXISTS

DD-809 (owner request via Telegram) asked for a shorter alias to the runtime
layer directory name. This is a naming alias only - the layer's behaviour
(config merging, hooks, collectors) is unchanged - so the test exercises
exactly the resolution logic, not the layer's downstream effects, which are
already covered by the existing PathRegistry test suite.

=head1 WHEN TO USE

Run this test after any change to C<PathRegistry>'s home-runtime or
project-layer resolution (C<home_runtime_path>, C<project_runtime_root>,
C<_ancestor_runtime_layers>).

=head1 HOW TO USE

  prove -lv t/25-d2-alias.t

=head1 WHAT USES IT

L<Developer::Dashboard::PathRegistry>, whose home-runtime and project-layer
resolution methods this test exercises directly.

=head1 EXAMPLES

  # Full run with verbose output
  prove -lv t/25-d2-alias.t

  # Run as part of the full suite
  prove -lr t

=cut
