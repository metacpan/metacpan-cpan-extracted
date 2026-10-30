#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Errno qw(EIO);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PathIdentity ();
use Developer::Dashboard::Config;
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::Platform ();

# Hermetic runtime: isolated home + isolated state root, cwd anchored inside the
# temp home so DD-OOP-LAYER discovery resolves from a controlled tree.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

{
    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = '';
    delete $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    my @provided_roots = map { File::Spec->catdir( $home, $_ ) } qw(home project);
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::runtime_roots = sub {
        die "runtime_roots was recomputed instead of using its supplied snapshot\n";
    };
    is_deeply(
        [ $paths->config_roots( runtime_roots => \@provided_roots ) ],
        [ map { File::Spec->catdir( $_, 'config' ) } @provided_roots ],
        'config_roots derives from an operation-provided runtime-root snapshot',
    );
    is_deeply(
        [ $paths->skills_roots( runtime_roots => \@provided_roots ) ],
        [ map { File::Spec->catdir( $_, 'skills' ) } @provided_roots ],
        'skills_roots derives from an operation-provided runtime-root snapshot',
    );
}

# --------------------------------------------------------------------------
# config overlay: a private writable root augments, rather than replaces, the
# normal layered config chain.
# --------------------------------------------------------------------------
{
    my $overlay = File::Spec->catdir( $home, 'private-config-overlay' );
    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = $overlay;
    delete $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    my @base_roots = map { File::Spec->catdir( $_, 'config' ) } $paths->runtime_roots;
    is( $paths->config_root, $overlay, 'config writes target the private overlay when configured' );
    is_deeply( [ $paths->config_roots ], [ $overlay, @base_roots ], 'private config overlay augments existing config lookup roots at highest priority' );
    is_deeply( [ $paths->config_layers ], [ ( map { File::Spec->catdir( $_, 'config' ) } $paths->runtime_layers ), $overlay ], 'private config overlay is the final inherited config layer' );
    my @overlay_stat = stat $overlay;
    is( $overlay_stat[2] & 0777, 0700, 'private config overlay is restricted to its owner' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = '';
    ok( !defined $paths->_config_overlay_root, 'an explicitly empty config overlay is treated as unset' );
}

{
    my $overlay = File::Spec->catdir( $home, 'missing-config-overlay' );
    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = $overlay;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::_config_overlay_stat = sub { return () };
    dies_like( sub { $paths->_config_overlay_root }, qr/Unable to inspect config overlay directory/,
        'config overlay reports when filesystem metadata cannot be read' );
}

{
    my $overlay = File::Spec->catdir( $home, 'foreign-owner-config-overlay' );
    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = $overlay;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::_config_overlay_stat = sub { return ( 0, 0, 0, 0, $> + 1 ) };
    dies_like( sub { $paths->_config_overlay_root }, qr/Config overlay directory is not owned by the current user/,
        'config overlay refuses a directory reported as owned by another user' );
}

{
    my $target = File::Spec->catdir( $home, 'overlay-symlink-target' );
    my $link   = File::Spec->catdir( $home, 'overlay-symlink' );
    make_path($target);
    symlink $target, $link or die "Unable to create overlay symlink fixture $link: $!";
    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = $link;
    my $error = eval { $paths->config_root; 1 } ? '' : $@;
    like( $error, qr/Config overlay must not be a symbolic link/, 'config overlay refuses a symlink target' );
}

{
    my $overlay = File::Spec->catdir( $home, 'workspace-config-overlay' );
    my $config  = Developer::Dashboard::Config->for_paths($paths);
    $config->save_global_path_alias( 'somewhere', '/tmp/foobar' );

    local $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY} = $overlay;
    $config->save_global_path_alias( 'somewhere', '/workspace' );
    is( $config->path_aliases->{somewhere}, '/workspace', 'container-local overlay alias wins over the inherited host alias' );

    my $host_file = File::Spec->catfile( $home, '.developer-dashboard', 'config', 'config.json' );
    open my $host_fh, '<:raw', $host_file or die "Unable to open $host_file: $!";
    local $/;
    my $host_config = json_decode(<$host_fh>);
    close $host_fh or die "Unable to close $host_file: $!";
    is( $host_config->{path_aliases}{somewhere}, '/tmp/foobar', 'saving the container override leaves the host alias unchanged' );
}

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

# --------------------------------------------------------------------------
# _resolved_home_from_env: HOME, USERPROFILE, HOMEDRIVE/HOMEPATH resolution.
# --------------------------------------------------------------------------
{
    # HOME wins when set and non-empty.
    {
        local %ENV = %ENV;
        $ENV{HOME} = '/env/home';
        is( Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            '/env/home', 'HOME resolves the runtime home' );
    }

    # HOME empty -> USERPROFILE wins.
    {
        local %ENV = %ENV;
        $ENV{HOME}        = '';
        $ENV{USERPROFILE} = '/env/userprofile';
        is( Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            '/env/userprofile', 'USERPROFILE resolves when HOME is empty' );
    }

    # HOME + USERPROFILE absent -> HOMEDRIVE/HOMEPATH combine.
    {
        local %ENV = %ENV;
        delete $ENV{HOME};
        delete $ENV{USERPROFILE};
        $ENV{HOMEDRIVE} = 'C:';
        $ENV{HOMEPATH}  = '\\Users\\dev';
        ok( defined Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            'HOMEDRIVE+HOMEPATH combine into a home path' );
    }

    # HOMEDRIVE defined but empty -> no home.
    {
        local %ENV = %ENV;
        $ENV{HOME}        = '';
        $ENV{USERPROFILE} = '';
        $ENV{HOMEDRIVE}   = '';
        is( Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            undef, 'empty HOMEDRIVE yields no home' );
    }

    # HOMEDRIVE absent entirely -> no home.
    {
        local %ENV = %ENV;
        $ENV{HOME}        = '';
        $ENV{USERPROFILE} = '';
        delete $ENV{HOMEDRIVE};
        delete $ENV{HOMEPATH};
        is( Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            undef, 'absent HOMEDRIVE yields no home' );
    }

    # HOMEDRIVE set but HOMEPATH absent -> no home.
    {
        local %ENV = %ENV;
        $ENV{HOME}        = '';
        $ENV{USERPROFILE} = '';
        $ENV{HOMEDRIVE}   = 'C:';
        delete $ENV{HOMEPATH};
        is( Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            undef, 'HOMEDRIVE without HOMEPATH yields no home' );
    }

    # HOMEDRIVE set but HOMEPATH empty -> no home.
    {
        local %ENV = %ENV;
        $ENV{HOME}        = '';
        $ENV{USERPROFILE} = '';
        $ENV{HOMEDRIVE}   = 'C:';
        $ENV{HOMEPATH}    = '';
        is( Developer::Dashboard::PathRegistry::_resolved_home_from_env(),
            undef, 'HOMEDRIVE with empty HOMEPATH yields no home' );
    }
}

# --------------------------------------------------------------------------
# register/unregister/named_paths.
# --------------------------------------------------------------------------
{
    # Non-hash argument is a no-op.
    is( $paths->register_named_paths('not-a-hash'), $paths, 'non-hash register is a no-op' );

    # Empty-string key is skipped; a real key is registered.
    $paths->register_named_paths( { '' => '/skipme', good => '/tmp/good' } );
    my $named = $paths->named_paths;
    is( $named->{good}, '/tmp/good', 'real named path registered' );
    ok( !exists $named->{''}, 'empty-string named path skipped' );

    # Unregister with undef / empty name is a no-op returning self.
    is( $paths->unregister_named_path(undef), $paths, 'unregister undef name is a no-op' );
    is( $paths->unregister_named_path(''),    $paths, 'unregister empty name is a no-op' );
    $paths->unregister_named_path('good');
    ok( !exists $paths->named_paths->{good}, 'named path removed' );
}

# --------------------------------------------------------------------------
# current_working_directory uses verified PWD before falling back to a live
# directory lookup, while preserving explicit overrides and later chdir.
# --------------------------------------------------------------------------
{
    my $first = File::Spec->catdir( $home, 'cwd-first' );
    my $second = File::Spec->catdir( $home, 'cwd-second' );
    make_path( $first, $second );
    chdir $first or die "Unable to chdir to $first: $!";

    my $getcwd_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::getcwd = sub { $getcwd_calls++; return Cwd::getcwd(); };
    local *Developer::Dashboard::PathRegistry::cwd = sub { die "current_working_directory must not fork pwd\n"; };

    my $reg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => '' );
    is( $reg->current_working_directory, $first, 'empty cwd uses the live in-process working directory' );
    chdir $second or die "Unable to chdir to $second: $!";
    is( $reg->current_working_directory, $second, 'the same registry observes a later process chdir' );
    is( $getcwd_calls, 2, 'the live working directory is read without stale per-instance memoization' );

    my $fixed = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $first );
    is( $fixed->current_working_directory, $first, 'a supplied cwd remains invocation-scoped' );
    is( $getcwd_calls, 2, 'a supplied cwd bypasses live working-directory lookup' );

    local *Developer::Dashboard::PathRegistry::getcwd = sub { die "working directory unavailable\n"; };
    is( $reg->current_working_directory, undef, 'an unavailable working directory remains non-fatal' );

    chdir $home or die "Unable to chdir to $home: $!";
}

is( $paths->cwd, $home, 'the public cwd compatibility accessor delegates to the in-process lookup' );

{
    my $nested = File::Spec->catdir( $home, 'with-dir-getcwd' );
    make_path($nested);
    my $cwd_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::getcwd = sub { $cwd_calls++; return Cwd::getcwd(); };
    local *Developer::Dashboard::PathRegistry::cwd = sub { die "with_dir must not fork pwd\n"; };

    is(
        $paths->with_dir( $nested, sub { return Cwd::getcwd(); } ),
        $nested,
        'with_dir enters the requested directory without using external pwd',
    );
    is( Cwd::getcwd(), $home, 'with_dir restores the original working directory' );
    is( $cwd_calls, 1, 'with_dir snapshots the original directory in-process once' );
}

# --------------------------------------------------------------------------
# project_root_for: undef / empty start dir, and walk-to-root with no .git.
# --------------------------------------------------------------------------
{
    is( $paths->project_root_for(undef), $paths->project_root_for(''),
        'undef and empty start dir both resolve via current working directory' );

    # A start dir with a real .git ancestor resolves to that root.
    my $proot = File::Spec->catdir( $home, 'gitproj' );
    make_path( File::Spec->catdir( $proot, '.git' ) );
    my $deep = File::Spec->catdir( $proot, 'a', 'b' );
    make_path($deep);
    is( $paths->project_root_for($deep), $proot, 'nearest .git ancestor is the project root' );

    # No .git anywhere -> walk terminates at the filesystem root, returns undef.
    is( $paths->project_root_for( File::Spec->catdir( $home, 'no-git-here' ) ),
        undef, 'a tree without .git yields no project root' );

    # current_project_root exercises the memoized identity path.
    $paths->current_project_root;
}

# project_root_for with a current_working_directory that yields undef / empty.
{
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::current_working_directory = sub { undef };
    is( $paths->project_root_for(undef), undef, 'undef working directory yields no project root' );
    local *Developer::Dashboard::PathRegistry::current_working_directory = sub { '' };
    is( $paths->project_root_for(undef), undef, 'empty working directory yields no project root' );
}

