#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(getcwd);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;

sub spew {
    my ( $path, $content ) = @_;
    my $dir = ( File::Spec->splitpath($path) )[1];
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

sub fake_git {
    my ($body) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    my $git = File::Spec->catfile( $dir, 'git' );
    spew( $git, "#!/bin/sh\n$body\n" );
    chmod 0755, $git or die $!;
    return $dir;
}

my $orig_cwd = getcwd();
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die $!;

my $paths   = Developer::Dashboard::PathRegistry->new( home => $home );
my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );

# disable(): the marker path is a directory, so it cannot be written.
{
    my $skill = File::Spec->catdir( $paths->skills_root, 'blockme' );
    make_path($skill);
    spew( File::Spec->catfile( $skill, '.env' ), "VERSION=1\n" );
    my $marker = $manager->_disabled_marker_path($skill);
    make_path($marker);
    like( $manager->disable('blockme')->{error}, qr/Unable to write disabled marker/, 'disable reports a marker that cannot be written' );
}

# _register_root_ddfile_source(): the ddfile path is a directory.
{
    my $blocked_home = tempdir( CLEANUP => 1 );
    my $blocked_paths = Developer::Dashboard::PathRegistry->new( home => $blocked_home );
    my $blocked = Developer::Dashboard::SkillManager->new( paths => $blocked_paths );
    make_path( File::Spec->catdir( $blocked_paths->home_runtime_root, 'ddfile' ) );
    like( $blocked->_register_root_ddfile_source('https://example.invalid/x.git')->{error}, qr/Unable to update root ddfile/, 'an unwritable root ddfile is reported' );
}

# _clone_skill_source(): failed first branch followed by a cleanup failure.
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_clone_skill_branch = sub { return { error => 'nope' } };
    local *Developer::Dashboard::SkillManager::_remove_existing_skill_path = sub { return { error => 'stuck' } };
    my $result = $manager->_clone_skill_source( 'https://example.invalid/x.git', File::Spec->catdir( $home, 'tgt' ), undef );
    like( $result->{error}, qr/Unable to retry skill clone after branch 'master' failed: stuck/, 'a cleanup failure aborts the master to main retry' );
}

# Missing branch guards.
{
    is( $manager->_clone_skill_branch( 'src', 'tgt', undef )->{error}, 'Missing remote skill branch', '_clone_skill_branch rejects an undefined branch' );
    is( $manager->_clone_skill_branch( 'src', 'tgt', '' )->{error},    'Missing remote skill branch', '_clone_skill_branch rejects an empty branch' );
    is( $manager->_validate_skill_branch(undef)->{error}, 'Missing remote skill branch', '_validate_skill_branch rejects an undefined branch' );
    is( $manager->_validate_skill_branch('')->{error},    'Missing remote skill branch', '_validate_skill_branch rejects an empty branch' );
}

# Silent git failures fall back to the generic messages.
{
    my $silent = fake_git('exit 1');
    local $ENV{PATH} = "$silent:$ENV{PATH}";
    my $dir = File::Spec->catdir( $home, 'gitish' );
    make_path( File::Spec->catdir( $dir, '.git' ) );
    like( $manager->_current_installed_skill_branch($dir)->{error}, qr/git could not report the current branch/, 'a silent git failure reports the generic branch message' );
    like( $manager->_validate_skill_branch('x')->{error}, qr/git rejected the branch name/, 'a silent ref-format failure reports the generic message' );
}

# Empty git output means no named branch.
{
    my $empty = fake_git('exit 0');
    local $ENV{PATH} = "$empty:$ENV{PATH}";
    my $dir = File::Spec->catdir( $home, 'gitish' );
    is( $manager->_current_installed_skill_branch($dir), undef, 'empty git output means no named branch' );
}

