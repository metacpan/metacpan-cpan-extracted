#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);

use lib 'lib';

use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::JSON qw(json_encode);

my $EL = 'Developer::Dashboard::EnvLoader';

# Warnings are fatal in this repository: collect any and assert none escaped.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home; config layers resolve from the cwd,
# so we chdir into the temp home before building any registry.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

# write_file($path, $content)
# Creates any missing parent directories and writes one fixture file.
# Input: absolute file path and file body.
# Output: the file path.
sub write_file {
    my ( $path, $content ) = @_;
    make_path( dirname($path) );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

{
    package Local::MockPaths;

    # new(%args)
    # Builds a minimal path registry stand-in for _plain_directory_layers.
    # Input: cwd, home, and project_root values.
    # Output: blessed mock object.
    sub new { my ( $class, %args ) = @_; return bless {%args}, $class; }

    # current_working_directory()
    # Returns the configured invocation cwd.
    # Input: none.
    # Output: cwd value or undef.
    sub current_working_directory { return $_[0]->{cwd} }

    # home()
    # Returns the configured home directory.
    # Input: none.
    # Output: home value.
    sub home { return $_[0]->{home} }

    # current_project_root()
    # Returns the configured project root.
    # Input: none.
    # Output: project root value or undef.
    sub current_project_root { return $_[0]->{project_root} }
}

{
    package Local::EnvCov;

    # hello()
    # Static env-function helper returning a fixed value.
    # Input: none.
    # Output: fixed string.
    sub hello { return 'hi' }

    # boom()
    # Static env-function helper that always dies for failure coverage.
    # Input: none.
    # Output: never returns; dies.
    sub boom { die "boom\n" }
}

# --- Top-level entry guards ------------------------------------------------

{
    my $err = eval { $EL->load_runtime_layers; 1 } ? '' : $@;
    like( $err, qr/Missing paths/, 'load_runtime_layers dies when paths are missing' );
    my $scope_err = eval {
        $EL->load_runtime_layers(
            paths => Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home ),
            scope => 'invalid',
        );
        1;
    } ? '' : $@;
    like( $scope_err, qr/Unsupported runtime environment scope 'invalid'/, 'load_runtime_layers rejects an unknown scope explicitly' );
    my $skill_runtime_err = eval { $EL->load_skill_runtime_layers; 1 } ? '' : $@;
    like( $skill_runtime_err, qr/Missing paths/, 'load_skill_runtime_layers dies when paths are missing' );
}

{
    local %ENV                                     = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}      = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT   = ();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $loaded = $EL->load_runtime_layers( paths => $paths );
    is( ref($loaded), 'ARRAY', 'load_runtime_layers returns an ordered file list for a valid registry' );
    my $skill_runtime_loaded = $EL->load_skill_runtime_layers( paths => $paths );
    is( ref($skill_runtime_loaded), 'ARRAY', 'load_skill_runtime_layers defaults to an empty skill list' );
}

