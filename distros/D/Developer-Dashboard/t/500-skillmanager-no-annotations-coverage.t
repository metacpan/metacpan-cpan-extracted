#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL overrides must exist before SkillManager is compiled. They
# fail only for exact registered paths/handles, so each I/O failure path runs
# deterministically for any uid (root can still read a mode-0000 file).
our ( %FAIL_OPEN, %FAIL_CLOSE, %FAIL_UNLINK, %FAIL_OPENDIR, %FAIL_CHDIR, %HANDLE_PATH );

BEGIN {
    require Scalar::Util;
    require Symbol;

    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            if ( $FAIL_OPEN{"$_[1]|$_[2]"} ) {
                $! = 13;
                return 0;
            }
            my $ok = CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
            $HANDLE_PATH{ Scalar::Util::refaddr( $_[0] ) } = "$_[1]|$_[2]" if $ok && ref $_[0] && $FAIL_CLOSE{"$_[1]|$_[2]"};
            return $ok;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0] );
    };

    *CORE::GLOBAL::close = sub (;*) {
        return CORE::close() if !@_;
        my $ref = ref $_[0] ? $_[0] : Symbol::qualify_to_ref( $_[0], scalar caller );
        my $key = Scalar::Util::refaddr($ref);
        if ( defined $key && $HANDLE_PATH{$key} ) {
            delete $HANDLE_PATH{$key};
            CORE::close($ref);
            $! = 5;
            return 0;
        }
        return CORE::close($ref);
    };

    *CORE::GLOBAL::unlink = sub {
        if ( @_ == 1 && defined $_[0] && $FAIL_UNLINK{ $_[0] } ) {
            $! = 13;
            return 0;
        }
        return CORE::unlink(@_);
    };

    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };

    # A registered path succeeds N times, then fails.
    *CORE::GLOBAL::chdir = sub (;$) {
        return CORE::chdir() if !@_;
        if ( defined $_[0] && exists $FAIL_CHDIR{ $_[0] } ) {
            if ( $FAIL_CHDIR{ $_[0] }-- <= 0 ) {
                $! = 13;
                return 0;
            }
        }
        return CORE::chdir( $_[0] );
    };
}

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(getcwd);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;

my $SM = 'Developer::Dashboard::SkillManager';

sub spew {
    my ( $path, $content ) = @_;
    my $dir = ( File::Spec->splitpath($path) )[1];
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

my $orig_cwd = getcwd();
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die $!;

my $paths   = Developer::Dashboard::PathRegistry->new( home => $home );
my $manager = $SM->new( paths => $paths );

# install_progress / dependency tasks and the label fallback.
{
    my $skill = File::Spec->catdir( $paths->skills_root, 'tasks' );
    spew( File::Spec->catfile( $skill, 'Makefile' ), "install:\n\t\@true\n" );
    my @ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill) };
    is_deeply( \@ids, ['install_makefile'], 'dependency tasks resolve for a skill with a Makefile' );
    is( $manager->_dependency_progress_label( 'mystery_task', $skill ), 'mystery_task', 'an unknown task id labels as itself' );
}

# install_from_ddfiles: a base dir whose parent does not exist cannot be realpathed.
{
    my $res = $manager->install_from_ddfiles('/nonexistent-s1-root/a/b');
    like( $res->{error}, qr{No ddfile or ddfile\.local found under /nonexistent-s1-root/a/b}, 'an unresolvable base dir falls back to the raw path' );
}

# uninstall/update: a skill path that is defined but not a directory.
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::get_skill_path = sub { return '/nonexistent-s1-skill' };
    like( $manager->uninstall('ghost')->{error}, qr/Skill 'ghost' not found/, 'uninstall reports a non-directory skill path' );
    like( $manager->update('ghost')->{error},    qr/Skill 'ghost' not found/, 'update reports a non-directory skill path' );
}

# enable(): the marker cannot be removed.
{
    my $skill = File::Spec->catdir( $paths->skills_root, 'enableme' );
    spew( File::Spec->catfile( $skill, '.env' ), "VERSION=1\n" );
    my $marker = $manager->_disabled_marker_path($skill);
    spew( $marker, "disabled\n" );
    local $FAIL_UNLINK{$marker} = 1;
    like( $manager->enable('enableme')->{error}, qr/Unable to remove disabled marker/, 'enable reports a marker that cannot be removed' );
}