# install(): an existing checkout whose branch cannot be read, then a detached one.
{
    my $inst_home = tempdir( CLEANUP => 1 );
    my $inst_paths = Developer::Dashboard::PathRegistry->new( home => $inst_home );
    my $inst = Developer::Dashboard::SkillManager->new( paths => $inst_paths );
    my $existing = File::Spec->catdir( $inst_paths->skills_root, 'sticky' );
    make_path( File::Spec->catdir( $existing, '.git' ) );

    {
        my $failing = fake_git( 'echo broken >&2; exit 1' );
        local $ENV{PATH} = "$failing:$ENV{PATH}";
        like( $inst->install('https://example.invalid/sticky.git')->{error}, qr/Unable to detect current branch/, 'install surfaces a branch-detection error for an existing checkout' );
    }

    {
        my $detached = fake_git( 'echo HEAD' );
        local $ENV{PATH} = "$detached:$ENV{PATH}";
        my $selected = 'unset';
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_clone_skill_source = sub { $selected = $_[3]; return { error => 'intercepted' } };
        is( $inst->install('https://example.invalid/sticky.git')->{error}, 'intercepted', 'install proceeds when the existing checkout is detached' );
        is( $selected, undef, 'a detached checkout leaves the clone branch unset' );
    }
}

# _install_skill_nested_dependency_manifest guard clauses and loop paths.
{
    my $owner = File::Spec->catdir( $paths->skills_root, 'owner' );
    make_path($owner);
    no warnings 'redefine';
    {
        local *Developer::Dashboard::SkillManager::_install_path_contained = sub { return 0 };
        like( $manager->_install_skill_nested_dependency_manifest( $owner, 'ddfile.local', 'https://example.invalid/dep.git' )->{error}, qr/Refusing to use an owning skill outside its skills root/, 'an owner outside its skills root is refused' );
    }
    {
        my $calls = 0;
        local *Developer::Dashboard::SkillManager::_install_path_contained = sub { return ++$calls == 1 ? 1 : 0 };
        like( $manager->_install_skill_nested_dependency_manifest( $owner, 'ddfile.local', 'https://example.invalid/dep.git' )->{error}, qr/Refusing to use a skill-local skills root outside its owner/, 'a skills root outside its owner is refused' );
    }
    {
        local $ENV{DEVELOPER_DASHBOARD_INSTALL_STACK} = 'dep';
        my $result = $manager->_install_skill_nested_dependency_manifest( $owner, 'ddfile.local', 'https://example.invalid/dep.git' );
        ok( $result->{skipped}, 'a dependency already on the install stack is skipped' );
    }
    {
        local *Developer::Dashboard::SkillManager::_install_to_skills_root = sub { return { error => 'inner failure' } };
        is( $manager->_install_skill_nested_dependency_manifest( $owner, 'ddfile.local', 'https://example.invalid/fresh.git' )->{error}, 'inner failure', 'a nested install failure is returned' );
    }
    {
        local *Developer::Dashboard::SkillManager::_install_to_skills_root = sub { return { success => 1 } };
        my $result = $manager->_install_skill_nested_dependency_manifest(
            $owner, 'ddfile.local',
            'https://example.invalid/one.git', 'https://example.invalid/one.git',
        );
        ok( $result->{success} && !$result->{skipped}, 'a repeated dependency is installed only once' );
    }
}

# _copy_tree_contents: a dangling symlink cannot be copied.
{
    my $src = File::Spec->catdir( $home, 'copy-src' );
    make_path($src);
    symlink( File::Spec->catfile( $home, 'no-such-target' ), File::Spec->catfile( $src, 'dangling' ) ) or die $!;
    my $ok = eval { $manager->_copy_tree_contents( $src, File::Spec->catdir( $home, 'copy-dst' ) ); 1 };
    ok( !$ok, '_copy_tree_contents dies when a source entry cannot be copied' );
    like( $@, qr/Unable to copy/, 'the copy failure names the operation' );
}

# _skill_package_runner_prefix: both answers, independent of the uid running the
# suite (the effective uid lookup is stubbed).
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_effective_uid = sub { 65534 };
    is_deeply( [ $manager->_skill_package_runner_prefix ], ['sudo'], 'a non-root user gets the sudo runner prefix' );
    local *Developer::Dashboard::SkillManager::_effective_uid = sub { 0 };
    is_deeply( [ $manager->_skill_package_runner_prefix ], [], 'root gets no runner prefix' );
}
is( $manager->_effective_uid, $>, '_effective_uid reports the real effective uid' );

chdir $orig_cwd;
done_testing;

__END__

=pod

=head1 NAME

t/422-skillmanager-coverage.t - closes remaining branch and condition gaps in Developer::Dashboard::SkillManager

=head1 PURPOSE

Covers marker and ddfile write failures, clone retry cleanup failures, missing
branch guards, silent git failures, existing-checkout branch detection during
install, nested dependency manifest guards, and tree copy failures.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/422-skillmanager-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/422-skillmanager-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/422-skillmanager-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
