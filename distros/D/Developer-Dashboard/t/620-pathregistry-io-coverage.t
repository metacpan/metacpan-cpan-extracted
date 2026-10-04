#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL overrides must exist before the module under test is
# compiled. They fail only for exact paths registered in the %FAIL_* tables,
# so every I/O error branch runs deterministically for any uid (a chmod-based
# unreadable file does not fail for root).
our ( %FAIL_OPEN, %FAIL_OPENDIR, %FAIL_CHDIR, %FAIL_CHMOD, %FAIL_CLOSE, %CLOSE_HANDLE );

BEGIN {
    require Scalar::Util;
    require Symbol;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_OPEN{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        my $ok = @_ == 2 ? CORE::open( $_[0], $_[1] ) : CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
        if ( $ok && @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_CLOSE{ $_[2] } && ref $_[0] ) {
            $CLOSE_HANDLE{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $ok;
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $handle = @_ ? $_[0] : undef;
        return CORE::close() if !defined $handle;
        $handle = Symbol::qualify_to_ref( $handle, caller ) if !ref $handle;
        if ( $CLOSE_HANDLE{ Scalar::Util::refaddr($handle) } ) {
            delete $CLOSE_HANDLE{ Scalar::Util::refaddr($handle) };
            CORE::close($handle);
            $! = 5;
            return 0;
        }
        return CORE::close($handle);
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::chdir = sub (;$) {
        if ( @_ && defined $_[0] && $FAIL_CHDIR{ $_[0] } ) {
            $! = 13;
            return 0;
        }
        return @_ ? CORE::chdir( $_[0] ) : CORE::chdir();
    };
    *CORE::GLOBAL::chmod = sub (@) {
        my ( $mode, @files ) = @_;
        return 0 if grep { defined $_ && $FAIL_CHMOD{$_} } @files;
        return CORE::chmod( $mode, @files );
    };
}

use Test::More;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
delete $ENV{DEVELOPER_DASHBOARD_CONFIG_DIRS};
chdir $home or die "Unable to chdir to $home: $!";
my $start = getcwd();

sub new_paths { return Developer::Dashboard::PathRegistry->new( home => $home, @_ ) }
sub error_of  { my ($code) = @_; return eval { $code->(); 1 } ? '' : $@ }

# --- named path registry guards -------------------------------------------
{
    my $paths = new_paths();
    $paths->register_named_paths( { '' => '/ignored', real => '/real' } );
    is_deeply( $paths->named_paths, { real => '/real' }, 'an empty alias name is skipped on registration' );
    delete $paths->{named_paths};
    is_deeply( $paths->named_paths, {}, 'named_paths tolerates a missing alias table' );
}

# --- alias_cache_key with an object whose accessors die --------------------
{
    package Local::DyingPaths;
    sub new { bless {}, shift }
    sub current_project_root { die "no root\n" }
    sub runtime_roots        { die "no roots\n" }
    package main;
    is( Developer::Dashboard::PathRegistry::alias_cache_key( Local::DyingPaths->new ), '', 'alias_cache_key degrades to an empty key when accessors die' );
}

# --- runtime_layers skips an empty root ------------------------------------
{
    my $paths = new_paths();
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::_runtime_layers_from_env = sub { return ('') };
    my @layers = $paths->runtime_layers;
    ok( !grep( { $_ eq '' } @layers ), 'runtime_layers drops an empty layer root' );
}

# --- skill roots: unreadable skills dirs, and per-runtime docker roots -----
{
    my $paths = new_paths();
    my $root  = File::Spec->catdir( $home, '.developer-dashboard' );
    my $skill = File::Spec->catdir( $root, 'skills', 'alpha' );
    make_path( File::Spec->catdir( $skill, 'config', 'docker' ), File::Spec->catdir( $skill, 'skills', 'nested' ) );
    my $skills_root = File::Spec->catdir( $root, 'skills' );

    local $FAIL_OPENDIR{$skills_root} = 1;
    like( error_of( sub { $paths->installed_skill_roots } ), qr/Unable to read \Q$skills_root\E/, 'installed_skill_roots dies when a skills root cannot be opened' );
    delete $FAIL_OPENDIR{$skills_root};

    my $nested_root = File::Spec->catdir( $skill, 'skills' );
    local $FAIL_OPENDIR{$nested_root} = 1;
    my @entries = $paths->nested_skill_entries;
    is( scalar(@entries), 1, 'an unreadable nested skills tree is skipped' );
    delete $FAIL_OPENDIR{$nested_root};

    my $project = File::Spec->catdir( $home, 'proj' );
    my $pskill  = File::Spec->catdir( $project, '.developer-dashboard', 'skills', 'beta' );
    make_path( File::Spec->catdir( $pskill, 'config', 'docker' ), File::Spec->catdir( $project, '.git' ) );
    chdir $project or die "chdir: $!";
    my $layered = new_paths();
    my @all     = $layered->installed_skill_roots;
    ok( @all >= 2, 'both layers contribute skills' );
    my @only_home = $layered->installed_skill_docker_roots_for_runtime($root);
    is_deeply( [ grep { /beta/ } @only_home ], [], 'docker roots for one runtime layer exclude other layers' );
    ok( scalar( grep {/alpha/} @only_home ), 'docker roots for one runtime layer include its own skills' );
    chdir $start or die "chdir: $!";
}

# --- state metadata open/close failures ------------------------------------
{
    my $paths = new_paths();
    my $dir   = tempdir( CLEANUP => 1 );
    my $file  = File::Spec->catfile( $dir, 'runtime.json' );
    {
        local $FAIL_OPEN{$file} = 1;
        like( error_of( sub { $paths->_write_state_metadata( $dir, $home ) } ), qr/Unable to write \Q$file\E/, '_write_state_metadata dies when it cannot open the file' );
    }
    {
        local $FAIL_CLOSE{$file} = 1;
        like( error_of( sub { $paths->_write_state_metadata( $dir, $home ) } ), qr/Unable to close \Q$file\E/, '_write_state_metadata dies when close fails' );
    }
    ok( $paths->_write_state_metadata( $dir, $home ), 'metadata writes normally without injected failures' );
    {
        my $tmp = File::Spec->catfile( $dir, 'pending.tmp' );
        local $FAIL_CLOSE{$tmp} = 1;
        like( error_of( sub { $paths->atomic_write_secure( $tmp, File::Spec->catfile( $dir, 'final.txt' ), 'x' ) } ), qr/Unable to close \Q$tmp\E/, 'atomic_write_secure dies when close fails' );
    }
}

# --- ls / with_dir ---------------------------------------------------------
{
    my $paths = new_paths();
    my $dir   = tempdir( CLEANUP => 1 );
    {
        local $FAIL_OPENDIR{$dir} = 1;
        like( error_of( sub { $paths->ls($dir) } ), qr/Unable to open \Q$dir\E/, 'ls dies when the directory cannot be opened' );
    }
    {
        local $FAIL_CHDIR{$dir} = 1;
        like( error_of( sub { $paths->with_dir( $dir, sub { 1 } ) } ), qr/Unable to chdir to \Q$dir\E/, 'with_dir dies when chdir fails' );
    }
    {
        my $old = getcwd();
        local $FAIL_CHDIR{$old} = 1;
        like( error_of( sub { $paths->with_dir( $dir, sub { 1 } ) } ), qr/Unable to restore cwd to \Q$old\E/, 'with_dir dies when restoring the cwd fails' );
        delete $FAIL_CHDIR{$old};
        chdir $start or die "chdir: $!";
    }
}

# --- locate_projects / locate_dirs_under -----------------------------------
{
    my $work = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $work, 'one', 'two' ) );
    my $paths = new_paths( workspace_roots => [$work], project_roots => [] );
    {
        local $FAIL_OPENDIR{$work} = 1;
        is_deeply( [ $paths->locate_projects('one') ], [], 'locate_projects skips an unreadable root' );
    }
    {
        my $sub = File::Spec->catdir( $work, 'one' );
        local $FAIL_OPENDIR{$sub} = 1;
        my @found = $paths->locate_dirs_under($work);
        ok( !grep( { m{/two\z} } @found ), 'locate_dirs_under does not descend into an unreadable directory' );
        ok( scalar( grep { m{/one\z} } @found ), 'locate_dirs_under still reports the unreadable directory itself' );
    }
    my @all = $paths->locate_dirs_under($work);
    ok( scalar( grep { m{/two\z} } @all ), 'locate_dirs_under descends when readable' );
}

# --- chmod failures --------------------------------------------------------
{
    my $paths = new_paths();
    my $root  = File::Spec->catdir( $home, '.developer-dashboard' );
    my $sub   = File::Spec->catdir( $root, 'cfg' );
    make_path($sub);
    {
        local $FAIL_CHMOD{$root} = 1;
        like( error_of( sub { $paths->secure_dir_permissions($sub) } ), qr/Unable to chmod \Q$root\E to 0700/, 'secure_dir_permissions dies when the layer root chmod fails' );
    }
    {
        local $FAIL_CHMOD{$sub} = 1;
        like( error_of( sub { $paths->secure_dir_permissions($sub) } ), qr/Unable to chmod \Q$sub\E to 0700/, 'secure_dir_permissions dies when a nested chmod fails' );
    }
    my $file = File::Spec->catfile( $sub, 'f.txt' );
    open my $fh, '>', $file or die "write: $!";
    close $fh;
    {
        local $FAIL_CHMOD{$file} = 1;
        like( error_of( sub { $paths->secure_file_permissions($file) } ), qr/Unable to chmod \Q$file\E to 0600/, 'secure_file_permissions dies when chmod fails' );
        like( error_of( sub { $paths->_chmod_pending( $file, 0600 ) } ), qr/Unable to chmod \Q$file\E to 0600/, '_chmod_pending dies when chmod fails' );
    }
    {
        local $FAIL_CHMOD{$sub} = 1;
        like( error_of( sub { $paths->_ensure_state_dir($sub) } ), qr/Unable to chmod \Q$sub\E to 0700/, '_ensure_state_dir dies when chmod of an existing dir fails' );
    }
}

done_testing;

__END__

=pod

=head1 NAME

t/620-pathregistry-io-coverage.t - forces the I/O failure and guard branches of Developer::Dashboard::PathRegistry

=head1 PURPOSE

Test file in the Developer Dashboard codebase. forces the I/O failure and guard branches of Developer::Dashboard::PathRegistry

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate with zero uncoverable annotations needs every PathRegistry open, opendir, chdir, close and chmod failure branch exercised for any uid, including root.

=head1 WHEN TO USE

Use this file when you change PathRegistry I/O handling, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/620-pathregistry-io-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/620-pathregistry-io-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/620-pathregistry-io-coverage.t

Confirm the targeted branches are reported as covered.

=cut