# root ddfile register/unregister I/O failures and empty-file slurps.
{
    my $h = tempdir( CLEANUP => 1 );
    my $p = Developer::Dashboard::PathRegistry->new( home => $h );
    my $m = $SM->new( paths => $p );
    my $ddfile = File::Spec->catfile( $p->home_runtime_root, 'ddfile' );
    spew( $ddfile, q{} );
    is( $m->_register_root_ddfile_source('https://example.invalid/empty.git')->{registered}, 1, 'an empty ddfile slurps as an empty string' );
    is( $m->_unregister_root_ddfile_source('nothing-here')->{removed}, 0, 'an unregister over a populated ddfile removes nothing' );
    spew( $ddfile, "https://example.invalid/a.git\n" );
    {
        local $FAIL_OPEN{"<|$ddfile"} = 1;
        like( $m->_register_root_ddfile_source('https://example.invalid/b.git')->{error}, qr/Unable to read root ddfile/, 'register reports an unreadable ddfile' );
        like( $m->_unregister_root_ddfile_source('a')->{error}, qr/Unable to read root ddfile/, 'unregister reports an unreadable ddfile' );
    }
    {
        local $FAIL_OPEN{">|$ddfile"} = 1;
        like( $m->_unregister_root_ddfile_source('a')->{error}, qr/Unable to update root ddfile/, 'unregister reports an unwritable ddfile' );
    }
    spew( $ddfile, q{} );
    is( $m->_unregister_root_ddfile_source('a')->{removed}, 0, 'an empty ddfile unregisters nothing' );

    is( $m->_ddfile_source_matches_repo_name( 'plainword', 'x' ), 0, 'a source with no repo name never matches' );
}

# home gitignore I/O failures.
{
    my $h = tempdir( CLEANUP => 1 );
    my $p = Developer::Dashboard::PathRegistry->new( home => $h );
    my $m = $SM->new( paths => $p );
    my $gi = File::Spec->catfile( $p->home_runtime_root, '.gitignore' );
    spew( $gi, q{} );
    {
        local $FAIL_OPEN{"<|$gi"} = 1;
        like( $m->_register_home_gitignore_skill('foo')->{error}, qr/Unable to read home gitignore/, 'unreadable gitignore is reported' );
    }
    {
        local $FAIL_CLOSE{"<|$gi"} = 1;
        like( $m->_register_home_gitignore_skill('foo')->{error}, qr/Unable to close home gitignore/, 'a gitignore read close failure is reported' );
    }
    {
        local $FAIL_OPEN{">>|$gi"} = 1;
        like( $m->_register_home_gitignore_skill('foo')->{error}, qr/Unable to update home gitignore/, 'an unappendable gitignore is reported' );
    }
    {
        local $FAIL_CLOSE{">>|$gi"} = 1;
        like( $m->_register_home_gitignore_skill('foo')->{error}, qr/Unable to close home gitignore/, 'a gitignore append close failure is reported' );
    }
}

# _sync_local_skill_source / _copy_tree: a false-valued exception object.
{
    package S1::FalseError;
    use overload 'bool' => sub { 0 }, '""' => sub { 'false-valued failure' }, fallback => 1;
    package main;

    my $src = tempdir( CLEANUP => 1 );
    spew( File::Spec->catfile( $src, 'a.txt' ), "a\n" );
    my $dst = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'out' );
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::copy = sub { die bless {}, 'S1::FalseError' };
    my $res = $manager->_copy_tree( $src, $dst );
    like( $res->{error}, qr/without rsync: Unknown local skill copy failure/, 'a false-valued exception object reports the generic copy failure' );
}

