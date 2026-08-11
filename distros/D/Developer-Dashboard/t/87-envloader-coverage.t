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
}

{
    local %ENV                                     = %ENV;
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT}      = undef;
    local %Developer::Dashboard::EnvAudit::AUDIT   = ();
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $loaded = $EL->load_runtime_layers( paths => $paths );
    is( ref($loaded), 'ARRAY', 'load_runtime_layers returns an ordered file list for a valid registry' );
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
        [],
        '_plain_directory_layers returns nothing when cwd is outside home and there is no project root',
    );

    is_deeply(
        [ $EL->_plain_directory_layers( Local::MockPaths->new( cwd => '/x/y/z', home => '/other', project_root => '/p/q' ) ) ],
        [],
        '_plain_directory_layers returns nothing when cwd is under neither home nor the project root',
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
untouched base keys must stay out. Read it to see the concrete inputs that reach each branch and
condition instead of inferring them from the module source.

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