# --------------------------------------------------------------------------
# resolve_dir / resolve_any / ls / with_dir.
# --------------------------------------------------------------------------
{
    eval { $paths->resolve_dir(undef) };
    like( $@, qr/Missing path name/, 'resolve_dir undef dies' );
    eval { $paths->resolve_dir('') };
    like( $@, qr/Missing path name/, 'resolve_dir empty dies' );

    is( $paths->resolve_dir('/absolute/path'), '/absolute/path', 'absolute path passes through' );
    ok( -d $paths->resolve_dir('home'), 'logical name resolves via method dispatch' );

    $paths->register_named_paths( { ghost => '/no/such/dir/xyz', realnamed => $home } );
    is( $paths->resolve_dir('realnamed'), $home, 'named alias resolves and expands' );
    eval { $paths->resolve_dir('totally-unknown-name') };
    like( $@, qr/Unknown directory name/, 'unknown name dies' );

    # resolve_any: first existing wins; all-missing yields undef.
    is( $paths->resolve_any( 'ghost', 'home' ), $paths->home, 'resolve_any returns first existing dir' );
    is( $paths->resolve_any('ghost'), undef, 'resolve_any with only missing dirs is undef' );

    # ls over an existing dir, and over a missing named dir.
    my @home_entries = $paths->ls('home');
    ok( scalar(@home_entries) >= 0, 'ls lists an existing directory' );
    is_deeply( [ $paths->ls('ghost') ], [], 'ls of a missing dir is empty' );

    # with_dir runs a callback inside the resolved dir and restores cwd.
    my $seen = $paths->with_dir( 'home', sub { return 'ran' } );
    is( $seen, 'ran', 'with_dir executes the callback and returns its value' );
    my @list = $paths->with_dir( 'home', sub { return ( 1, 2 ) } );
    is_deeply( \@list, [ 1, 2 ], 'with_dir preserves list context' );
    $paths->unregister_named_path('ghost');
    $paths->unregister_named_path('realnamed');
}

# --------------------------------------------------------------------------
# locate_projects: undef roots, missing roots, undef/empty search terms.
# --------------------------------------------------------------------------
{
    my $ws = File::Spec->catdir( $home, 'ws' );
    make_path( File::Spec->catdir( $ws, 'projalpha' ) );
    make_path( File::Spec->catdir( $ws, 'projbeta' ) );
    open my $fh, '>', File::Spec->catfile( $ws, 'loosefile' ) or die $!;
    close $fh;

    my $reg = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ undef, '/no/such/workspace/root', $ws ],
        project_roots   => [],
    );

    my @all = $reg->locate_projects( undef, '', 'proj' );
    is( scalar @all, 2, 'locate_projects matches both proj* directories, skipping empty terms' );
}

# --------------------------------------------------------------------------
# locate_dirs_under: guard cases + recursive walk with a file and a symlink.
# --------------------------------------------------------------------------
{
    is_deeply( [ $paths->locate_dirs_under(undef) ],                  [], 'undef root yields nothing' );
    is_deeply( [ $paths->locate_dirs_under('') ],                    [], 'empty root yields nothing' );
    is_deeply( [ $paths->locate_dirs_under('/no/such/root/at/all') ], [], 'missing root yields nothing' );

    my $tree = File::Spec->catdir( $home, 'tree' );
    make_path( File::Spec->catdir( $tree, 'alpha', 'beta' ) );
    open my $fh, '>', File::Spec->catfile( $tree, 'plainfile' ) or die $!;
    close $fh;
    my $link = File::Spec->catdir( $tree, 'loop' );
    my $have_symlink = eval { symlink( File::Spec->catdir( $tree, 'alpha' ), $link ); 1 };

    my @found = $paths->locate_dirs_under( $tree, undef, '', 'alpha' );
    ok( ( grep { m{alpha} } @found ), 'locate_dirs_under finds a matching descendant' );
}

# _compile_search_regex guards.
{
    is( $paths->_compile_search_regex(undef), undef, 'undef pattern compiles to nothing' );
    is( $paths->_compile_search_regex(''),    undef, 'empty pattern compiles to nothing' );
    ok( ref( $paths->_compile_search_regex('alpha') ) eq 'Regexp', 'valid pattern compiles to a regex' );
}

# --------------------------------------------------------------------------
# runtime_layer_root_for normalizes the candidate once while checking multiple
# runtime roots, preserving the strict symlink-aware comparison contract.
# --------------------------------------------------------------------------
{
    my $fixture = tempdir( CLEANUP => 1 );
    my @roots = map { File::Spec->catdir( $fixture, "layer-$_" ) } 1 .. 2;
    my $unrelated = File::Spec->catdir( $fixture, 'outside', 'candidate' );
    make_path( @roots, $unrelated );
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS} = join "\n", @roots;

    my $reg = Developer::Dashboard::PathRegistry->new(
        home => File::Spec->catdir( $fixture, 'home' ),
        cwd  => $home,
    );
    my $candidate_identity_calls = 0;
    my $path_identity = \&Developer::Dashboard::PathIdentity::_path_identity;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathIdentity::_path_identity = sub {
            ++$candidate_identity_calls if defined $_[0] && $_[0] eq $unrelated;
            goto &$path_identity;
        };
        is( $reg->runtime_layer_root_for($unrelated), '',
            'an unrelated candidate does not belong to a configured runtime layer' );
    }
    is( $candidate_identity_calls, 1,
        'runtime_layer_root_for canonicalizes the candidate only once across all roots' );
}

# --------------------------------------------------------------------------
# is_home_runtime_path guards.
# --------------------------------------------------------------------------
{
    is( $paths->is_home_runtime_path(undef), 0, 'undef path is not a home runtime path' );
    is( $paths->is_home_runtime_path(''),    0, 'empty path is not a home runtime path' );
    is( $paths->is_home_runtime_path( File::Spec->catdir( $home, '.developer-dashboard', 'x' ) ),
        1, 'path under the home runtime tree is recognised' );
    is( $paths->is_home_runtime_path('/etc'), 0, 'unrelated path is not a home runtime path' );
}

# --------------------------------------------------------------------------
# secure_dir_permissions: absent home runtime, absent nested part, real chain.
# --------------------------------------------------------------------------
{
    my $fresh = tempdir( CLEANUP => 1 );
    my $reg   = Developer::Dashboard::PathRegistry->new( home => $fresh );
    my $hr    = File::Spec->catdir( $fresh, '.developer-dashboard' );

    # Home runtime dir does not exist yet: the chmod chain is skipped.
    my $absent = File::Spec->catdir( $hr, 'sub' );
    is( $reg->secure_dir_permissions($absent), $absent,
        'securing under an absent home runtime is a no-op' );

    # Non home-runtime path returns immediately.
    is( $reg->secure_dir_permissions('/tmp'), '/tmp', 'non home-runtime dir is returned untouched' );

    # Build a real nested chain and secure the leaf.
    my $leaf = File::Spec->catdir( $hr, 'real', 'deep' );
    make_path($leaf);
    is( $reg->secure_dir_permissions($leaf), $leaf, 'securing an existing nested chain returns the leaf' );
    is( $reg->secure_dir_permissions($hr), $hr, 'securing the home runtime root itself returns it' );
}

# --------------------------------------------------------------------------
# secure_file_permissions guards + real chmod (default and executable).
# --------------------------------------------------------------------------
{
    my $fresh = tempdir( CLEANUP => 1 );
    my $reg   = Developer::Dashboard::PathRegistry->new( home => $fresh );
    my $hr    = File::Spec->catdir( $fresh, '.developer-dashboard' );
    make_path($hr);

    is( $reg->secure_file_permissions(undef), undef, 'undef file is returned untouched' );
    is( $reg->secure_file_permissions(''),    '',    'empty file is returned untouched' );
    is( $reg->secure_file_permissions('/etc/hosts'), '/etc/hosts',
        'file outside home/state is returned untouched' );

    my $missing = File::Spec->catfile( $hr, 'missing' );
    is( $reg->secure_file_permissions($missing), $missing, 'non-existent home file is returned untouched' );

    my $file = File::Spec->catfile( $hr, 'secret' );
    open my $fh, '>', $file or die $!;
    close $fh;
    is( $reg->secure_file_permissions($file), $file, 'existing home file is hardened' );
    is( $reg->secure_file_permissions( $file, executable => 1 ), $file,
        'existing home file is hardened with the executable bit' );
}

# --------------------------------------------------------------------------
# atomic_write_secure (DD-610): the single write-temp/secure-temp/rename
# helper every DD-599/600/601/602 call site now delegates to, so this is the
# one place that sequence's failure modes need executable proof.
# --------------------------------------------------------------------------
{
    my $fresh = tempdir( CLEANUP => 1 );
    my $reg   = Developer::Dashboard::PathRegistry->new( home => $fresh );

    # Success path: default 0600 and the explicit executable 0700 variant.
    my $target = File::Spec->catfile( $fresh, 'atomic-target' );
    my $tmp    = "$target.pending";
    is( $reg->atomic_write_secure( $tmp, $target, "hello\n" ), $target,
        'atomic_write_secure returns the destination path' );
    ok( !-e $tmp, 'the staging file is gone once the rename lands' );
    ok( -e $target, 'the destination file exists' );
    open my $read_fh, '<', $target or die "Unable to read $target: $!";
    my $written = do { local $/; <$read_fh> };
    close $read_fh;
    is( $written, "hello\n", 'the destination file holds the written content' );
    is( ( stat($target) )[2] & 07777, 0600, 'a default-mode write lands at 0600' );

    my $exec_target = File::Spec->catfile( $fresh, 'atomic-exec-target' );
    my $exec_tmp    = "$exec_target.pending";
    $reg->atomic_write_secure( $exec_tmp, $exec_target, '#!/bin/true', executable => 1 );
    is( ( stat($exec_target) )[2] & 07777, 0700, 'an executable write lands at 0700' );

    # Open failure: the staging path is itself an existing directory.
    my $open_target = File::Spec->catfile( $fresh, 'open-blocked-target' );
    my $open_pending = "$open_target.pending-dir";
    mkdir $open_pending or die "Unable to create $open_pending: $!";
    my $open_err = eval { $reg->atomic_write_secure( $open_pending, $open_target, 'x' ); 1 } ? '' : $@;
    like( $open_err, qr/\AUnable to write \Q$open_pending\E/, 'atomic_write_secure dies when the staging file cannot be opened' );
    rmdir $open_pending or die "Unable to remove $open_pending: $!";

    SKIP: {
        skip 'requires a writable /dev/full to force a write failure', 1
          if !-e '/dev/full' || !-w '/dev/full';

        my $write_target = File::Spec->catfile( $fresh, 'write-blocked-target' );
        my $write_pending = "$write_target.pending-full";
        skip "unable to symlink /dev/full: $!", 1
          if !symlink( '/dev/full', $write_pending );

        # DD-725. The print to /dev/full fails with ENOSPC and atomic_write_secure
        # dies, so $fh goes out of scope unflushed and perl warns about the
        # IMPLICIT close - attributing it to the print on PathRegistry.pm line
        # 1104, not to the explicit close on 1105, which is never reached. That
        # warning is expected here and was leaking to the suite's stderr on every
        # run, on a project where warnings are errors and a permanently noisy
        # stderr trains the reader to skim past the next real one.
        #
        # Tolerated in t/103's shape rather than t/89's: the match names BOTH the
        # close-filehandle phrase and the device clause, and anything else is
        # rethrown. t/89 filters on /unable to close filehandle/i alone, which is
        # safe inside its collect-and-assert structure but would, here, silently
        # absorb a close failure from EIO or EBADF at the same site.
        my $write_err;
        {
            local $SIG{__WARN__} = sub {
                my ($w) = @_;
                return if defined $w && $w =~ /unable to close filehandle.*No space left on device/;
                die $w;
            };
            $write_err = eval { $reg->atomic_write_secure( $write_pending, $write_target, 'x' x 200_000 ); 1 } ? '' : $@;
        }
        like( $write_err, qr/\AUnable to (?:write|close) \Q$write_pending\E/,
            'atomic_write_secure dies when the staging write cannot be flushed to the device' );
        unlink $write_pending if -l $write_pending;
    }

    # chmod failure: a symlink to a root-owned device we cannot chmod.
    my $chmod_target = File::Spec->catfile( $fresh, 'chmod-blocked-target' );
    my $chmod_pending = "$chmod_target.pending-devnull";
    symlink( File::Spec->devnull, $chmod_pending ) or die "Unable to symlink devnull: $!";
    my $chmod_err = eval { $reg->atomic_write_secure( $chmod_pending, $chmod_target, 'x' ); 1 } ? '' : $@;
  SKIP: {
        # CAP_FOWNER, not CAP_DAC_OVERRIDE: chmod is refused to a process that
        # does not own the file, and CAP_FOWNER overrides that. The staging path
        # is a symlink to /dev/null, which this process does not own. Probe with
        # a NO-OP chmod to the device's existing mode - it answers the question
        # and changes nothing.
        my $devnull   = File::Spec->devnull;
        my $null_mode = ( stat $devnull )[2];
        skip 'cannot stat the null device to probe chmod ownership', 1 if !defined $null_mode;
        skip 'this process can chmod a device it does not own, so the chmod failure cannot occur', 1
          if chmod( $null_mode & 07777, $devnull );

        like( $chmod_err, qr/\AUnable to chmod \Q$chmod_pending\E/, 'atomic_write_secure dies when the staging file cannot be chmod-ed' );
    }
    unlink $chmod_pending;

    # Rename failure: the final destination is an existing directory.
    my $rename_target = File::Spec->catdir( $fresh, 'rename-blocked-target' );
    mkdir $rename_target or die "Unable to create $rename_target: $!";
    my $rename_pending = "$rename_target.pending-rename";
    my $rename_err = eval { $reg->atomic_write_secure( $rename_pending, $rename_target, 'x' ); 1 } ? '' : $@;
    like( $rename_err, qr/\AUnable to rename \Q$rename_pending\E to \Q$rename_target\E/,
        'atomic_write_secure dies when the staging file cannot be renamed into place' );
    unlink $rename_pending if -e $rename_pending;
}