# open failures on single-file readers.
{
    my $d = tempdir( CLEANUP => 1 );
    my $env = spew( File::Spec->catfile( $d, '.env' ), "VERSION=1\n" );
    {
        local $FAIL_OPEN{"<|$env"} = 1;
        eval { $manager->_local_skill_has_version($d) };
        like( $@, qr/Unable to read \Q$env\E/, '_local_skill_has_version dies on an unreadable .env' );
        eval { $manager->_skill_env_version($d) };
        like( $@, qr/Unable to read \Q$env\E/, '_skill_env_version dies on an unreadable .env' );
    }
    my $apt = spew( File::Spec->catfile( $d, 'aptfile' ), "curl\n" );
    {
        local $FAIL_OPEN{"<|$apt"} = 1;
        eval { $manager->_skill_apt_packages($d) };
        like( $@, qr/Unable to read \Q$apt\E/, '_skill_apt_packages dies on an unreadable aptfile' );
        eval { $manager->_dependency_file_lines($apt) };
        like( $@, qr/Unable to read \Q$apt\E/, '_dependency_file_lines dies on an unreadable file' );
    }
    my $pkg = spew( File::Spec->catfile( $d, 'package.json' ), '{"dependencies":{"x":"1"}}' );
    {
        local $FAIL_OPEN{"<|$pkg"} = 1;
        eval { $manager->_package_json_dependency_specs($pkg) };
        like( $@, qr/Unable to read \Q$pkg\E/, '_package_json_dependency_specs dies on an unreadable file' );
    }
    spew( $pkg, 'null' );
    eval { $manager->_package_json_dependency_specs($pkg) };
    like( $@, qr/Unable to parse \Q$pkg\E/, 'a JSON null document is reported as unparseable' );

    my $mk = spew( File::Spec->catfile( $d, 'Makefile' ), "install:\n\t\@true\n" );
    {
        local $FAIL_OPEN{"<|$mk"} = 1;
        eval { $manager->_makefile_targets($mk) };
        like( $@, qr/Unable to read \Q$mk\E/, '_makefile_targets dies on an unreadable Makefile' );
    }
    {
        local $FAIL_CLOSE{"<|$mk"} = 1;
        eval { $manager->_makefile_targets($mk) };
        like( $@, qr/Unable to close \Q$mk\E/, '_makefile_targets dies when the Makefile cannot be closed' );
    }
    is_deeply( [ $manager->_makefile_targets($mk) ], ['install'], '_makefile_targets still reads targets normally' );

    my $cfg = spew( File::Spec->catfile( $d, 'config', 'config.json' ), '{"a":1}' );
    {
        local $FAIL_OPEN{"<|$cfg"} = 1;
        is_deeply( $manager->_read_skill_config_file($d), {}, 'an unreadable skill config reads as empty' );
    }
}

# opendir failures.
{
    my $d = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $d, $_ ) ) for ( 'cli', 'dashboards', File::Spec->catdir( 'config', 'docker' ) );
    my $cli = File::Spec->catdir( $d, 'cli' );
    my $dash = File::Spec->catdir( $d, 'dashboards' );
    my $dock = File::Spec->catdir( $d, 'config', 'docker' );
    for my $case ( [ $cli, '_cli_command_details' ], [ $dash, '_page_details' ], [ $dock, '_docker_service_details' ], [ $cli, '_sorted_files' ] ) {
        my ( $root, $method ) = @{$case};
        local $FAIL_OPENDIR{$root} = 1;
        eval { $method eq '_sorted_files' ? $manager->$method($root) : $manager->$method($d) };
        like( $@, qr/Unable to read \Q$root\E/, "$method dies on an unreadable directory" );
    }
}

# Timeout / streaming edge cases.
{
    my $out = $manager->_run_streaming_command( command => [ 'sh', '-c', 'echo hi' ], cwd => $home );
    is( $out->{exit}, 0, 'streaming command with a cwd runs' );

    {
        my $other = tempdir( CLEANUP => 1 );
        my $orig_cwd = getcwd();
        local $FAIL_CHDIR{$orig_cwd} = 0;
        eval { $manager->_run_streaming_command( command => ['true'], cwd => $other ) };
        like( $@, qr/Unable to chdir back to \Q$orig_cwd\E after command launch/, 'a failed chdir back is reported' );
    }
    chdir $home or die $!;

    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_drain_ready_handle = sub { die "boom\n" };
        eval { $manager->_run_streaming_command( command => [ 'sh', '-c', 'echo hi; sleep 1' ], timeout_ms => 5000 ) };
        is( $@, "boom\n", 'a non-timeout error inside the timed read loop is rethrown' );
    }

    # A TERM-slow child forces the bounded wait loop to sleep and retry.
    pipe( my $r, my $w ) or die $!;
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if ( !$pid ) {
        close $r;
        $SIG{TERM} = sub { select( undef, undef, undef, 0.15 ); exit 0 };
        syswrite( $w, 'x' );
        close $w;
        sleep 10;
        exit 0;
    }
    close $w;
    sysread( $r, my $buf, 1 );
    ok( $manager->_terminate_streaming_command($pid), 'a slow-to-terminate child is waited for' );
    is( waitpid( $pid, 1 ), -1, 'the slow child was reaped' );
}

