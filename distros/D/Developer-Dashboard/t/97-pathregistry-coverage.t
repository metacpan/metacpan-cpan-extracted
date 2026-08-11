#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform ();

# Hermetic runtime: isolated home + isolated state root, cwd anchored inside the
# temp home so DD-OOP-LAYER discovery resolves from a controlled tree.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

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
# current_working_directory uses the in-process getcwd implementation while
# preserving explicit constructor overrides and live post-construction chdir.
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
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        delete $ENV{USERNAME};
        is( $paths->_state_root_user, 'user', 'the literal fallback names the state root when nothing else can' );
    }
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

    # Distinct skills for the docker-root runtime filter.
    make_path( File::Spec->catdir( $proj_skills, 'aaa' ) );
    make_path( File::Spec->catdir( $home_skills, 'bbb' ) );

    my @layers = $mreg->skill_layers('ms');
    is( scalar @layers, 1, 'a disabled home skill layer is masked while the enabled deepest layer survives' );

    # include_disabled keeps every layer, exercising the disabled-inclusive path.
    my @all_layers = $mreg->skill_layers( 'ms', include_disabled => 1 );
    is( scalar @all_layers, 2, 'include_disabled surfaces both the enabled and disabled skill layers' );

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
    my $work = File::Spec->catdir( $ext, 'work' );
    make_path( File::Spec->catdir( $work, '.developer-dashboard' ) );
    my $ereg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $work );
    my @layers = $ereg->_ancestor_runtime_layers;
    ok( ( grep { m{\.developer-dashboard} } @layers ),
        'an ancestor .developer-dashboard under the project root is discovered' );

    # cwd outside home and outside any git project: no stop dir, no layers.
    my $orphan = tempdir( CLEANUP => 1 );
    my $oreg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $orphan );
    is_deeply( [ $oreg->_ancestor_runtime_layers ], [],
        'a cwd under neither home nor a project yields no ancestor layers' );
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

done_testing;

__END__

=head1 NAME

t/97-pathregistry-coverage.t - branch and condition coverage closure for the path registry

=head1 PURPOSE

This test drives the guard clauses, environment fallbacks, filesystem error
handling, and layered discovery edges of C<Developer::Dashboard::PathRegistry>
that ordinary runtime callers never reach with malformed or boundary input. It
exists to keep every reachable branch and condition of the path model executed
by the suite so the coverage gate stays honest.

=head1 WHY IT EXISTS

The path registry is the authoritative model for DD-OOP-LAYER discovery, state
root hashing, secure permission tightening, and directory search. Most of its
defensive guards (undef or empty names, absent home runtime trees, blank
environment layer entries, alias-prefix rewrites) are only taken under inputs
that higher-level modules pre-sanitize. Without a dedicated probe those genuine
code paths would appear untested, masking real regressions in the safety net.

=head1 WHEN TO USE

Run this whenever changing runtime-layer discovery, named-path registration,
project-root resolution, skill layer masking, state root derivation, or the
permission-hardening helpers, to confirm the boundary behavior is still exercised
and no branch silently regresses.

=head1 HOW TO USE

Execute it directly with C<perl -Ilib t/97-pathregistry-coverage.t> for a fast
standalone check, or under the coverage harness to confirm the registry keeps
full branch and condition coverage. It constructs isolated temporary homes and
state roots and drives the public and internal helpers with edge inputs.

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