# --------------------------------------------------------------------------
# _is_state_path guards, including a failing / empty state_base_root.
# --------------------------------------------------------------------------
{
    is( $paths->_is_state_path(undef), 0, 'undef path is not a state path' );
    is( $paths->_is_state_path(''),    0, 'empty path is not a state path' );
    my $sbase = $paths->state_base_root;
    is( $paths->_is_state_path( File::Spec->catdir( $sbase, 'x' ) ), 1, 'path under state base is a state path' );
    is( $paths->_is_state_path('/etc'), 0, 'unrelated path is not a state path' );

    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::state_base_root = sub { die "no state base\n" };
    is( $paths->_is_state_path('/anything'), 0, 'a failing state base means not a state path' );
    local *Developer::Dashboard::PathRegistry::state_base_root = sub { '' };
    is( $paths->_is_state_path('/anything'), 0, 'an empty state base means not a state path' );
}

# --------------------------------------------------------------------------
# _write_state_metadata guards.
# --------------------------------------------------------------------------
{
    my $dir = tempdir( CLEANUP => 1 );
    is( $paths->_write_state_metadata( undef, '/rt' ), '', 'undef dir writes no metadata' );
    is( $paths->_write_state_metadata( '',    '/rt' ), '', 'empty dir writes no metadata' );
    is( $paths->_write_state_metadata( $dir, undef ), '', 'undef runtime root writes no metadata' );
    is( $paths->_write_state_metadata( $dir, '' ),    '', 'empty runtime root writes no metadata' );
    ok( -e $paths->_write_state_metadata( $dir, '/rt/x' ), 'a valid call writes the metadata file' );

    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = File::Spec->catdir( $dir, 'state-root' );
    my $metadata_paths = Developer::Dashboard::PathRegistry->new( home => $paths->home );
    my $metadata_dir = File::Spec->catdir( $metadata_paths->state_base_root, 'metadata-cache-test' );
    my $secure_calls = 0;
    my $secure_permissions = \&Developer::Dashboard::PathRegistry::secure_file_permissions;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::secure_file_permissions = sub {
        $secure_calls++;
        return $secure_permissions->(@_);
    };
    my $metadata = $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
    is( $secure_calls, 1, 'the first metadata write secures the state file' );
    is( $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ), $metadata,
        'a repeated identical metadata request keeps the same path' );
    is( $secure_calls, 1, 'identical, already-secured metadata is not rewritten' );

    my $metadata_encode_calls = 0;
    my $json_encode_original = \&Developer::Dashboard::PathRegistry::json_encode;
    my $content_cache_dir = File::Spec->catdir( $metadata_dir, 'content-cache' );
    my $content_paths = Developer::Dashboard::PathRegistry->new( home => $paths->home );
    {
        local *Developer::Dashboard::PathRegistry::secure_file_permissions = $secure_permissions;
        local *Developer::Dashboard::PathRegistry::json_encode = sub {
            $metadata_encode_calls++;
            return $json_encode_original->(@_);
        };
        my $content_path = $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-a' );
        $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-a' );
        is( $metadata_encode_calls, 1, 'identical runtime metadata reuses its encoded JSON string' );
        $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
        is( $metadata_encode_calls, 2, 'a changed runtime root regenerates metadata JSON' );
        {
            local $content_paths->{app_name} = 'problem48-cache-test';
            $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
            open my $cache_fh, '<:raw', $content_path or die "Unable to read cached metadata $content_path: $!";
            my $cached_record = json_decode( do { local $/; <$cache_fh> } );
            close $cache_fh or die "Unable to close cached metadata $content_path: $!";
            is_deeply( $cached_record, { runtime_root => '/rt/cache-b', app_name => 'problem48-cache-test' },
                'metadata output reflects the latest application name after a cache-key change' );
            $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
        }
        is( $metadata_encode_calls, 3, 'a changed application name regenerates metadata JSON and then reuses it' );
        {
            local $content_paths->{app_name};
            $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
            $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
            is( $metadata_encode_calls, 4, 'undefined application name is encoded once and then reuses its exact cache entry' );
            open my $cache_fh, '<:raw', $content_path or die "Unable to read cached metadata $content_path: $!";
            my $cached_record = json_decode( do { local $/; <$cache_fh> } );
            close $cache_fh or die "Unable to close cached metadata $content_path: $!";
            is_deeply( $cached_record, { runtime_root => '/rt/cache-b', app_name => undef },
                'metadata output preserves an undefined application name as JSON null' );
        }
        $content_paths->{_state_metadata_json_cache} = {
            runtime_root => '/rt/cache-b',
            app_name     => undef,
            content      => 'stale cached bytes',
        };
        $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
        is( $metadata_encode_calls, 5,
            'a defined application name rejects a cache entry whose application name is undefined' );
        $content_paths->{_state_metadata_json_cache} = {
            runtime_root => undef,
            app_name     => 'developer-dashboard',
            content      => 'stale cached bytes',
        };
        $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
        is( $metadata_encode_calls, 6, 'a hash cache entry without a runtime root is treated as a miss' );
        $content_paths->{_state_metadata_json_cache} = {
            runtime_root => '/rt/cache-b',
            app_name     => 'developer-dashboard',
            content      => undef,
        };
        $content_paths->_write_state_metadata( $content_cache_dir, '/rt/cache-b' );
        is( $metadata_encode_calls, 7, 'a hash cache entry without encoded bytes is treated as a miss' );
    }

    unlink $metadata or die "Unable to remove test metadata $metadata: $!";
    $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
    is( $secure_calls, 2, 'missing metadata is recreated and secured' );

    open my $stale_fh, '>:raw', $metadata or die "Unable to corrupt test metadata $metadata: $!";
    print {$stale_fh} 'stale metadata' or die "Unable to write test metadata $metadata: $!";
    close $stale_fh or die "Unable to close test metadata $metadata: $!";
    $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
    is( $secure_calls, 3, 'changed metadata is rewritten and secured' );
    open my $read_fh, '<:raw', $metadata or die "Unable to read test metadata $metadata: $!";
    my $record = json_decode( do { local $/; <$read_fh> } );
    close $read_fh or die "Unable to close test metadata $metadata: $!";
    is_deeply( $record, { runtime_root => '/rt/x', app_name => $metadata_paths->app_name },
        'rewritten metadata retains the runtime identity payload' );

    chmod 0644, $metadata or die "Unable to loosen test metadata $metadata: $!";
    $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
    is( $secure_calls, 4, 'metadata with loose permissions is rewritten and secured' );
    my @secure_stat = stat $metadata;
    is( $secure_stat[2] & 0777, 0600, 'rewritten state metadata remains owner-only' );

    open my $empty_fh, '>:raw', $metadata or die "Unable to empty test metadata $metadata: $!";
    close $empty_fh or die "Unable to close empty test metadata $metadata: $!";
    chmod 0600, $metadata or die "Unable to secure empty test metadata $metadata: $!";
    $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
    is( $secure_calls, 5, 'an empty existing metadata file is rewritten' );

    {
        require Symbol;
        my $open = \&Developer::Dashboard::PathRegistry::_open_state_metadata_file;
        my $close = \&Developer::Dashboard::PathRegistry::_close_state_metadata_file;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_open_state_metadata_file = sub {
            return $open->(@_) if $_[1] ne '<:raw';
            my $fh = Symbol::gensym();
            tie *{$fh}, 'Local::UnreadableMetadataHandle';
            return $fh;
        };
        local *Developer::Dashboard::PathRegistry::_close_state_metadata_file = sub {
            return 1 if tied *{ $_[0] };
            return $close->(@_);
        };
        $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
        is( $secure_calls, 6, 'metadata with an unreadable empty content stream is rewritten' );
    }

    can_ok( 'Developer::Dashboard::PathRegistry',
        qw(_state_metadata_lstat _open_state_metadata_file _print_state_metadata _close_state_metadata_file) );
    ok( !defined Developer::Dashboard::PathRegistry::_open_state_metadata_file(
            File::Spec->catfile( $dir, 'absent-metadata' ), '<:raw' ),
        'the metadata open helper reports a missing file without hiding the open failure' );

    my $lstat_error = eval {
        local *Developer::Dashboard::PathRegistry::_state_metadata_lstat = sub { $! = EIO; return; };
        $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' );
        1;
    } ? '' : $@;
    like( $lstat_error, qr/Unable to inspect runtime metadata/, 'a non-ENOENT metadata lstat error is reported' );

    unlink $metadata or die "Unable to remove metadata before non-file fixture $metadata: $!";
    mkdir $metadata or die "Unable to create non-file metadata fixture $metadata: $!";
    dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
        qr/Runtime metadata is not a regular file/, 'metadata directories are refused' );
    rmdir $metadata or die "Unable to remove non-file metadata fixture $metadata: $!";
    open my $owner_fh, '>:raw', $metadata or die "Unable to create owner fixture $metadata: $!";
    print {$owner_fh} 'foreign owner' or die "Unable to write owner fixture $metadata: $!";
    close $owner_fh or die "Unable to close owner fixture $metadata: $!";
    chmod 0600, $metadata or die "Unable to secure owner fixture $metadata: $!";
    my $metadata_lstat = \&Developer::Dashboard::PathRegistry::_state_metadata_lstat;
    my @foreign_stat = $metadata_lstat->($metadata);
    $foreign_stat[4] = $> + 1;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_state_metadata_lstat = sub {
            # Keep Perl's cached lstat record valid for the file-type checks,
            # while overriding only the owner field under test.
            my @actual_stat = lstat $_[0];
            $actual_stat[4] = $foreign_stat[4];
            return @actual_stat;
        };
        dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
            qr/Runtime metadata is not owned by the current user/, 'metadata owned by another user is refused' );
    }

    {
        my $open = \&Developer::Dashboard::PathRegistry::_open_state_metadata_file;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_open_state_metadata_file = sub {
            return if $_[1] eq '<:raw';
            return $open->(@_);
        };
        dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
            qr/Unable to read/, 'metadata read-open failures are reported' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_close_state_metadata_file = sub { return; };
        dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
            qr/Unable to close/, 'metadata read-close failures are reported' );
    }
    {
        my $open = \&Developer::Dashboard::PathRegistry::_open_state_metadata_file;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_open_state_metadata_file = sub {
            return if $_[1] eq '>:raw';
            return $open->(@_);
        };
        dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
            qr/Unable to write/, 'metadata write-open failures are reported' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_print_state_metadata = sub { return; };
        dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
            qr/Unable to write runtime metadata/, 'metadata print failures are reported' );
    }
    {
        my $close = \&Developer::Dashboard::PathRegistry::_close_state_metadata_file;
        my $close_calls = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_close_state_metadata_file = sub {
            return $close->(@_) if ++$close_calls == 1;
            return;
        };
        dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
            qr/Unable to close/, 'metadata write-close failures are reported' );
    }

    {
        my $directory = File::Spec->catdir( $dir, 'not-a-metadata-file' );
        mkdir $directory or die "Unable to create metadata open failure fixture $directory: $!";
        ok( !defined Developer::Dashboard::PathRegistry::_open_state_metadata_file( $directory, '>:raw' ),
            'the metadata open helper exposes a write-open failure' );
        rmdir $directory or die "Unable to remove metadata open failure fixture $directory: $!";
    }

    my $target = File::Spec->catfile( $dir, 'metadata-link-target' );
    open my $target_fh, '>:raw', $target or die "Unable to create symlink target $target: $!";
    print {$target_fh} 'do not overwrite' or die "Unable to write symlink target $target: $!";
    close $target_fh or die "Unable to close symlink target $target: $!";
    unlink $metadata or die "Unable to remove test metadata $metadata: $!";
    symlink $target, $metadata or die "Unable to create metadata symlink $metadata: $!";
    dies_like( sub { $metadata_paths->_write_state_metadata( $metadata_dir, '/rt/x' ) },
        qr/Refusing symbolic link for runtime metadata/, 'metadata symlinks are refused' );
    open my $target_read_fh, '<:raw', $target or die "Unable to read symlink target $target: $!";
    my $target_content = do { local $/; <$target_read_fh> };
    close $target_read_fh or die "Unable to close symlink target $target: $!";
    is( $target_content, 'do not overwrite', 'refusing a metadata symlink leaves its target untouched' );
}