{
    my $scope_home    = tempdir( CLEANUP => 1 );
    my $scope_project = File::Spec->catdir( $scope_home, 'project' );
    my $scope_skill   = File::Spec->catdir( $scope_home, 'skill' );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $scope_home, cwd => $scope_project );
    my @files = (
        [ File::Spec->catfile( $scope_home, '.env' ), "DD_T87_HOME_PLAIN=home\n" ],
        [ File::Spec->catfile( $scope_home, '.d2', '.env' ), "DD_T87_HOME_RUNTIME=d2\n" ],
        [ File::Spec->catfile( $scope_home, '.developer-dashboard', '.env' ), "DD_T87_HOME_RUNTIME=dashboard\nDD_T87_HOME_SKILL=home-runtime\n" ],
        [ File::Spec->catfile( $scope_home, '.developer-dashboard', '.env.pl' ), "\$ENV{DD_T87_HOME_SKILL} = 'home-runtime-pl';\n1;\n" ],
        [ File::Spec->catfile( $scope_project, '.env' ), "DD_T87_PROJECT_PLAIN=project\n" ],
        [ File::Spec->catfile( $scope_project, '.d2', '.env' ), "DD_T87_PROJECT_RUNTIME=d2\n" ],
        [ File::Spec->catfile( $scope_project, '.developer-dashboard', '.env' ), "DD_T87_PROJECT_RUNTIME=dashboard\n" ],
        [ File::Spec->catfile( $scope_skill, '.env' ), "DD_T87_HOME_SKILL=skill\n" ],
        [ File::Spec->catfile( $scope_skill, '.env.pl' ), "\$ENV{DD_T87_HOME_SKILL} = 'skill-pl';\n1;\n" ],
    );
    write_file( @{$_} ) for @files;
    local %ENV                                   = %ENV;
    local $ENV{DD_T87_EXPLICIT_SHELL}            = 'caller-wins';
    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( ['DD_T87_EXPLICIT_SHELL'] );
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    my $loaded = $EL->load_skill_runtime_layers( paths => $paths, skill_layers => [$scope_skill] );
    is( $ENV{DD_T87_HOME_SKILL}, 'skill-pl', 'skill .env.pl overrides matching home runtime .env and .env.pl values' );
    is( $ENV{DD_T87_HOME_RUNTIME}, 'dashboard', 'canonical home runtime environment remains later than the .d2 alias' );
    is( $ENV{DD_T87_PROJECT_PLAIN}, 'project', 'plain project environment still loads after skill environment' );
    is( $ENV{DD_T87_PROJECT_RUNTIME}, 'dashboard', 'deeper project runtime environment still has final precedence' );
    is( $ENV{DD_T87_EXPLICIT_SHELL}, 'caller-wins', 'caller-exported values stay above home, skill, and project env files' );
    my @expected_loaded = map { $_->[0] } ( @files[ 0 .. 3 ], @files[ 7 .. 8 ], @files[ 4 .. 6 ] );
    is_deeply(
        $loaded,
        \@expected_loaded,
        'load_skill_runtime_layers returns files in home, skill, then descendant precedence order',
    );
    ok(
        !defined $Developer::Dashboard::EnvAudit::AUDIT{DD_T87_EXPLICIT_SHELL},
        'an explicit caller value is not attributed to a dashboard env file',
    );
}

{
    local %ENV                                   = %ENV;
    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = undef;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    $EL->load_files( files => [] );
    ok( !defined $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}, 'restoring the absent internal marker does not create an empty env-audit record' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    is( ref( $EL->load_skill_layers ), 'ARRAY', 'load_skill_layers tolerates a missing skill_layers list' );
    is(
        ref( $EL->load_skill_layers( skill_layers => [ File::Spec->catdir( $home, 'skills', 'foo' ) ] ) ),
        'ARRAY',
        'load_skill_layers accepts an explicit skill_layers list',
    );
    my $skill_cli_root = File::Spec->catdir( $home, 'skills', 'foo', 'cli' );
    write_file( File::Spec->catfile( $skill_cli_root, '.env' ), "SKILL_CLI_ENV=loaded\n" );
    is_deeply(
        $EL->load_skill_cli_layers( skill_layers => [ File::Spec->catdir( $home, 'skills', 'foo' ) ] ),
        [ File::Spec->catfile( $skill_cli_root, '.env' ) ],
        'load_skill_cli_layers loads .env files from participating skill cli directories',
    );
    is_deeply( $EL->load_skill_cli_layers, [], 'load_skill_cli_layers returns no files when skill_layers is omitted' );
    is( $ENV{SKILL_CLI_ENV}, 'loaded', 'load_skill_cli_layers applies the skill cli env file' );
}

{
    my $r1 = $EL->load_skill_layers_into_hash;
    is( ref($r1),        'HASH', 'load_skill_layers_into_hash returns a hash without arguments' );
    is( ref( $r1->{env} ), 'HASH', 'load_skill_layers_into_hash returns an env overlay hash' );
    my $r2 = $EL->load_skill_layers_into_hash(
        base_env     => { COV_BASE => 1 },
        skill_layers => [ File::Spec->catdir( $home, 'skills', 'foo' ) ],
    );
    is( ref($r2), 'HASH', 'load_skill_layers_into_hash returns a hash for an explicit base env and skill list' );
}