# Host detection helpers.
{
    local $ENV{DD_TEST_OS};
    delete $ENV{DD_TEST_OS};
    {
        local $^O = q{};
        is( $manager->_current_os, q{}, 'an empty perl OS name falls through' );
    }
    local $ENV{DD_TEST_OS} = 'linux';
    local $ENV{DD_TEST_DEBIAN_LIKE};
    local $ENV{DD_TEST_ALPINE};
    local $ENV{DD_TEST_FEDORA};
    delete @ENV{qw(DD_TEST_DEBIAN_LIKE DD_TEST_ALPINE DD_TEST_FEDORA)};
    is( $manager->_is_debian_like, ( -f '/etc/debian_version' ? 1 : 0 ), 'debian detection follows the marker file' );
    is( $manager->_is_alpine,      ( -f '/etc/alpine-release' ? 1 : 0 ), 'alpine detection follows the marker file' );
    is( $manager->_is_fedora,      ( -f '/etc/fedora-release' ? 1 : 0 ), 'fedora detection follows the marker file' );
    my @tasks = $manager->_host_progress_system_task_ids;
    ok( scalar(@tasks) <= 1, 'at most one system task is host relevant' );
}

# make resolution when make is not on PATH, and manifest naming default.
{
    my $d = tempdir( CLEANUP => 1 );
    spew( File::Spec->catfile( $d, 'Makefile' ), "install:\n\t\@true\n" );
    my $m = $SM->new( paths => $paths, skip_tests => 1 );
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::command_in_path = sub { return undef };
    my $res = $m->_install_skill_makefile($d);
    ok( $res->{success}, 'make falls back to the bare command name' );

    my $manifest = spew( File::Spec->catfile( $d, 'ddfile.extra' ), "# only a comment\n" );
    my $r = $m->_install_manifest_file( $manifest, skills_root => $d, operations => [] );
    ok( $r->{skipped}, 'a manifest without a manifest_name argument derives it from the path' );
}

# Node dependency copy-merge failure and empty nested streams are exercised by
# the existing suites; the workspace write failure is covered here.
{
    my $h = tempdir( CLEANUP => 1 );
    my $p = Developer::Dashboard::PathRegistry->new( home => $h );
    my $m = $SM->new( paths => $p );
    my $skill = File::Spec->catdir( $h, 'nodeskill' );
    spew( File::Spec->catfile( $skill, 'package.json' ), '{"dependencies":{"x":"1"}}' );
    my $parent = File::Spec->catdir( $p->home_runtime_root, 'cache', 'node-package-installs' );
    make_path($parent);
    no warnings 'redefine';
    my $fixed = File::Spec->catdir( $parent, 'npm-install-FIXED1' );
    make_path($fixed);
    local *Developer::Dashboard::SkillManager::tempdir = sub { return $fixed };
    local $FAIL_OPEN{ '>|' . File::Spec->catfile( $fixed, 'package.json' ) } = 1;
    eval { $m->_install_skill_package_json($skill) };
    like( $@, qr/Unable to write .*package\.json/, 'a workspace package.json that cannot be written dies' );
}

chdir $orig_cwd;
done_testing;

__END__

=pod

=head1 NAME

t/500-skillmanager-no-annotations-coverage.t - covers SkillManager paths that used to carry uncoverable annotations

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives the I/O failure, host-detection, streaming and fallback branches of Developer::Dashboard::SkillManager with CORE::GLOBAL overrides, stubs and real child processes, so none of them needs an uncoverable comment.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with zero uncoverable annotations, and the earlier annotations claimed a root-owned suite could not fail these opens, closes, unlinks and opendirs. Exact-path overrides fail them for any uid.

=head1 WHEN TO USE

Use this file when you change file handling, host detection or the streaming command runner in SkillManager, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/500-skillmanager-no-annotations-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/500-skillmanager-no-annotations-coverage.t

Run this coverage-gap test by itself while editing SkillManager.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/500-skillmanager-no-annotations-coverage.t

Confirm the formerly annotated branches are reported as covered.

=cut