# The state-root callers and the metadata writer used to harden the same
# directory consecutively. The writer owns that check, so each route should
# perform it once while preserving metadata creation.
{
    my $state_paths = Developer::Dashboard::PathRegistry->new(
        home => tempdir( CLEANUP => 1 ),
    );
    my $runtime_root = $state_paths->runtime_root;
    my $state_dir = File::Spec->catdir(
        $state_paths->state_base_root,
        $state_paths->_state_root_key($runtime_root),
    );
    my $ensure_count = 0;
    my $ensure_state_dir = \&Developer::Dashboard::PathRegistry::_ensure_state_dir;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_ensure_state_dir = sub {
            my ( $self, $dir ) = @_;
            $ensure_count++ if $dir eq $state_dir;
            return $ensure_state_dir->(@_);
        };
        is( $state_paths->state_root, $state_dir, 'state_root preserves its resolved state directory' );
    }
    is( $ensure_count, 1,
        'state_root and its metadata write harden the state directory only once' );
    ok( -f File::Spec->catfile( $state_dir, 'runtime.json' ),
        'state_root still writes runtime identity metadata' );

    my $other_runtime_root = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'external-runtime' );
    make_path($other_runtime_root);
    my $other_state_dir = File::Spec->catdir(
        $state_paths->state_base_root,
        $state_paths->_state_root_key($other_runtime_root),
    );
    $ensure_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_ensure_state_dir = sub {
            my ( $self, $dir ) = @_;
            $ensure_count++ if $dir eq $other_state_dir;
            return $ensure_state_dir->(@_);
        };
        is( $state_paths->_state_root_for_layer($other_runtime_root), $other_state_dir,
            '_state_root_for_layer preserves its resolved directory' );
    }
    is( $ensure_count, 1,
        '_state_root_for_layer and its metadata write harden the state directory only once' );
    ok( -f File::Spec->catfile( $other_state_dir, 'runtime.json' ),
        '_state_root_for_layer still writes runtime identity metadata' );
}

# --------------------------------------------------------------------------
# _state_root_user across the environment fallback chain.
# --------------------------------------------------------------------------
{
    {
        local %ENV = %ENV;
        $ENV{DD_STATE_ROOT_USER} = 'explicit user!';
        is( $paths->_state_root_user, 'explicit_user_', 'DD_STATE_ROOT_USER wins and is sanitized' );
    }
    {
        local %ENV = %ENV;
        delete $ENV{DD_STATE_ROOT_USER};
        $ENV{USER} = 'plainuser';
        is( $paths->_state_root_user, 'plainuser', 'USER is used when DD_STATE_ROOT_USER is absent' );
    }
    {
        local %ENV = %ENV;
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        $ENV{LOGNAME} = 'loguser';
        is( $paths->_state_root_user, 'loguser', 'LOGNAME is used when USER is absent' );
    }
    {
        local %ENV = %ENV;
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        $ENV{USERNAME} = 'winuser';
        is( $paths->_state_root_user, 'winuser', 'USERNAME is used when the Unix variables are absent' );
    }
    {
        local %ENV = %ENV;
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        delete $ENV{USERNAME};
        ok( length $paths->_state_root_user, 'the passwd database provides a username as the next fallback' );
    }

    # No environment variable names the account and the passwd database cannot
    # answer, which is the non-interactive Windows case, so the literal is used.
    {
        local %ENV = %ENV;
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        delete $ENV{USERNAME};
        delete $paths->{_state_root_user_cache};
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_passwd_user_name = sub { return; };
        is( $paths->_state_root_user, 'user', 'the literal fallback names the state root when nothing else can' );
    }

    {
        local %ENV = %ENV;
        delete @ENV{qw(DD_STATE_ROOT_USER USER LOGNAME USERNAME)};
        delete $paths->{_state_root_user_cache};
        my $lookups = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_passwd_user_name = sub {
            $lookups++;
            return 'passwd-name';
        };
        is( $paths->_state_root_user, 'passwd-name', 'the passwd fallback is sanitized before caching' );
        is( $paths->_state_root_user, 'passwd-name', 'a repeated passwd fallback preserves the resolved name' );
        is( $lookups, 1, 'the passwd database is queried once while the account environment stays unchanged' );
    }

    {
        local %ENV = %ENV;
        delete @ENV{qw(DD_STATE_ROOT_USER USER LOGNAME USERNAME)};
        delete $paths->{_state_root_user_cache};
        local *Developer::Dashboard::PathRegistry::_passwd_user_name = sub { return 'fallback-user' };
        is( $paths->_state_root_user, 'fallback-user', 'an undefined environment tuple is cached' );
        $ENV{USER} = 'environment-user';
        is( $paths->_state_root_user, 'environment-user', 'a newly defined environment value invalidates the cache' );
        is( $paths->_state_root_user, 'environment-user', 'the changed environment tuple is then reused' );
        $ENV{USER} = 'updated-user';
        is( $paths->_state_root_user, 'updated-user', 'a changed defined environment value invalidates the cache' );
        delete $ENV{USER};
        is( $paths->_state_root_user, 'fallback-user', 'an environment value becoming undefined invalidates the cache' );
    }

    {
        local %ENV = %ENV;
        $ENV{USER} = 'cache-shape-user';
        $paths->{_state_root_user_cache} = { environment => 'not-an-array', user => 'stale' };
        is( $paths->_state_root_user, 'cache-shape-user', 'a malformed cache environment is discarded' );
        $paths->{_state_root_user_cache} = 'not-a-hash';
        is( $paths->_state_root_user, 'cache-shape-user', 'a non-hash cache entry is discarded' );
    }
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::_passwd_entry = sub { return ('passwd-name') };
    is( Developer::Dashboard::PathRegistry::_passwd_user_name(), 'passwd-name',
        'the lightweight passwd lookup returns the account name' );

    local *Developer::Dashboard::PathRegistry::_passwd_entry = sub { die "passwd lookup unavailable\\n" };
    is( Developer::Dashboard::PathRegistry::_passwd_user_name(), undef,
        'the lightweight passwd lookup contains platform lookup exceptions' );

    local *Developer::Dashboard::PathRegistry::_passwd_entry = sub { return () };
    is( Developer::Dashboard::PathRegistry::_passwd_user_name(), undef,
        'the lightweight passwd lookup returns undef when no record exists' );
}

# --------------------------------------------------------------------------
# _path_identity guards + resolvable / unresolvable paths.
# --------------------------------------------------------------------------
{
    is( $paths->_path_identity(undef), '', 'undef path has empty identity' );
    is( $paths->_path_identity(''),    '', 'empty path has empty identity' );
    ok( length $paths->_path_identity('/tmp'), 'an existing path resolves to a canonical identity' );
    is( $paths->_path_identity('/no/such/path/zzz'), '/no/such/path/zzz',
        'a non-existent path falls back to a canonical string' );
}

# --------------------------------------------------------------------------
# _same_or_descendant_path across all guard operands.
# --------------------------------------------------------------------------
{
    is( $paths->_same_or_descendant_path( undef, '/a' ), 0, 'undef path is not a descendant' );
    is( $paths->_same_or_descendant_path( '',    '/a' ), 0, 'empty path is not a descendant' );
    is( $paths->_same_or_descendant_path( '/a', undef ), 0, 'undef root has no descendants' );
    is( $paths->_same_or_descendant_path( '/a', '' ),    0, 'empty root has no descendants' );
    is( $paths->_same_or_descendant_path( '/a', '/a' ),  1, 'identical paths are same-or-descendant' );
    is( $paths->_same_or_descendant_path( '/a/b', '/a' ), 1, 'a nested path is a descendant' );
    is( $paths->_same_or_descendant_path( '/a', '/b' ),   0, 'an unrelated path is not a descendant' );
}

# --------------------------------------------------------------------------
# _prefer_reference_style guards and the equivalent-path rewrite.
# --------------------------------------------------------------------------
{
    is( $paths->_prefer_reference_style( undef, '/ref' ), undef, 'undef path is returned unchanged' );
    is( $paths->_prefer_reference_style( '',    '/ref' ), '',    'empty path is returned unchanged' );
    is( $paths->_prefer_reference_style( '/p', undef ), '/p', 'undef reference returns the path' );
    is( $paths->_prefer_reference_style( '/p', '' ),    '/p', 'empty reference returns the path' );

    # Reference is the root: prefix already ends in '/', relative collapses to empty.
    is( $paths->_prefer_reference_style( '/', '/' ), '/', 'root path prefers the reference verbatim' );

    # Path not under the reference is returned unchanged.
    is( $paths->_prefer_reference_style( '/other/place', '/ref/base' ), '/other/place',
        'a path outside the reference is unchanged' );

    # A '..' segment is stripped when restyling under the reference.
    is( $paths->_prefer_reference_style( '/nx/a/../b', '/nx' ),
        File::Spec->catdir( '/nx', 'a', 'b' ),
        'equivalent path is restyled beneath the reference' );
}