# --- load_skill_layers_into_hash: overlay difference classes ----------------
# The overlay filter keeps a key only when the skill chain added it or changed
# it. The changed-value class (key exists in the base env, both values defined,
# values differ) is the one outcome nothing else in the suite produces, so it
# is pinned here directly rather than left to incidental execution: without it
# the value-comparison arm of the overlay filter sits uncovered and a refactor
# could silently start leaking unchanged keys into, or dropping changed keys
# from, the overlay.
{
    my $covchange = File::Spec->catdir( $home, 'skills', 'covchange' );
    write_file(
        File::Spec->catfile( $covchange, '.env' ),
        "COV_CHANGE=new\nCOV_KEEP=same\nCOV_ADDED=fresh\n",
    );
    my $r = $EL->load_skill_layers_into_hash(
        base_env => {
            COV_CHANGE    => 'old',
            COV_KEEP      => 'same',
            COV_UNTOUCHED => 'stay',
        },
        skill_layers => [$covchange],
    );
    is(
        $r->{env}{COV_CHANGE},
        'new',
        'a base key the skill chain rewrites to a different value lands in the overlay with the new value',
    );
    is(
        $r->{env}{COV_ADDED},
        'fresh',
        'a key the skill chain introduces lands in the overlay',
    );
    ok(
        !exists $r->{env}{COV_KEEP},
        'a base key the skill chain rewrites to the identical value stays out of the overlay',
    );
    ok(
        !exists $r->{env}{COV_UNTOUCHED},
        'a base key the skill chain never touches stays out of the overlay',
    );
}

# --- load_files ------------------------------------------------------------

