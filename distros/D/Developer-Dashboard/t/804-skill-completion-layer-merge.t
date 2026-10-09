#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Complete;

my $original_cwd = getcwd();
my $dashboard = File::Spec->catfile( $original_cwd, 'bin', 'dashboard' );
my $home = tempdir( CLEANUP => 1 );
my $project = File::Spec->catdir( $home, 'project' );
my $home_skill = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'layered-skill' );
my $project_skill = File::Spec->catdir( $project, '.developer-dashboard', 'skills', 'layered-skill' );
make_path(
    File::Spec->catdir( $project, '.git' ),
    File::Spec->catdir( $home_skill, 'cli' ),
    File::Spec->catdir( $project_skill, 'cli' ),
);

_write_executable( File::Spec->catfile( $home_skill, 'cli', 'home-only' ) );
_write_executable( File::Spec->catfile( $project_skill, 'cli', 'project-only' ) );
_write_executable( File::Spec->catfile( $home_skill, 'cli', 'shared' ) );
_write_executable( File::Spec->catfile( $project_skill, 'cli', 'shared' ) );

local $ENV{HOME} = $home;
chdir $project or die "Unable to chdir to $project: $!";

my ( undef, undef, $init_exit ) = capture {
    system $^X, $dashboard, 'init';
};
is( $init_exit >> 8, 0, 'dashboard init stages the normal home private helper runtime for the public-command check' );

my @candidates = Developer::Dashboard::CLI::Complete::complete(
    words => [ 'd2', 'layered-skill.' ],
    index => 1,
);

is_deeply(
    [ sort @candidates ],
    [ qw(layered-skill.home-only layered-skill.project-only layered-skill.shared) ],
    'd2 skill-prefix completion merges project and home commands without duplicating shared names',
);
my ( $stdout, $stderr, $exit ) = capture {
    system $^X, $dashboard, 'complete', '1', 'd2', 'layered-skill.';
};
is( $exit >> 8, 0, 'the public dashboard completion command exits successfully for the layered skill prefix' );
is( $stderr, '', 'the public dashboard completion command emits no errors' );
is_deeply(
    [ sort grep { $_ ne '' } split /\n/, $stdout ],
    [ qw(layered-skill.home-only layered-skill.project-only layered-skill.shared) ],
    'the command used by shell TAB completion returns both layers and one shared command',
);
chdir $original_cwd or die "Unable to restore working directory to $original_cwd: $!";

done_testing;

# _write_executable($path)
# Creates a runnable fixture CLI in one skill layer.
# Input: destination file path string.
# Output: true value after the fixture is closed and executable.
sub _write_executable {
    my ($path) = @_;
    open my $fh, '>', $path or die "Unable to create $path: $!";
    print {$fh} "#!/bin/sh\nexit 0\n";
    close $fh or die "Unable to close $path: $!";
    chmod 0755, $path or die "Unable to chmod $path: $!";
    return 1;
}

__END__

=pod

=head1 NAME

t/804-skill-completion-layer-merge.t - verify completion merges same-named skill layers

=head1 DESCRIPTION

Creates an isolated temporary home and Git project. Both runtime layers
contain a skill named C<layered-skill>; the project layer exposes one unique
CLI command and the home layer exposes another. Both layers also expose the
same C<shared> command to verify that completion returns one candidate for an
effective command name, not one entry per physical copy.

=head1 PURPOSE

This test protects the command completion contract for C<d2
layered-skill.<TAB>> when a project-local skill overlays an installed
home-level skill. Completion must enumerate command names from every
participating layer so an overlay cannot hide commands inherited from home.

=head1 WHY IT EXISTS

Skill lookup is layered, but completion previously enumerated only the
highest-priority physical root for a skill name. That made valid home-level
commands disappear whenever a project contained any skill directory with
the same name. This test keeps the completion inventory aligned with layered
command lookup while leaving actual command execution precedence unchanged.

=head1 WHEN TO USE

Run this test when changing C<Developer::Dashboard::CLI::Suggest>,
C<Developer::Dashboard::CLI::Complete>, skill-layer discovery, or shell
completion behavior. It uses only temporary directories and does not read or
modify the operator's installed skills.

=head1 HOW TO USE

Run it inside the repository's development Docker service:

  prove -lv t/804-skill-completion-layer-merge.t

The full repository suite and the coverage gate should also include it before
release.

=head1 WHAT USES IT

The automated test suite runs it through C<prove -lr t>. It checks both
C<CLI::Complete::complete> and the public C<dashboard complete> helper that
generated bash and zsh completion functions invoke.

=head1 EXAMPLES

Example 1:

  d2 layered-skill.<TAB>

Both C<layered-skill.project-only> and C<layered-skill.home-only> should be
available.

Example 2:

  prove -lv t/804-skill-completion-layer-merge.t

The assertion fails when either layer is hidden or when the shared command
appears more than once.

=cut