# --------------------------------------------------------------------------
# _display_path guards and the /private alias handling.
# --------------------------------------------------------------------------
{
    is( $paths->_display_path(undef), undef, 'undef display path is returned unchanged' );
    is( $paths->_display_path(''),    '',    'empty display path is returned unchanged' );
    is( $paths->_display_path('/home/dev/x'), '/home/dev/x', 'a normal path is returned unchanged' );

    # On Linux /private/tmp/... does not resolve to /tmp/..., so the alias is
    # rejected and the original path is returned.
    my $priv = '/private/tmp/dd-nonexistent-alias-xyz';
    is( $paths->_display_path($priv), $priv, 'an unresolved /private alias leaves the path unchanged' );
}

# --------------------------------------------------------------------------
# _runtime_layers_from_env: blank lines are dropped, real entries survive.
# --------------------------------------------------------------------------
{
    {
        local %ENV = %ENV;
        delete $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS};
        is_deeply( [ $paths->_runtime_layers_from_env ], [], 'no env layers yields nothing' );
    }
    {
        local %ENV = %ENV;
        $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS} = "/layer/one\n\n/layer/two\n";
        is_deeply(
            [ $paths->_runtime_layers_from_env ],
            [ '/layer/one', '/layer/two' ],
            'blank env layer lines are dropped'
        );
    }
}

# A PathRegistry can be retained by a resident process. Runtime-layer memoized
# data must therefore be refreshed after the filesystem topology changes.
{
    my $layer_home    = tempdir( CLEANUP => 1 );
    my $project_root  = tempdir( CLEANUP => 1 );
    my $project_cwd   = File::Spec->catdir( $project_root, 'work' );
    my $project_layer = File::Spec->catdir( $project_root, '.developer-dashboard' );
    make_path( File::Spec->catdir( $project_root, '.git' ), $project_cwd );
    my $resident_paths = Developer::Dashboard::PathRegistry->new(
        home => $layer_home,
        cwd  => $project_cwd,
    );

    {
        local $resident_paths->{_runtime_layer_candidate_scope} = {};
        is_deeply( [ $resident_paths->_existing_layer_dirs_for($project_root) ], [],
            'runtime-layer request scope starts with no existing project layer' );
        make_path($project_layer);
        is_deeply( [ $resident_paths->_existing_layer_dirs_for($project_root) ], [],
            'runtime-layer request scope reuses its directory snapshot' );
    }
    is_deeply( [ $resident_paths->_existing_layer_dirs_for($project_root) ], [$project_layer],
        'a later unscoped operation observes a newly created project layer' );
    rmdir $project_layer or die "Unable to remove project runtime layer $project_layer: $!";

    my $choice_home = tempdir( CLEANUP => 1 );
    my $canonical_runtime = File::Spec->catdir( $choice_home, '.developer-dashboard' );
    my $alias_runtime = File::Spec->catdir( $choice_home, '.d2' );
    my $choice_paths = Developer::Dashboard::PathRegistry->new( home => $choice_home, cwd => $choice_home );
    {
        local $choice_paths->{_runtime_layer_candidate_scope} = {};
        is( $choice_paths->home_runtime_path, $canonical_runtime,
            'runtime choice begins with the canonical name when neither layer exists' );
        make_path($alias_runtime);
        is( $choice_paths->home_runtime_path, $canonical_runtime,
            'runtime choice is stable within one runtime-layer snapshot' );
    }
    is( $choice_paths->home_runtime_path, $alias_runtime,
        'a later operation observes the newly created .d2 runtime layer' );

    for my $invalid_parent ( undef, '', [] ) {
        my $valid = eval {
            $choice_paths->_layer_dir_for($invalid_parent);
            1;
        };
        ok( !$valid, 'runtime layer-name lookup rejects an invalid parent' );
        like( $@, qr/parent path is required/i, 'invalid runtime layer-name parent reports its contract' );
    }

    my $same_home_paths = Developer::Dashboard::PathRegistry->new( home => $choice_home, cwd => $choice_home );
    my ( $same_path_checks, $project_root_checks ) = ( 0, 0 );
    my $same_path = \&Developer::Dashboard::PathRegistry::_same_or_descendant_path;
    my $project_root_method = \&Developer::Dashboard::PathRegistry::current_project_root;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_same_or_descendant_path = sub {
            $same_path_checks++;
            return $same_path->(@_);
        };
        local *Developer::Dashboard::PathRegistry::current_project_root = sub {
            $project_root_checks++;
            return $project_root_method->(@_);
        };
        is_deeply( [ $same_home_paths->_ancestor_runtime_layers ], [],
            'the home directory has no additional ancestor runtime layers' );
    }
    is( $same_path_checks, 0, 'exact home cwd skips canonical ancestry comparisons' );
    is( $project_root_checks, 0, 'exact home cwd skips project-root discovery' );

    for my $invalid_parent ( undef, '', [] ) {
        my $valid_parent = eval {
            $resident_paths->_existing_layer_dirs_for($invalid_parent);
            1;
        };
        ok( !$valid_parent, 'runtime-layer lookup rejects an invalid parent path' );
        like( $@, qr/parent path is required/i, 'invalid runtime-layer parent reports its input contract' );
    }

    my $ancestor_calls = 0;
    my $ancestor_layers = \&Developer::Dashboard::PathRegistry::_ancestor_runtime_layers;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_ancestor_runtime_layers = sub {
            $ancestor_calls++;
            return $ancestor_layers->(@_);
        };
        local $resident_paths->{_runtime_layer_candidate_scope} = {};
        my @first_in_scope  = $resident_paths->runtime_layers;
        my @second_in_scope = $resident_paths->runtime_layers;
        is_deeply( \@second_in_scope, \@first_in_scope,
            'a single runtime-layer scope reuses its immutable result' );
        cmp_ok( $ancestor_calls, '<=', 2,
            'a runtime-layer scope bounds ancestor walks during home-root initialization and repeated reads' );
    }

    my $scoped_root_paths = Developer::Dashboard::PathRegistry->new(
        home => $choice_home,
        cwd  => $choice_home,
    );
    my $runtime_layer_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::runtime_layers = sub {
            $runtime_layer_calls++;
            return ( '/home/.developer-dashboard', '/project/.developer-dashboard' );
        };
        local $scoped_root_paths->{_runtime_layer_candidate_scope} = {};
        is( $scoped_root_paths->runtime_root, '/project/.developer-dashboard',
            'runtime_root returns the deepest layer from the operation snapshot' );
        is( $scoped_root_paths->runtime_root, '/project/.developer-dashboard',
            'runtime_root reuses its result in the same operation snapshot' );
        is( $runtime_layer_calls, 1,
            'repeated runtime_root reads do not re-enter runtime_layers within one operation' );
    }

    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::runtime_layers = sub {
            die "runtime_root should use the precomputed scoped layer list\n";
        };
        local $scoped_root_paths->{_runtime_layer_candidate_scope} = {
            runtime_layers => [ '/home/.developer-dashboard', '/project/.developer-dashboard' ],
        };
        is( $scoped_root_paths->runtime_root, '/project/.developer-dashboard',
            'runtime_root reads the deepest value from a precomputed operation layer list' );
    }

    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::runtime_layers = sub { return; };
        local $scoped_root_paths->{_runtime_layer_candidate_scope} = { runtime_layers => [] };
        ok( !defined $scoped_root_paths->runtime_root,
            'runtime_root preserves undef for an empty precomputed layer list' );
        ok( !defined $scoped_root_paths->runtime_root,
            'an empty deepest-root value is cached only for the active operation' );
    }

    my $unscoped_root_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::runtime_layers = sub {
            $unscoped_root_calls++;
            return $unscoped_root_calls == 1 ? ('/home/.d2') : ('/new-home/.d2');
        };
        is( $scoped_root_paths->runtime_root, '/home/.d2',
            'an unscoped runtime_root reads the current layer inventory' );
        is( $scoped_root_paths->runtime_root, '/new-home/.d2',
            'an unscoped runtime_root does not retain a stale layer result' );
        is( $unscoped_root_calls, 2, 'unscoped runtime_root requests recompute the layer inventory' );
    }

    my @initial_layers = $resident_paths->runtime_layers;
    ok( !( grep { $_ eq $project_layer } @initial_layers ),
        'runtime layer inventory initially excludes a missing project layer' );

    make_path($project_layer);
    my @created_layers = $resident_paths->runtime_layers;
    ok( ( grep { $_ eq $project_layer } @created_layers ),
        'the same PathRegistry object discovers a runtime layer created after its prior lookup' );

    rmdir $project_layer or die "Unable to remove project runtime layer $project_layer: $!";
    my @removed_layers = $resident_paths->runtime_layers;
    ok( !( grep { $_ eq $project_layer } @removed_layers ),
        'the same PathRegistry object drops a project runtime layer removed after its prior lookup' );
}

# --------------------------------------------------------------------------
# _memoize guards.
# --------------------------------------------------------------------------
{
    eval { $paths->_memoize( undef, sub { 1 } ) };
    like( $@, qr/Missing memoization key/, 'undef key dies' );
    eval { $paths->_memoize( '', sub { 1 } ) };
    like( $@, qr/Missing memoization key/, 'empty key dies' );
    eval { $paths->_memoize( 'k', 'not-code' ) };
    like( $@, qr/Missing memoization builder/, 'non-code builder dies' );
    is( $paths->_memoize( 'answer', sub { 42 } ), 42, 'a valid memoize caches and returns the value' );
    is( $paths->_memoize( 'answer', sub { 99 } ), 42, 'a cached key returns the stored value' );
}