{
    my $caller_value = 'from-caller';
    my $override_file = write_file(
        File::Spec->catfile( $home, 'caller-precedence', '.env' ),
        "DD_T87_CALLER_PRECEDENCE=from-file\nDD_T87_FILE_ONLY=loaded\n_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS=not-json\n",
    );
    my $override_perl_file = write_file(
        File::Spec->catfile( $home, 'caller-precedence', '.env.pl' ),
        "\$ENV{DD_T87_CALLER_PRECEDENCE} = 'from-perl-file';\n1;\n",
    );
    local %ENV                                   = %ENV;
    local $ENV{DD_T87_CALLER_PRECEDENCE}         = $caller_value;
    my $caller_key_marker = json_encode( ['DD_T87_CALLER_PRECEDENCE'] );
    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = $caller_key_marker;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();

    $EL->load_files( files => [ $override_file, $override_perl_file ] );
    is(
        $ENV{DD_T87_CALLER_PRECEDENCE},
        $caller_value,
        'an explicitly inherited environment value takes precedence over a loaded env file',
    );
    is( $ENV{DD_T87_FILE_ONLY}, 'loaded', 'unexported values still load from env files' );
    is( $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS}, $caller_key_marker, 'env files cannot overwrite the private inherited-key marker' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = '';
    ok( exists $EL->_capture_inherited_env->{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS}, 'an empty inherited-key marker is preserved as empty' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    ok( exists $EL->_capture_inherited_env->{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS}, '_capture_inherited_env preserves marker absence' );
    ok( $EL->_restore_inherited_env(undef), '_restore_inherited_env safely ignores a non-hash input' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( ['DD_T87_ABSENT_SHELL'] );
    my $absent_file = write_file(
        File::Spec->catfile( $home, 'absent-caller', '.env' ),
        "DD_T87_ABSENT_SHELL=file-may-populate\n",
    );
    $EL->load_files( files => [$absent_file] );
    is( $ENV{DD_T87_ABSENT_SHELL}, 'file-may-populate', 'a caller-unset variable may still be supplied by an env file' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( {} );
    my $shape_error = eval { $EL->_capture_inherited_env; 1 } ? '' : $@;
    like( $shape_error, qr/must contain a JSON array/, 'invalid marker shape fails explicitly' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( ['DD-BAD-NAME'] );
    my $key_error = eval { $EL->_capture_inherited_env; 1 } ? '' : $@;
    like( $key_error, qr/contains an invalid environment key/, 'invalid inherited key fails explicitly' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( [{}] );
    my $reference_key_error = eval { $EL->_capture_inherited_env; 1 } ? '' : $@;
    like( $reference_key_error, qr/contains an invalid environment key/, 'non-scalar inherited keys fail explicitly' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( [undef] );
    my $undefined_key_error = eval { $EL->_capture_inherited_env; 1 } ? '' : $@;
    like( $undefined_key_error, qr/contains an invalid environment key/, 'undefined inherited keys fail explicitly' );

    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( ['DD_T87_RESTORE_ON_ERROR'] );
    local $ENV{DD_T87_RESTORE_ON_ERROR} = 'caller-survives-error';
    my $bad_file = write_file(
        File::Spec->catfile( $home, 'caller-error', '.env' ),
        "DD_T87_RESTORE_ON_ERROR=file-overwrite\n/* unterminated\n",
    );
    my $load_error = eval { $EL->load_files( files => [$bad_file] ); 1 } ? '' : $@;
    like( $load_error, qr/Unterminated block comment/, 'load_files still reports a broken env file' );
    is( $ENV{DD_T87_RESTORE_ON_ERROR}, 'caller-survives-error', 'caller values are restored even when env loading fails' );
}

{
    my $skill_error_root = File::Spec->catdir( $home, 'skills', 'skill-error' );
    write_file(
        File::Spec->catfile( $skill_error_root, '.env' ),
        "DD_T87_SKILL_ERROR=skill-value\n/* unterminated\n",
    );
    local %ENV                                   = %ENV;
    local $ENV{DD_T87_SKILL_ERROR}               = 'caller-survives-skill-error';
    local $ENV{_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS} = json_encode( ['DD_T87_SKILL_ERROR'] );
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    my $skill_error = eval { $EL->load_skill_layers( skill_layers => [$skill_error_root] ); 1 } ? '' : $@;
    like( $skill_error, qr/Unterminated block comment/, 'skill layer loading reports a broken env file' );
    is( $ENV{DD_T87_SKILL_ERROR}, 'caller-survives-skill-error', 'skill layer loading restores caller values before reporting failure' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ( DD_T87_FORGET => { value => 'old', envfile => '/tmp/old.env' } );
    ok( Developer::Dashboard::EnvAudit->forget('DD_T87_FORGET'), 'forget removes env-file provenance' );
    ok( !defined Developer::Dashboard::EnvAudit->key('DD_T87_FORGET'), 'forgotten provenance is no longer reported' );
    my $forget_error = eval { Developer::Dashboard::EnvAudit->forget(''); 1 } ? '' : $@;
    like( $forget_error, qr/Missing env audit key/, 'forget rejects an empty key explicitly' );
    my $undefined_forget_error = eval { Developer::Dashboard::EnvAudit->forget(undef); 1 } ? '' : $@;
    like( $undefined_forget_error, qr/Missing env audit key/, 'forget rejects an undefined key explicitly' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();

    is( ref( $EL->load_files ), 'ARRAY', 'load_files tolerates a missing files list' );

    my $real = write_file( File::Spec->catfile( $home, 'plain', '.env' ), "PLAIN_KEY=plainval\n" );
    my $loaded = $EL->load_files( files => [ undef, '', $real, $real ] );
    is_deeply( $loaded, [$real], 'load_files skips undef, empty, and duplicate entries and loads the real file once' );
    is( $ENV{PLAIN_KEY}, 'plainval', 'load_files applies a real env file' );
}

# --- _load_env_file failure and block-comment paths ------------------------

{
    my $err = eval { $EL->_load_env_file( File::Spec->catfile( $home, 'no-such', 'missing.env' ) ); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_load_env_file dies when the file cannot be opened' );

    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    my $bad = write_file( File::Spec->catfile( $home, 'blockcomment', '.env' ), "KEY=val\n/* unterminated block comment\n" );
    my $berr = eval { $EL->_load_env_file($bad); 1 } ? '' : $@;
    like( $berr, qr/Unterminated block comment/, '_load_env_file dies on an unterminated block comment' );
}

# --- _path_identity --------------------------------------------------------

{
    is( $EL->_path_identity(undef), '', '_path_identity returns empty for an undefined path' );
    is( $EL->_path_identity(''),    '', '_path_identity returns empty for an empty path' );
    my $id = $EL->_path_identity($home);
    ok( defined $id && $id ne '', '_path_identity resolves an existing path via abs_path' );
    my $missing = '/no/such/envloader/path/xyz';
    is( $EL->_path_identity($missing), File::Spec->canonpath($missing), '_path_identity falls back to canonpath for a nonexistent path' );
}

# --- _same_or_descendant_path ----------------------------------------------

{
    is( $EL->_same_or_descendant_path( undef, '/r' ), 0, '_same_or_descendant_path rejects an undefined path' );
    is( $EL->_same_or_descendant_path( '',    '/r' ), 0, '_same_or_descendant_path rejects an empty path' );
    is( $EL->_same_or_descendant_path( '/p', undef ), 0, '_same_or_descendant_path rejects an undefined root' );
    is( $EL->_same_or_descendant_path( '/p', '' ),    0, '_same_or_descendant_path rejects an empty root' );
    is( $EL->_same_or_descendant_path( '/same/path', '/same/path' ), 1, '_same_or_descendant_path returns true for identical paths' );
    is( $EL->_same_or_descendant_path( '/a/b/c', '/a/b' ), 1, '_same_or_descendant_path recognizes a descendant path' );
    is( $EL->_same_or_descendant_path( '/a/b/c', '/x/y' ), 0, '_same_or_descendant_path rejects an unrelated path' );
}

# --- _strip_env_comments ---------------------------------------------------

{
    my $state = 0;
    is( $EL->_strip_env_comments( in_block_comment => \$state ), '', '_strip_env_comments defaults a missing line to empty' );
    is( $EL->_strip_env_comments( line => 'plain=1', in_block_comment => \$state ), 'plain=1', '_strip_env_comments returns a plain line unchanged' );
    my $err = eval { $EL->_strip_env_comments( line => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing in_block_comment state/, '_strip_env_comments dies without block-comment state' );
}

# --- value expansion helpers -----------------------------------------------

{
    local %ENV = %ENV;
    is( $EL->_expand_env_value( file => 'f', line_no => 1 ), '', '_expand_env_value defaults a missing value to empty' );
    is( $EL->_expand_env_value( value => 'literal', file => 'f', line_no => 1 ), 'literal', '_expand_env_value returns a literal value' );

    delete $ENV{DD_ENVLOADER_UNSET_XYZ};
    is( $EL->_expand_braced_env_expression( expression => 'DD_ENVLOADER_UNSET_XYZ', file => 'f', line_no => 1 ), '', '_expand_braced_env_expression returns empty with no value and no default' );
    is( $EL->_expand_braced_env_expression( expression => 'DD_ENVLOADER_UNSET_XYZ:-fallback', file => 'f', line_no => 1 ), 'fallback', '_expand_braced_env_expression uses the default when the symbol is unset' );

    is( $EL->_lookup_env_symbol(undef), undef, '_lookup_env_symbol returns undef for an undefined name' );
    is( $EL->_lookup_env_symbol(''),    undef, '_lookup_env_symbol returns undef for an empty name' );
    $ENV{DD_ENVLOADER_SET_XYZ} = 'set';
    is( $EL->_lookup_env_symbol('DD_ENVLOADER_SET_XYZ'), 'set', '_lookup_env_symbol returns the value for a defined name' );
}

# --- _call_env_function ----------------------------------------------------

{
    my $e1 = eval { $EL->_call_env_function( file => 'f', line_no => 1 ); 1 } ? '' : $@;
    like( $e1, qr/Invalid env function/, '_call_env_function rejects a missing function name' );

    my $e2 = eval { $EL->_call_env_function( function => '1bad()', file => 'f', line_no => 2 ); 1 } ? '' : $@;
    like( $e2, qr/Invalid env function/, '_call_env_function rejects a malformed function name' );

    my $e3 = eval { $EL->_call_env_function( function => 'Local::EnvCov::nope()', file => 'f', line_no => 3 ); 1 } ? '' : $@;
    like( $e3, qr/Invalid env function/, '_call_env_function rejects an unresolved function' );

    my $e4 = eval { $EL->_call_env_function( function => 'Local::EnvCov::boom()', file => 'f', line_no => 4 ); 1 } ? '' : $@;
    like( $e4, qr/Env function .* failed/, '_call_env_function reports a dying function' );

    is( $EL->_call_env_function( function => 'Local::EnvCov::hello()', file => 'f', line_no => 5 ), 'hi', '_call_env_function returns a static function value' );
}

# --- skill-spec expansion helpers ------------------------------------------

{
    is_deeply( [ $EL->_nested_skill_layer_specs(undef) ], [], '_nested_skill_layer_specs returns empty for an undefined root' );
    is_deeply( [ $EL->_nested_skill_layer_specs('') ],    [], '_nested_skill_layer_specs returns empty for an empty root' );

    my @plain = $EL->_nested_skill_layer_specs('/opt/tools/widget');
    is( scalar @plain,      1,        '_nested_skill_layer_specs yields one spec for a non-skill root' );
    is( $plain[0]{prefix}, 'widget', '_nested_skill_layer_specs normalizes the leaf segment as the prefix' );

    my @rooted = $EL->_nested_skill_layer_specs('/');
    is( $rooted[0]{prefix}, '', '_nested_skill_layer_specs yields an empty prefix for the filesystem root' );

    my @nested = $EL->_nested_skill_layer_specs('/base/skills/alpha/skills/beta');
    is( scalar @nested,     2,             '_nested_skill_layer_specs expands a nested skill chain' );
    is( $nested[0]{prefix}, 'alpha',       '_nested_skill_layer_specs uses the first skill segment as the base prefix' );
    is( $nested[1]{prefix}, 'alpha_beta',  '_nested_skill_layer_specs accumulates nested skill prefixes' );

    is( $EL->_normalize_skill_env_prefix(undef),     '',          '_normalize_skill_env_prefix returns empty for undef' );
    is( $EL->_normalize_skill_env_prefix(''),        '',          '_normalize_skill_env_prefix returns empty for an empty name' );
    is( $EL->_normalize_skill_env_prefix('Al-pha 1'), 'Al_pha_1', '_normalize_skill_env_prefix underscores non-word characters' );

    my $specs = $EL->_skill_layer_specs( '/base/skills/alpha', '/base/skills/alpha' );
    is( scalar @{$specs}, 1, '_skill_layer_specs deduplicates repeated skill roots' );
}

# --- _load_skill_layer_specs: overwrite, dedup, and preservation -----------

my $sl  = File::Spec->catdir( $home, 'sl' );
my $foo = File::Spec->catdir( $sl, 'foo' );
my $bar = File::Spec->catdir( $sl, 'bar' );
my $baz = File::Spec->catdir( $sl, 'baz' );
my $qux = File::Spec->catdir( $sl, 'qux' );
my $af  = File::Spec->catdir( $sl, 'af' );
my $am  = File::Spec->catdir( $sl, 'am' );
my $ab  = File::Spec->catdir( $sl, 'ab' );

write_file( File::Spec->catfile( $foo, '.env' ), "SHARED=fooval\nFOO_ONLY=1\n" );
write_file( File::Spec->catfile( $bar, '.env' ), "SHARED=barval\n" );
write_file( File::Spec->catfile( $baz, '.env' ), "BAZKEY=1\n" );
write_file( File::Spec->catfile( $qux, '.env' ),    "QK=1\n" );
write_file( File::Spec->catfile( $qux, '.env.pl' ), "\$ENV{QK} = 2;\n1;\n" );
write_file( File::Spec->catfile( $af,  '.env' ),    "AK=afval\n" );
write_file( File::Spec->catfile( $am,  '.env.pl' ), "delete \$ENV{AK};\n1;\n" );
write_file( File::Spec->catfile( $ab,  '.env' ),    "AK=abval\n" );

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();

    is_deeply( $EL->_load_skill_layer_specs, [], '_load_skill_layer_specs tolerates a missing specs list' );

    my $loaded = $EL->_load_skill_layer_specs(
        specs => [
            'not-a-hash-spec',
            { root => $foo, prefix => 'foo' },
            { root => $bar, prefix => 'foo_bar' },
            { root => $foo, prefix => 'foo_dup' },
        ],
    );
    is( $ENV{SHARED},     'barval', '_load_skill_layer_specs applies the deepest skill value' );
    is( $ENV{foo_SHARED}, 'fooval', '_load_skill_layer_specs preserves the overwritten parent value under a prefixed alias' );
    is_deeply(
        $loaded,
        [ File::Spec->catfile( $foo, '.env' ), File::Spec->catfile( $bar, '.env' ) ],
        '_load_skill_layer_specs loads foo and bar once, skipping the duplicate foo root',
    );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    my $loaded = $EL->_load_skill_layer_specs( specs => [ { root => $baz } ] );
    is( $ENV{BAZKEY}, '1', '_load_skill_layer_specs loads a spec that has no prefix' );
    is_deeply( $loaded, [ File::Spec->catfile( $baz, '.env' ) ], '_load_skill_layer_specs loads the baz env file' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    $EL->_load_skill_layer_specs( specs => [ { root => $qux, prefix => 'qq' } ] );
    is( $ENV{QK}, '2', '_load_skill_layer_specs applies a same-layer .env.pl override after the .env' );
    ok( !exists $ENV{qq_QK}, 'a same-prefix override within one layer does not create a parent alias' );
}

# ---------------------------------------------------------------------------
# DD-1044: a .env.pl that assigns $ENV{KEY} to the SAME value it already had
# (inherited from the OS environment, or from an earlier layer) must still be
# recorded in the audit - the file genuinely set it, even though the value
# didn't change. The pre/post %ENV value-diff alone cannot see this: it
# only detects keys whose VALUE changed, not keys a .env.pl explicitly
# assigned.
# ---------------------------------------------------------------------------
{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    local $ENV{SAME_VALUE_KEY} = 'unchanged';

    my $pl = write_file(
        File::Spec->catfile( $home, 'samevalue', '.env.pl' ),
        "\$ENV{SAME_VALUE_KEY} = 'unchanged';\n1;\n",
    );
    $EL->_load_env_pl_file($pl);
    my $recorded = Developer::Dashboard::EnvAudit->key('SAME_VALUE_KEY');
    ok( defined $recorded, 'a .env.pl assignment that keeps the same value is still recorded in the audit (DD-1044)' );
    is( $recorded->{envfile}, $pl, 'the audit records the correct .env.pl source file for a same-value assignment' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    local $ENV{DYNAMIC_ENV_KEY} = 'before';

    my $pl = write_file(
        File::Spec->catfile( $home, 'dynamic-assignment', '.env.pl' ),
        "my \$key = 'DYNAMIC_ENV_KEY';\n\$ENV{\$key} = 'after';\n1;\n",
    );
    $EL->_load_env_pl_file($pl);
    is( $ENV{DYNAMIC_ENV_KEY}, 'after', 'a dynamically named .env.pl assignment updates the inherited value' );
    is(
        Developer::Dashboard::EnvAudit->key('DYNAMIC_ENV_KEY')->{envfile}, $pl,
        'the runtime value-diff records dynamic assignments that static scanning cannot name',
    );

    my $same_value = write_file(
        File::Spec->catfile( $home, 'dynamic-same-value', '.env.pl' ),
        "my \$key = 'DYNAMIC_SAME_VALUE';\n\$ENV{\$key} = 'same';\n1;\n",
    );
    local $ENV{DYNAMIC_SAME_VALUE} = 'same';
    $EL->_load_env_pl_file($same_value);
    ok(
        !defined Developer::Dashboard::EnvAudit->key('DYNAMIC_SAME_VALUE'),
        'a dynamic assignment of an unchanged value is not misreported without a literal assignment target',
    );

    my $from_undef = write_file(
        File::Spec->catfile( $home, 'dynamic-from-undef', '.env.pl' ),
        "my \$key = 'DYNAMIC_FROM_UNDEF';\n\$ENV{\$key} = 'now-defined';\n1;\n",
    );
    local $ENV{DYNAMIC_FROM_UNDEF} = undef;
    $EL->_load_env_pl_file($from_undef);
    is( $ENV{DYNAMIC_FROM_UNDEF}, 'now-defined',
        'dynamic env.pl assignments are recorded when the inherited value was undef' );

    my $to_undef = write_file(
        File::Spec->catfile( $home, 'dynamic-to-undef', '.env.pl' ),
        "my \$key = 'DYNAMIC_TO_UNDEF';\n\$ENV{\$key} = undef;\n1;\n",
    );
    local $ENV{DYNAMIC_TO_UNDEF} = 'before';
    $EL->_load_env_pl_file($to_undef);
    ok( !defined $ENV{DYNAMIC_TO_UNDEF},
        'dynamic env.pl assignments are recorded when they clear an inherited value' );
}

{
    my $missing = File::Spec->catfile( $home, 'missing-env-source.pl' );
    is_deeply( [ $EL->_env_pl_assigned_keys($missing) ], [], 'the assignment scanner returns no keys when its source cannot be opened' );
    is_deeply( [ $EL->_env_pl_assigned_keys($home) ], [], 'the assignment scanner returns no keys when reading a directory yields no source text' );
}

{
    local %ENV                                   = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}    = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT = ();
    $EL->_load_skill_layer_specs(
        specs => [
            { root => $af, prefix => 'af' },
            { root => $am, prefix => 'af_am' },
            { root => $ab, prefix => 'af_am_ab' },
        ],
    );
    is( $ENV{AK}, 'abval', '_load_skill_layer_specs re-applies a key that a middle layer deleted' );
    ok( !exists $ENV{af_AK}, 'a key absent from the pre-file environment is not preserved as a parent alias' );
}

# --- _load_env_pl_file defined-ness transitions (via load_files_into_hash) --

{
    my $pl = write_file(
        File::Spec->catfile( $home, 'plfile', 'undef.env.pl' ),
        "\$ENV{VALK} = undef;\n\$ENV{UNDEFK} = 'now';\n\$ENV{NEWK} = 'new';\n1;\n",
    );

    my $result = $EL->load_files_into_hash(
        base_env => {
            VALK       => 'orig',
            UNDEFK     => undef,
            UNDEFKEEP  => undef,
            NORMALKEEP => 'keep',
        },
        files => [$pl],
    );
    is( ref($result), 'HASH', 'load_files_into_hash returns a hash with an explicit base env' );
    is( $result->{env}{UNDEFK}, 'now', 'load_files_into_hash overlays a key that changed from undef to a value' );
    is( $result->{env}{NEWK},   'new', 'load_files_into_hash overlays a brand new key' );
    ok( exists $result->{env}{VALK},   'load_files_into_hash overlays a key that changed from a value to undef' );
    ok( !defined $result->{env}{VALK}, 'load_files_into_hash preserves an undef overlay value' );
    ok( !exists $result->{env}{UNDEFKEEP}, 'load_files_into_hash omits a key that stayed undef' );
    ok( !exists $result->{env}{NORMALKEEP}, 'load_files_into_hash omits an unchanged defined key' );

    my $r2 = $EL->load_files_into_hash( files => [] );
    is( ref($r2), 'HASH', 'load_files_into_hash returns a hash without a base env' );
}

# --- _plain_directory_layers ancestry resolution ---------------------------

{
    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => undef, home => '/hm', project_root => '' ) ) ],
        [],
        '_plain_directory_layers returns nothing for an undefined cwd',
    );
    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => '', home => '/hm', project_root => '' ) ) ],
        [],
        '_plain_directory_layers returns nothing for an empty cwd',
    );

    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => '/hm/a/b', home => '/hm', project_root => '' ) ) ],
        [ '/hm', '/hm/a', '/hm/a/b' ],
        '_plain_directory_layers walks from home down to the cwd',
    );

    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => '/x/y/z', home => '/other', project_root => '' ) ) ],
        ['/x/y/z'],
        '_plain_directory_layers loads the invocation cwd when it is outside home and there is no project root',
    );

    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => '/x/y/z', home => '/other', project_root => '/p/q' ) ) ],
        ['/x/y/z'],
        '_plain_directory_layers still loads the invocation cwd when it is under neither home nor the project root',
    );

    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => '/p/q/r', home => '/other', project_root => '/p/q' ) ) ],
        [ '/p/q', '/p/q/r' ],
        '_plain_directory_layers walks from the project root down to the cwd',
    );
}