# --------------------------------------------------------------------------
# Multi-layer skill discovery: an enabled deepest layer with a disabled home
# layer, plus distinct skills for the docker-root runtime filter.
# --------------------------------------------------------------------------
{
    my $mhome = tempdir( CLEANUP => 1 );
    my $proj  = File::Spec->catdir( $mhome, 'proj' );
    make_path( File::Spec->catdir( $proj, '.developer-dashboard' ) );

    my $mreg = Developer::Dashboard::PathRegistry->new( home => $mhome, cwd => $proj );

    my $home_skills = File::Spec->catdir( $mhome, '.developer-dashboard', 'skills' );
    my $proj_skills = File::Spec->catdir( $proj,  '.developer-dashboard', 'skills' );

    # Same skill in both layers: deepest (proj) enabled, home disabled.
    make_path( File::Spec->catdir( $proj_skills, 'ms' ) );
    make_path( File::Spec->catdir( $home_skills, 'ms' ) );
    open my $df, '>', File::Spec->catfile( $home_skills, 'ms', '.disabled' ) or die $!;
    close $df;

    # A disabled deepest layer masks every enabled inherited layer.
    make_path( File::Spec->catdir( $proj_skills, 'masked' ) );
    make_path( File::Spec->catdir( $home_skills, 'masked' ) );
    open my $masked_marker, '>', File::Spec->catfile( $proj_skills, 'masked', '.disabled' ) or die $!;
    close $masked_marker;

    # Distinct skills for the docker-root runtime filter.
    make_path( File::Spec->catdir( $proj_skills, 'aaa' ) );
    make_path( File::Spec->catdir( $home_skills, 'bbb' ) );

    my @layers = $mreg->skill_layers('ms');
    is( scalar @layers, 1, 'a disabled home skill layer is masked while the enabled deepest layer survives' );

    # include_disabled keeps every layer, exercising the disabled-inclusive path.
    my @all_layers = $mreg->skill_layers( 'ms', include_disabled => 1 );
    is( scalar @all_layers, 2, 'include_disabled surfaces both the enabled and disabled skill layers' );

    my %layer_entries = map { $_->{skill_name} => $_ } $mreg->installed_skill_entries( include_disabled => 1 );
    is_deeply(
        [ map { $_->{skill_root} } $mreg->installed_skill_entries( include_disabled => 1 ) ],
        [ $mreg->installed_skill_roots( include_disabled => 1 ) ],
        'grouped inventory root ordering matches installed_skill_roots for disabled-inclusive lookup',
    );
    is_deeply(
        [ map { $_->{skill_root} } $mreg->installed_skill_entries ],
        [ $mreg->installed_skill_roots ],
        'grouped inventory root ordering matches effective installed_skill_roots',
    );
    is( $layer_entries{ms}{skill_root}, File::Spec->catdir( $proj_skills, 'ms' ),
        'installed skill entry records the deepest selected skill root' );
    is_deeply( $layer_entries{ms}{layers}, [ File::Spec->catdir( $home_skills, 'ms' ), File::Spec->catdir( $proj_skills, 'ms' ) ],
        'installed skill entry provides every layer in home-to-project merge order' );
    is_deeply( $layer_entries{masked}{layers}, [ File::Spec->catdir( $home_skills, 'masked' ), File::Spec->catdir( $proj_skills, 'masked' ) ],
        'include_disabled preserves the disabled deepest layer and inherited layers in precedence order' );
    my %effective_entries = map { $_->{skill_name} => $_ } $mreg->installed_skill_entries;
    is_deeply( $effective_entries{ms}{layers}, [ File::Spec->catdir( $proj_skills, 'ms' ) ],
        'installed skill entry excludes a disabled inherited layer while keeping the enabled deepest layer' );
    ok( !exists $effective_entries{masked}, 'a disabled deepest skill layer masks all inherited layers from effective inventory' );

    my $original_disabled_marker_check = Developer::Dashboard::PathRegistry->can('_skill_is_disabled');
    is( $mreg->_skill_is_disabled(undef), 0, 'disabled-marker helper treats an undefined root as enabled' );
    is( $mreg->_skill_is_disabled(''),    0, 'disabled-marker helper treats an empty root as enabled' );
    my %disabled_marker_checks;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_skill_is_disabled = sub {
            my ( $self, $skill_root ) = @_;
            $disabled_marker_checks{$skill_root}++;
            return $original_disabled_marker_check
              ? $original_disabled_marker_check->(@_)
              : 0;
        };
        my @nested = $mreg->nested_skill_entries(include_disabled => 1);
        ok( @nested, 'disabled-inclusive nested discovery returns the fixture skills' );
        is( $disabled_marker_checks{ File::Spec->catdir( $proj_skills, 'ms' ) }, 1,
            'nested discovery checks each disabled-inclusive top-level marker only once' );
    }

    my $original_skills_roots = \&Developer::Dashboard::PathRegistry::skills_roots;
    my $skills_roots_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::skills_roots = sub {
            $skills_roots_calls++;
            return $original_skills_roots->(@_);
        };
        local $mreg->{_installed_skill_inventory_scope} = {};
        my @nested = $mreg->nested_skill_entries(
            include_disabled              => 1,
            include_config_write_location => 1,
        );
        my @inventory = $mreg->installed_skill_entries( include_disabled => 1 );
        ok( @nested && @inventory, 'nested and layered views both return the fixture skill inventory' );
        is( $skills_roots_calls, 1, 'nested discovery and layered config share one request-scoped skill-root scan' );
    }

    {
        my $original_segment_validator = Developer::Dashboard::PathRegistry->can('validated_path_segments');
        my $segment_validation_calls = 0;
        my $scoped_skills_root_calls = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::validated_path_segments = sub {
            $segment_validation_calls++;
            return $original_segment_validator->(@_);
        };
        local *Developer::Dashboard::PathRegistry::skills_roots = sub {
            $scoped_skills_root_calls++;
            return $original_skills_roots->(@_);
        };
        local $mreg->{_runtime_layer_candidate_scope} = {};
        local $mreg->{_installed_skill_inventory_scope} = {};
        my @first = $mreg->skill_layers('ms');
        my $project_disabled = File::Spec->catfile( $proj_skills, 'ms', '.disabled' );
        open my $marker_fh, '>', $project_disabled or die "Unable to create $project_disabled: $!";
        close $marker_fh or die "Unable to close $project_disabled: $!";
        my @masked = $mreg->skill_layers('ms');
        unlink $project_disabled or die "Unable to remove $project_disabled: $!";
        my @restored = $mreg->skill_layers('ms');
        is( scalar @first, 1, 'scoped skill-layer lookup finds the active project layer' );
        is_deeply( \@masked, [], 'scoped skill-layer reuse still observes a newly-created disable marker' );
        is_deeply( \@restored, \@first, 'scoped skill-layer reuse still observes a removed disable marker' );
        is( $segment_validation_calls, 1, 'request-scoped repeated skill names reuse their validated path segments' );
        is( $scoped_skills_root_calls, 1, 'request-scoped skill-layer lookup reuses its installed directory inventory' );
    }

    # Exercise the bounded request-local segment cache and compatibility path
    # for inventory records created before name_set was added.
    {
        local $mreg->{_installed_skill_inventory_scope} = {
            directories => [
                {
                    skills_root => $proj_skills,
                    names       => ['ms'],
                },
            ],
            skill_layer_segments => {},
        };
        is_deeply( [ $mreg->skill_layers('ms') ], [ File::Spec->catdir( $proj_skills, 'ms' ) ],
            'scoped lookup builds membership from a legacy names-only inventory record' );
        is_deeply( [ $mreg->skill_layers('not-installed') ], [],
            'scoped lookup skips names absent from the inventory membership list' );
        local $mreg->{_installed_skill_inventory_scope}{directories}[0]{names} = undef;
        is_deeply( [ $mreg->skill_layers('ms') ], [],
            'scoped lookup treats a missing legacy names list as empty' );
        is_deeply( [ $mreg->skill_layers( [] ) ], [],
            'scoped lookup safely rejects a reference-valued skill name' );
    }

    {
        my %full_segment_cache = map { ("cached-$_" => ['cached-$_']) } 1 .. 512;
        local $mreg->{_installed_skill_inventory_scope} = {
            directories          => [],
            skill_layer_segments => \%full_segment_cache,
        };
        is_deeply( [ $mreg->skill_layers('new-cache-entry') ], [],
            'scoped lookup remains correct when the bounded segment cache is full' );
        is_deeply( [ $mreg->skill_layers( 'x' x 4097 ) ], [],
            'scoped lookup does not cache an exceptionally long skill name' );
    }

    {
        local $mreg->{_installed_skill_inventory_scope} = {
            directories          => [],
            skill_layer_segments => 'invalid-cache-shape',
        };
        is_deeply( [ $mreg->skill_layers('ms') ], [],
            'scoped lookup remains safe if supplied a non-hash segment-cache value' );
    }
    make_path( File::Spec->catdir( $proj_skills, 'added-after-scope' ) );
    my %after_scope = map { $_->{skill_name} => 1 } $mreg->installed_skill_entries( include_disabled => 1 );
    ok( $after_scope{'added-after-scope'}, 'a later inventory sees a skill added after the request-scoped scan' );

    my $ms_disabled = File::Spec->catfile( $proj_skills, 'ms', '.disabled' );
    open my $ms_disabled_fh, '>', $ms_disabled or die "Unable to create $ms_disabled: $!";
    close $ms_disabled_fh or die "Unable to close $ms_disabled: $!";
    my %disabled_after_request = map { $_ => 1 } $mreg->installed_skill_roots;
    ok( !$disabled_after_request{ File::Spec->catdir( $proj_skills, 'ms' ) },
        'a later inventory sees a newly-created disable marker instead of reusing prior request state' );

    unlink $ms_disabled or die "Unable to remove $ms_disabled: $!";
    my %enabled_after_request = map { $_ => 1 } $mreg->installed_skill_roots;
    ok( $enabled_after_request{ File::Spec->catdir( $proj_skills, 'ms' ) },
        'a later inventory sees a removed disable marker instead of reusing prior request state' );

    my $removed_skill = File::Spec->catdir( $proj_skills, 'added-after-scope' );
    rmdir $removed_skill or die "Unable to remove $removed_skill: $!";
    my %removed_after_request = map { $_ => 1 } $mreg->installed_skill_roots( include_disabled => 1 );
    ok( !$removed_after_request{$removed_skill},
        'a later inventory sees a deleted skill directory instead of reusing prior request state' );

    # skill_layers / skill_root argument guards.
    is_deeply( [ $mreg->skill_layers(undef) ], [], 'skill_layers undef name yields nothing' );
    is_deeply( [ $mreg->skill_layers('') ],    [], 'skill_layers empty name yields nothing' );

    # DD-416: a skill name is joined straight onto the skills root, so a name
    # that carries current/parent directory components, an absolute path, a
    # Windows separator, or a NUL byte must resolve to no layer at all.
    is_deeply( [ $mreg->skill_layers('..') ], [],
        'skill_layers rejects a parent-directory skill name' );
    is_deeply( [ $mreg->skill_layers('.') ], [],
        'skill_layers rejects a current-directory skill name' );
    is_deeply( [ $mreg->skill_layers('ms/../../..') ], [],
        'skill_layers rejects a skill name with an embedded parent traversal' );
    is_deeply( [ $mreg->skill_layers( File::Spec->catdir( $mhome, '.developer-dashboard' ) ) ], [],
        'skill_layers rejects an absolute skill name' );
    is_deeply( [ $mreg->skill_layers('..\\ms') ], [],
        'skill_layers rejects a backslash-separated skill name' );
    is_deeply( [ $mreg->skill_layers("ms\0/x") ], [],
        'skill_layers rejects a NUL-truncated skill name' );

    eval { $mreg->skill_root(undef) };
    like( $@, qr/Missing skill name/, 'skill_root undef name dies' );
    eval { $mreg->skill_root('') };
    like( $@, qr/Missing skill name/, 'skill_root empty name dies' );
    ok( -d $mreg->skill_root('ms'), 'skill_root creates and returns the skill directory' );

    # installed_skill_docker_roots_for_runtime: guards + a real runtime filter.
    is_deeply( [ $mreg->installed_skill_docker_roots_for_runtime(undef) ], [],
        'docker roots for an undef runtime yields nothing' );
    is_deeply( [ $mreg->installed_skill_docker_roots_for_runtime('') ], [],
        'docker roots for an empty runtime yields nothing' );

    my $proj_runtime = File::Spec->catdir( $proj, '.developer-dashboard' );
    my @docker = $mreg->installed_skill_docker_roots_for_runtime($proj_runtime);
    ok( ( grep { m{aaa} } @docker ), 'a skill under the runtime is included in its docker roots' );
    ok( !( grep { m{bbb} } @docker ), 'a skill from another layer is excluded from the runtime docker roots' );
}

# A resident candidate must not retain config bytes across command-like reads.
{
    my $cache_home = tempdir( CLEANUP => 1 );
    my $cache_cwd  = File::Spec->catdir( $cache_home, 'project' );
    my $skill_dir  = File::Spec->catdir( $cache_cwd, '.developer-dashboard', 'skills', 'dynamic' );
    my $config_dir = File::Spec->catdir( $skill_dir, 'config' );
    make_path($config_dir);
    my $config_file = File::Spec->catfile( $config_dir, 'config.json' );
    my $write_config = sub {
        my ($path_value) = @_;
        open my $fh, '>:raw', $config_file or die "Unable to write $config_file: $!";
        print {$fh} Developer::Dashboard::JSON::json_encode(
            { path_aliases => { workspace => $path_value } }
        ) or die "Unable to write config bytes to $config_file: $!";
        close $fh or die "Unable to close $config_file: $!";
    };
    $write_config->('/workspace/first');

    my $cache_paths = Developer::Dashboard::PathRegistry->new(
        home => $cache_home,
        cwd  => $cache_cwd,
    );
    my $cache_config = Developer::Dashboard::Config->for_path_config($cache_paths);
    is( $cache_config->path_aliases->{'dynamic.workspace'}, '/workspace/first',
        'resident-candidate config reads expose the initial skill alias' );

    $write_config->('/workspace/second');
    is( $cache_config->path_aliases->{'dynamic.workspace'}, '/workspace/second',
        'a later read from the same Config object sees replaced skill config bytes' );

    my $new_skill_dir = File::Spec->catdir( $cache_cwd, '.developer-dashboard', 'skills', 'later' );
    make_path( File::Spec->catdir( $new_skill_dir, 'config' ) );
    my $new_config_file = File::Spec->catfile( $new_skill_dir, 'config', 'config.json' );
    open my $new_fh, '>:raw', $new_config_file or die "Unable to write $new_config_file: $!";
    print {$new_fh} Developer::Dashboard::JSON::json_encode(
        { path_aliases => { fresh => '/workspace/new' } }
    ) or die "Unable to write config bytes to $new_config_file: $!";
    close $new_fh or die "Unable to close $new_config_file: $!";
    is( $cache_config->path_aliases->{'later.fresh'}, '/workspace/new',
        'the same Config and PathRegistry objects discover a newly installed skill' );
}

SKIP: {
    my $link_home = tempdir( CLEANUP => 1 );
    my $link_cwd  = File::Spec->catdir( $link_home, 'project' );
    my $runtime_link = File::Spec->catdir( $link_cwd, '.developer-dashboard' );
    my $target_a = File::Spec->catdir( $link_home, 'runtime-a' );
    my $target_b = File::Spec->catdir( $link_home, 'runtime-b' );
    my $write_target = sub {
        my ( $target, $alias_path ) = @_;
        my $config_dir = File::Spec->catdir( $target, 'skills', 'linked', 'config' );
        make_path($config_dir);
        my $config_file = File::Spec->catfile( $config_dir, 'config.json' );
        open my $fh, '>:raw', $config_file or die "Unable to write $config_file: $!";
        print {$fh} Developer::Dashboard::JSON::json_encode(
            { path_aliases => { link => $alias_path } }
        ) or die "Unable to write config bytes to $config_file: $!";
        close $fh or die "Unable to close $config_file: $!";
    };
    make_path($link_cwd);
    $write_target->( $target_a, '/target/a' );
    $write_target->( $target_b, '/target/b' );
    skip 'symlink creation is not available', 2 if !symlink $target_a, $runtime_link;

    my $link_paths = Developer::Dashboard::PathRegistry->new(
        home => $link_home,
        cwd  => $link_cwd,
    );
    my $link_config = Developer::Dashboard::Config->for_path_config($link_paths);
    is( $link_config->path_aliases->{'linked.link'}, '/target/a',
        'a reused Config object reads a skill alias through its initial runtime symlink' );

    unlink $runtime_link or die "Unable to remove runtime symlink $runtime_link: $!";
    symlink $target_b, $runtime_link or die "Unable to retarget runtime symlink $runtime_link: $!";
    is( $link_config->path_aliases->{'linked.link'}, '/target/b',
        'a later read follows a retargeted runtime symlink instead of stale cached config' );
}

# --------------------------------------------------------------------------
# DD-416: validated_path_segments is the shared guard every layered resolver
# uses before an untrusted route or skill name is joined onto a runtime root.
# File::Spec->catfile/catdir do not collapse parent-directory components, so
# each rejected shape here is a real escape from the tree it was anchored to.
# --------------------------------------------------------------------------
{
    my $validate = \&Developer::Dashboard::PathRegistry::validated_path_segments;

    is_deeply( [ $validate->('index') ], ['index'], 'a plain relative segment validates' );
    is_deeply( [ $validate->('nav/index.tt') ], [ 'nav', 'index.tt' ],
        'a nested relative path validates into its segments' );
    is_deeply( [ $validate->('a//b') ], [ 'a', 'b' ],
        'repeated separators collapse exactly as the previous split did' );
    is_deeply( [ $validate->('..info') ], ['..info'],
        'a leading-dot filename that is not a parent reference still validates' );

    is_deeply( [ $validate->(undef) ], [], 'an undef path is rejected' );
    is_deeply( [ $validate->('') ],    [], 'an empty path is rejected' );
    is_deeply( [ $validate->("a\0b") ], [], 'a NUL byte in the path is rejected' );
    is_deeply( [ $validate->('a\\b') ], [], 'a backslash separator in the path is rejected' );
    is_deeply( [ $validate->('/etc/passwd') ], [], 'an absolute path is rejected' );
    is_deeply( [ $validate->('C:/windows/win.ini') ], [],
        'a drive-qualified Windows path is rejected' );
    is_deeply( [ $validate->('..') ],        [], 'a bare parent reference is rejected' );
    is_deeply( [ $validate->('a/../../b') ], [], 'an embedded parent reference is rejected' );
    is_deeply( [ $validate->('.') ],         [], 'a bare current-directory reference is rejected' );
    is_deeply( [ $validate->('a/./b') ],     [], 'an embedded current-directory reference is rejected' );
    is_deeply( [ $validate->('a/') ],        [], 'a trailing separator leaves an empty segment and is rejected' );

    is( scalar( $validate->('nav/index.tt') ), 2,
        'the validator reports its segment count in scalar context' );
    is( scalar( $validate->('..') ), undef,
        'the validator is false in scalar context when the path is rejected' );
}

# --------------------------------------------------------------------------
# project_runtime_root when the project root IS the home runtime directory.
# --------------------------------------------------------------------------
{
    my $ghome = tempdir( CLEANUP => 1 );
    my $gdd   = File::Spec->catdir( $ghome, '.developer-dashboard' );
    make_path( File::Spec->catdir( $gdd, '.git' ) );
    my $greg = Developer::Dashboard::PathRegistry->new( home => $ghome, cwd => $gdd );
    is( $greg->project_runtime_root, undef,
        'a git root that equals the home runtime yields no project runtime root' );

    # A distinct git project with its own runtime yields the project runtime root.
    my $phome = tempdir( CLEANUP => 1 );
    my $prepo = File::Spec->catdir( $phome, 'repo' );
    make_path( File::Spec->catdir( $prepo, '.git' ) );
    make_path( File::Spec->catdir( $prepo, '.developer-dashboard' ) );
    my $preg = Developer::Dashboard::PathRegistry->new( home => $phome, cwd => $prepo );
    is( $preg->project_runtime_root, File::Spec->catdir( $prepo, '.developer-dashboard' ),
        'a project with its own runtime resolves the project runtime root' );
}

# --------------------------------------------------------------------------
# _ancestor_runtime_layers: undef/empty cwd, and the project-root stop branch.
# --------------------------------------------------------------------------
{
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::current_working_directory = sub { undef };
        is_deeply( [ $paths->_ancestor_runtime_layers ], [], 'undef cwd yields no ancestor layers' );
        local *Developer::Dashboard::PathRegistry::current_working_directory = sub { '' };
        is_deeply( [ $paths->_ancestor_runtime_layers ], [], 'empty cwd yields no ancestor layers' );
    }

    # cwd outside home but inside a git project: the project root is the stop dir.
    my $ext = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $ext, '.git' ) );
    my $work = File::Spec->catdir( $ext, 'work', 'nested', 'leaf' );
    make_path( File::Spec->catdir( $work, '.developer-dashboard' ) );
    my $ereg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $work );
    my $original_identity = \&Developer::Dashboard::PathRegistry::_path_identity;
    my $stop_identity_calls = 0;
    my @layers;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_path_identity = sub {
            my ( $self, $path ) = @_;
            $stop_identity_calls++ if defined $path && $path eq $ext;
            return $original_identity->(@_);
        };
        @layers = $ereg->_ancestor_runtime_layers;
    }
    ok( ( grep { m{\.developer-dashboard} } @layers ),
        'an ancestor .developer-dashboard under the project root is discovered' );
    is( $stop_identity_calls, 1,
        'a deep ancestry walk resolves the stop identity once rather than once per parent' );

    # cwd outside home and outside any git project: no stop dir, no layers.
    my $orphan = tempdir( CLEANUP => 1 );
    my $oreg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $orphan );
    is_deeply( [ $oreg->_ancestor_runtime_layers ], [],
        'a cwd under neither home nor a project yields no ancestor layers' );

    my $plain_root = tempdir( CLEANUP => 1 );
    my $plain_work = File::Spec->catdir( $plain_root, 'work', 'nested', 'leaf' );
    make_path( File::Spec->catdir( $plain_root, '.git' ), $plain_work );
    my $plain_paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $plain_work );
    my $plain_root_identity_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_path_identity = sub {
            my ( $self, $path ) = @_;
            $plain_root_identity_calls++ if defined $path && $path eq $plain_root;
            return $original_identity->(@_);
        };
        $plain_paths->_ancestor_runtime_layers;
    }
    is( $plain_root_identity_calls, 1,
        'a deep walk with no runtime layers resolves the stop identity once' );

    # The home runtime root is present in both inputs to the exclusion set
    # when the canonical home runtime directory exists. It should be resolved
    # once while building that set, then once while comparing the candidate.
    my $duplicate_home = tempdir( CLEANUP => 1 );
    my $duplicate_work = File::Spec->catdir( $duplicate_home, 'work' );
    my $duplicate_runtime = File::Spec->catdir( $duplicate_home, '.developer-dashboard' );
    make_path( $duplicate_runtime, $duplicate_work, File::Spec->catdir( $duplicate_home, '.d2' ) );
    my $duplicate_paths = Developer::Dashboard::PathRegistry->new(
        home => $duplicate_home,
        cwd  => $duplicate_work,
    );
    my $duplicate_runtime_identity_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_path_identity = sub {
            my ( $self, $path ) = @_;
            $duplicate_runtime_identity_calls++ if defined $path && $path eq $duplicate_runtime;
            return $original_identity->(@_);
        };
        is_deeply( [ $duplicate_paths->_ancestor_runtime_layers ], [],
            'home runtime directories are excluded from the ancestor-layer result' );
    }
    is( $duplicate_runtime_identity_calls, 2,
        'ancestor discovery canonicalizes the duplicate home runtime path once per distinct use' );
}

{
    my $fixture = tempdir( CLEANUP => 1 );
    my $real_home = File::Spec->catdir( $fixture, 'real-home' );
    my $home_alias = File::Spec->catdir( $fixture, 'home-alias' );
    my $work = File::Spec->catdir( $real_home, 'work' );
    my $work_layer = File::Spec->catdir( $work, '.d2' );
    make_path($work_layer);
    symlink $real_home, $home_alias or die "Unable to create home alias $home_alias: $!";

    my $alias_paths = Developer::Dashboard::PathRegistry->new( home => $home_alias, cwd => $work );
    my $original_identity = \&Developer::Dashboard::PathRegistry::_path_identity;
    my $physical_stop_calls = 0;
    my @layers;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::_path_identity = sub {
            my ( $self, $path ) = @_;
            $physical_stop_calls++ if defined $path && $path eq $real_home;
            return $original_identity->(@_);
        };
        @layers = $alias_paths->_ancestor_runtime_layers;
    }
    ok( ( grep { $_ eq $work_layer } @layers ),
        'ancestor discovery retains a runtime layer below a symlink-aliased home' );
    is( $physical_stop_calls, 1,
        'different spellings still canonicalize once when the walk reaches a symlink-equivalent stop' );
}