is_deeply( \@warnings, [], 'no warnings were emitted during the EnvLoader coverage run' )
  or diag( "warnings:\n" . join( '', @warnings ) );

done_testing;

__END__

=pod

=head1 NAME

t/87-envloader-coverage.t - branch and condition coverage closure for the layered env loader

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::EnvLoader>. It drives every decision point in the
layered env-file loader: the entry-guard defaults, the plain-directory and
skill-root ancestry walks, the nested-skill parent-value preservation, the
C<.env> parser failure paths, the C<.env.pl> defined-ness transition
detection, and the overlay difference classes of
C<load_skill_layers_into_hash> - a changed base key must surface in the
overlay with its new value, an added key must surface, and identical or
untouched base keys must stay out. It also covers home/descendant runtime
scoping and verifies that skill values override home defaults without changing
deeper-project precedence. Read it to see the concrete inputs that reach each
branch and condition instead of inferring them from the module source.

=head1 WHY IT EXISTS

It exists because the env loader carries several rarely-taken paths -
missing-argument defaults, malformed input that must fail loudly, and the
nested-skill logic that re-homes a parent value under a prefixed alias when a
deeper skill overwrites it. Those paths are easy to break without noticing, so
this file pins them with hermetic fixtures and keeps the module at full branch
and condition coverage.

=head1 WHEN TO USE

Use this file when changing env precedence, the skill-prefix derivation, the
C<.env> comment or expansion grammar, or the audit-recording behavior, and
whenever the coverage gate reports an uncovered branch or condition in the env
loader.

=head1 HOW TO USE

Run C<prove -lv t/87-envloader-coverage.t> while iterating, then keep it green
under C<prove -lr t> and under the Devel::Cover run before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the coverage gates
all rely on this file to keep the env loader's decision points exercised and
its failure modes explicit.

=head1 EXAMPLES

Example 1:

  prove -lv t/87-envloader-coverage.t

Run the focused env-loader coverage test by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/87-envloader-coverage.t

Exercise the same test while collecting coverage for the env loader.

Example 3:

  prove -lr t

Run it inside the whole repository suite before calling the work finished.

=cut