# --------------------------------------------------------------------------
# home_cache_root stays anchored at the home layer even when a deeper runtime
# layer is the effective write target, because shell-startup caches belong to
# the user rather than to whichever project the refreshing shell stood in.
# --------------------------------------------------------------------------
{
    my $chome = tempdir( CLEANUP => 1 );
    my $cproj = File::Spec->catdir( $chome, 'repo' );
    make_path( File::Spec->catdir( $cproj, '.git' ) );
    make_path( File::Spec->catdir( $cproj, '.developer-dashboard' ) );
    my $creg = Developer::Dashboard::PathRegistry->new( home => $chome, cwd => $cproj );

    is( $creg->cache_root,
        File::Spec->catdir( $cproj, '.developer-dashboard', 'cache' ),
        'cache_root follows the deepest runtime layer' );
    is( $creg->home_cache_root,
        File::Spec->catdir( $chome, '.developer-dashboard', 'cache' ),
        'home_cache_root stays on the home layer regardless of the deepest layer' );
    ok( -d $creg->home_cache_root, 'home_cache_root creates the home-layer cache directory' );
}

# --------------------------------------------------------------------------
# Exercise the aggregate inventories so the state/metadata write path runs.
# --------------------------------------------------------------------------
{
    my $all = $paths->all_paths;
    ok( $all->{home_runtime_root}, 'all_paths reports the home runtime root' );
    my $aliases = $paths->all_path_aliases;
    ok( $aliases->{home}, 'all_path_aliases reports the home alias' );
    ok( $paths->_state_root_key( $paths->home_runtime_root ), 'state root key hashes the runtime identity' );
}

# An aggregate inventory should resolve and record its shared state root once,
# then derive the collector and indicator children from that exact root.
{
    my $inventory = Developer::Dashboard::PathRegistry->new(
        home => tempdir( CLEANUP => 1 ),
        cwd  => $home,
    );
    my $metadata_writes = 0;
    my $ancestor_walks = 0;
    my $write_metadata = \&Developer::Dashboard::PathRegistry::_write_state_metadata;
    my $ancestor_runtime_layers = \&Developer::Dashboard::PathRegistry::_ancestor_runtime_layers;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::_write_state_metadata = sub {
        $metadata_writes++;
        return $write_metadata->(@_);
    };
    local *Developer::Dashboard::PathRegistry::_ancestor_runtime_layers = sub {
        $ancestor_walks++;
        return $ancestor_runtime_layers->(@_);
    };

    my $all = $inventory->all_paths;
    is( $metadata_writes, 1,
        'all_paths writes shared runtime metadata once for its aggregate inventory' );
    is( $ancestor_walks, 1,
        'all_paths shares one request-scoped ancestor inventory across permission checks' );
    is( $all->{collectors_root}, File::Spec->catdir( $all->{state_root}, 'collectors' ),
        'all_paths derives collector state from its resolved state root' );
    is( $all->{indicators_root}, File::Spec->catdir( $all->{state_root}, 'indicators' ),
        'all_paths derives indicator state from its resolved state root' );
}

# Path identity is shared only inside the explicit aggregate scope; the
# all_paths integration opens that scope and later lookups remain fresh.
{
    my $inventory = Developer::Dashboard::PathRegistry->new(
        home => tempdir( CLEANUP => 1 ),
        cwd  => $home,
    );
    my $resolve_identity = \&Developer::Dashboard::PathIdentity::_path_identity;
    my %identity_calls;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathIdentity::_path_identity = sub {
            my ( $path, %options ) = @_;
            my $key = defined $path ? "defined:$path" : 'undefined';
            $identity_calls{$key}++;
            return $resolve_identity->(@_);
        };
        my $path = $inventory->home;
        my ( $first, $second );
        {
            local $inventory->{_path_identity_scope} = {};
            $first  = $inventory->_path_identity($path);
            $second = $inventory->_path_identity($path);
        }
        is( $first, $second, 'scoped path identity reuse preserves the normalized value' );
        is( $identity_calls{"defined:$path"}, 1,
            'the same path is normalized once during an explicit aggregate scope' );
        $inventory->_path_identity($path);
        is( $identity_calls{"defined:$path"}, 2,
            'path identity is normalized afresh after the explicit scope ends' );
        {
            local $inventory->{_path_identity_scope} = {};
            is( $inventory->_path_identity(undef), '',
                'undefined path identity keeps the historical empty result' );
            is( $inventory->_path_identity(undef), '',
                'undefined path identity can use the scoped cached empty result' );
        }
        is( $identity_calls{undefined}, 1,
            'undefined path input is normalized once in a cache scope' );

        my $all_paths_scope_calls = 0;
        my $original_registry_identity = \&Developer::Dashboard::PathRegistry::_path_identity;
        local *Developer::Dashboard::PathRegistry::_path_identity = sub {
            my ($self) = @_;
            $all_paths_scope_calls++ if ref( $self->{_path_identity_scope} ) eq 'HASH';
            return $original_registry_identity->(@_);
        };
        my $all = $inventory->all_paths;
        ok( $all->{state_root}, 'all_paths preserves the state-root result' );
        cmp_ok( $all_paths_scope_calls, '>', 0,
            'all_paths opens the path-identity cache only for its aggregate work' );
    }
}

# A request-local permission inventory must not survive into a later call.
{
    my $fixture = tempdir( CLEANUP => 1 );
    my $repo = File::Spec->catdir( $fixture, 'repo' );
    my $work = File::Spec->catdir( $repo, 'work' );
    make_path( File::Spec->catdir( $repo, '.git' ), $work );
    my $registry = Developer::Dashboard::PathRegistry->new(
        home => File::Spec->catdir( $fixture, 'home' ),
        cwd  => $work,
    );

    $registry->all_paths;
    my $new_layer = File::Spec->catdir( $repo, '.d2' );
    make_path($new_layer);
    is(
        $registry->runtime_layer_root_for( File::Spec->catfile( $new_layer, 'config', 'config.json' ) ),
        $new_layer,
        'a later security lookup discovers a runtime layer created after all_paths completed',
    );
}


# DD-616: File.pm and Folder.pm each carried their own byte-identical copy of the
# alias cache key computation. The shared implementation lives here, on the registry
# whose roots it reads, because both callers already load this module and the value
# is derived entirely from a paths object.
{
    can_ok( 'Developer::Dashboard::PathRegistry', 'alias_cache_key' );

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $key   = Developer::Dashboard::PathRegistry::alias_cache_key($paths);
    ok( defined $key, 'alias_cache_key returns a defined value for a real registry' );

    is( Developer::Dashboard::PathRegistry::alias_cache_key(undef), '',
        'alias_cache_key is empty for an undefined registry' );
    is( Developer::Dashboard::PathRegistry::alias_cache_key('not-an-object'), '',
        'alias_cache_key is empty for an unblessed scalar' );
    is( Developer::Dashboard::PathRegistry::alias_cache_key( {} ), '',
        'alias_cache_key is empty for an unblessed hash reference' );
}

# --------------------------------------------------------------------------
# DD-870: resolve_dir's method-name fallback must dispatch ONLY to the
# allowlisted no-arg path getters, never to any other public method (the
# constructor, mutators, or plural/hash-returning inventory methods).
# --------------------------------------------------------------------------
{
    my $reg = Developer::Dashboard::PathRegistry->new( home => $home );

    # Non-getter public methods must be refused, not dispatched.
    for my $bad (
        qw(all_paths all_path_aliases new new_from_all_folders
        register_named_paths unregister_named_path named_paths
        runtime_roots dashboards_roots resolve_dir resolve_any)
      )
    {
        dies_like( sub { $reg->resolve_dir($bad) },
            qr/Unknown directory name/, "resolve_dir refuses to dispatch to '$bad'" );
    }

    # All 26 legitimate no-arg path getters must still resolve by name.
    for my $good (
        qw(home runtime_root home_runtime_root home_runtime_path
        project_runtime_root state_root state_base_root cache_root
        home_cache_root logs_root dashboards_root bookmarks bookmarks_root
        cli_root skills_root collectors_root indicators_root sessions_root
        temp_root config_root auth_root repo_dashboard_root users_root
        current_project_root current_working_directory cwd)
      )
    {
        my $direct   = $reg->$good();
        my $resolved = $reg->resolve_dir($good);
        is( $resolved, $direct, "resolve_dir still resolves allowlisted getter '$good'" );
    }
}

{
    package Local::UnreadableMetadataHandle;

    sub TIEHANDLE { return bless {}, $_[0] }
    sub READLINE  { return }
}

package main;

done_testing;

__END__

=head1 NAME

t/97-pathregistry-coverage.t - branch and condition coverage closure for the path registry

=head1 PURPOSE

This test drives the guard clauses, environment fallbacks, filesystem error
handling, and layered discovery edges of C<Developer::Dashboard::PathRegistry>
that ordinary runtime callers never reach with malformed or boundary input. It
exists to keep every reachable branch and condition of the path model executed
by the suite so the coverage gate stays honest. It also verifies that aggregate
path output resolves and writes shared state metadata once, and that passwd
fallback errors remain contained without loading platform helpers. It also
drives metadata I/O failures and checks that cached usernames are invalidated
whenever any of the four account environment values changes, including
transitions to or from undef. Its runtime-layer fixture verifies that an
explicit request scope retains one filesystem existence snapshot while a later
unscoped lookup sees a newly created layer. Invalid undefined, empty, and
reference-valued parent paths are rejected before directory discovery.

=head1 WHY IT EXISTS

The path registry is the authoritative model for DD-OOP-LAYER discovery, state
root hashing, secure permission tightening, passwd fallback, and directory search. Most of its
defensive guards (undef or empty names, absent home runtime trees, blank
environment layer entries, alias-prefix rewrites) are only taken under inputs
that higher-level modules pre-sanitize. Without a dedicated probe those genuine
code paths would appear untested, masking real regressions in the safety net.

=head1 WHEN TO USE

Run this whenever changing runtime-layer discovery, named-path registration,
project-root resolution, skill layer masking, state root derivation, or the
permission-hardening helpers, to confirm the boundary behavior is still exercised
and no branch silently regresses. Its skill fixtures also verify that the
grouped installed-skill inventory preserves layer order and disable masking.
Use it when changing state metadata validation,
metadata open/write/close handling, or the per-registry account-name cache too.
The aggregate path inventory also checks that permission-layer discovery is
shared only during that call and that later operations observe new layers.
The installed-skill inventory verifies nested discovery and layered metadata
reuse one directory listing only during a scoped operation, while a later
operation sees a newly created skill.
Later inventory calls also verify live creation/removal of disable markers and
skill-directory deletion, which are required freshness cases for any future
resident cache. A same-object Config fixture also verifies replaced skill
config bytes and newly installed skill aliases are visible on later reads.
Where symlink creation is supported, the same objects also follow a runtime
symlink retargeted between reads.
The tied metadata stream also exercises the failed-read/undefined-content path,
and the cache fixture changes one environment value between two defined values.
The multi-root fixture also guards the path-ownership check against redundant
candidate canonicalization while preserving independently checked runtime
root identities.
The resident-process fixture proves that runtime-layer lookup refreshes after
project layer creation/removal outside an operation scope, while repeated
lookups inside one scope share one ancestor walk and one per-parent layer
directory-existence snapshot.

=head1 HOW TO USE

Execute it directly with C<perl -Ilib t/97-pathregistry-coverage.t> for a fast
standalone check, or under the coverage harness to confirm the registry keeps
full branch and condition coverage. It constructs isolated temporary homes and
state roots and drives the public and internal helpers with edge inputs. The
metadata fixtures cover exact repeats, empty and stale content, loose mode,
symlinks, directories, foreign ownership, lstat/open/print/close failures, and
username cache environment changes.

=head1 WHAT USES IT

The repository coverage gate and the ordinary C<prove -lr t> correctness run
consume this file; it complements the broader unit tests in t/07-core-units.t
that cover the registry's mainline behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/97-pathregistry-coverage.t

Run the coverage closure test standalone and confirm every assertion passes with
no warnings.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run the whole suite under the coverage gate and confirm the path registry stays
at full branch and condition coverage.

=cut
