#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config ();
use Developer::Dashboard::File ();
use Developer::Dashboard::FileRegistry ();
use Developer::Dashboard::PathRegistry ();

# Blessed stand-ins for the runtime registries. Each one deliberately
# implements only part of the registry interface so the defensive guards in
# Developer::Dashboard::File that protect against half-built runtime objects
# can be driven from a test instead of only in production accidents.
{

    package DDFileCoverRegistry;

    # new(%args)
    # Builds a file-registry stand-in that can expose a path registry.
    # Input: optional paths value (blessed, unblessed, or missing).
    # Output: blessed DDFileCoverRegistry object.
    sub new { my ( $class, %args ) = @_; return bless {%args}, $class }

    # paths()
    # Returns whatever path registry value the test asked for.
    # Input: none.
    # Output: paths value or undef.
    sub paths { return $_[0]{paths} }

    # register_named_files($aliases)
    # Accepts config-backed aliases without storing them.
    # Input: alias hash reference.
    # Output: true value.
    sub register_named_files { return 1 }
}

{

    package DDFileCoverBareRegistry;

    # new()
    # Builds a blessed file-registry stand-in that answers no registry methods.
    # Input: none.
    # Output: blessed DDFileCoverBareRegistry object.
    sub new { return bless {}, $_[0] }
}

{

    package DDFileCoverEmptyPaths;

    # new()
    # Builds a blessed path registry whose layers are all empty.
    # Input: none.
    # Output: blessed DDFileCoverEmptyPaths object.
    sub new { return bless {}, $_[0] }

    # current_project_root()
    # Reports that no project root is active.
    # Input: none.
    # Output: empty string.
    sub current_project_root { return '' }

    # runtime_roots()
    # Reports an empty runtime layer stack.
    # Input: none.
    # Output: empty list.
    sub runtime_roots { return () }

    # config_roots()
    # Reports an empty config layer stack.
    # Input: none.
    # Output: empty list.
    sub config_roots { return () }

    # installed_skill_roots()
    # Reports that no skills are installed.
    # Input: none.
    # Output: empty list.
    sub installed_skill_roots { return () }

    # secure_file_permissions($path)
    # Accepts permission hardening requests without touching the filesystem.
    # Input: file path string.
    # Output: true value.
    sub secure_file_permissions { return 1 }
}

# Hermetic runtime: an empty temporary home plus a cwd inside it, so no
# .developer-dashboard layer from the checkout can leak into the resolver.
my $orig_cwd = getcwd();
my $home     = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
    project_roots   => [ File::Spec->catdir( $home, 'workspace' ) ],
);
my $registry = Developer::Dashboard::FileRegistry->new( paths => $paths );

# Keep every compatibility global out of the rest of the suite's way.
local $Developer::Dashboard::File::FILES              = undef;
local %Developer::Dashboard::File::ALIASES            = ();
local %Developer::Dashboard::File::CONFIG_ALIASES     = ();
local $Developer::Dashboard::File::CONFIG_ALIASES_KEY = '';

# configure(): registry selection and the alias table default.
{
    local $Developer::Dashboard::File::FILES   = undef;
    local %Developer::Dashboard::File::ALIASES = ( leftover => '/tmp/leftover.txt' );
    ok( Developer::Dashboard::File->configure( files => $registry ), 'configure accepts a prebuilt file registry' );
    is( $Developer::Dashboard::File::FILES, $registry, 'configure adopts the supplied file registry' );
    is_deeply( \%Developer::Dashboard::File::ALIASES, {}, 'configure without an aliases hash resets the alias table' );
}

{
    local $Developer::Dashboard::File::FILES = $registry;
    Developer::Dashboard::File->configure( paths => $paths, aliases => { alpha => '/tmp/alpha.txt' } );
    is( $Developer::Dashboard::File::FILES, $registry, 'configure keeps an already configured registry instead of rebuilding it from paths' );
    is( $Developer::Dashboard::File::ALIASES{alpha}, '/tmp/alpha.txt', 'configure stores literal aliases' );
}

{
    local $Developer::Dashboard::File::FILES = undef;
    Developer::Dashboard::File->configure( aliases => { alpha => '/tmp/alpha.txt' } );
    is( $Developer::Dashboard::File::FILES, undef, 'configure without files or paths leaves the registry unbuilt' );
}

{
    local $Developer::Dashboard::File::FILES = undef;
    Developer::Dashboard::File->configure( paths => $paths );
    isa_ok( $Developer::Dashboard::File::FILES, 'Developer::Dashboard::FileRegistry' );
}

# all(): no runtime home at all, and a registry that cannot list files.
{
    local $ENV{HOME}                         = '';
    local $Developer::Dashboard::File::FILES = undef;
    is_deeply( Developer::Dashboard::File->all, {}, 'all returns an empty inventory when no home directory is available' );
    is( $Developer::Dashboard::File::FILES, undef, 'a missing home directory never builds a lazy registry' );
}

{
    local $Developer::Dashboard::File::FILES              = DDFileCoverRegistry->new( paths => $paths );
    local $Developer::Dashboard::File::CONFIG_ALIASES_KEY = 'stale-key';
    is_deeply( Developer::Dashboard::File->all, {}, 'all returns an empty inventory when the registry cannot list files' );
}

# exists(): a resolved path that is not on disk.
{
    local $Developer::Dashboard::File::FILES   = $registry;
    local %Developer::Dashboard::File::ALIASES = ( absent => File::Spec->catfile( $home, 'absent.txt' ) );
    is( Developer::Dashboard::File->exists('absent'), 0, 'exists reports false for a resolved path with no file on disk' );
}

# read(): unresolvable names, missing files, and an unopenable file.
{
    local $Developer::Dashboard::File::FILES = $registry;
    is( Developer::Dashboard::File->read(undef), undef, 'read returns undef when the name is undefined' );
    is( Developer::Dashboard::File->read(''),    undef, 'read returns undef for an empty name' );
    is( Developer::Dashboard::File->read( File::Spec->catfile( $home, 'nope.txt' ) ),
        undef, 'read returns undef when the resolved file does not exist' );

    my $unreadable = File::Spec->catfile( $home, 'unreadable.txt' );
    open my $fh, '>', $unreadable or die "Unable to write $unreadable: $!";
    print {$fh} "secret\n";
    close $fh or die "Unable to close $unreadable: $!";
    chmod 0000, $unreadable or die "Unable to chmod $unreadable: $!";

    my $error = '';
    eval { Developer::Dashboard::File->read($unreadable); 1 } or $error = $@;
    like( $error, qr/\AUnable to read \Q$unreadable\E: /, 'read dies when an existing file cannot be opened' );

    chmod 0600, $unreadable or die "Unable to restore $unreadable: $!";
}

# write(): missing paths, append mode, undefined content, and failed IO.
{
    local $Developer::Dashboard::File::FILES   = $registry;
    local %Developer::Dashboard::File::ALIASES = ( emptyalias => '' );

    my $error = '';
    eval { Developer::Dashboard::File->write( undef, 'x' ); 1 } or $error = $@;
    like( $error, qr/\AMissing file path/, 'write dies when the name cannot resolve to a path' );

    $error = '';
    eval { Developer::Dashboard::File->write( 'emptyalias', 'x' ); 1 } or $error = $@;
    like( $error, qr/\AMissing file path/, 'write dies when an alias resolves to an empty path' );

    my $file = File::Spec->catfile( $home, 'appended.txt' );
    Developer::Dashboard::File->write( $file, "first\n" );
    is( Developer::Dashboard::File->write( $file, "second\n", 1 ), $file, 'write returns the resolved path' );
    is( Developer::Dashboard::File->read($file), "first\nsecond\n", 'write appends when the append flag is set' );

    Developer::Dashboard::File->write($file);
    is( -s $file, 0, 'write with undefined content truncates the file to empty' );

    my $unwritable = File::Spec->catfile( $home, 'no-such-dir', 'x.txt' );
    $error = '';
    eval { Developer::Dashboard::File->write( $unwritable, 'x' ); 1 } or $error = $@;
    like( $error, qr/\AUnable to write \Q$unwritable\E: /, 'write dies when the destination cannot be opened' );
}

SKIP: {
    skip 'requires a writable /dev/full to force a flush failure on close', 1
      if !-e '/dev/full' || !-w '/dev/full';

    local $Developer::Dashboard::File::FILES = $registry;
    my $error = '';
    eval { Developer::Dashboard::File->write( '/dev/full', "overflow\n" ); 1 } or $error = $@;
    like( $error, qr{\AUnable to close /dev/full: }, 'write dies when flushing the content on close fails' );
}

# write()/touch(): permission hardening is skipped when no usable registry exists.
{
    local $ENV{HOME}                         = '';
    local $Developer::Dashboard::File::FILES = undef;
    my $file = File::Spec->catfile( $home, 'no-registry.txt' );
    is( Developer::Dashboard::File->write( $file, "plain\n" ), $file, 'write succeeds without a registry to harden permissions' );
    is( Developer::Dashboard::File->touch($file), $file, 'touch succeeds without a registry to harden permissions' );
}

{
    local $Developer::Dashboard::File::FILES = DDFileCoverBareRegistry->new;
    my $file = File::Spec->catfile( $home, 'bare-registry.txt' );
    is( Developer::Dashboard::File->write( $file, "plain\n" ), $file, 'write skips hardening when the registry cannot expose paths' );
    is( Developer::Dashboard::File->touch($file), $file, 'touch skips hardening when the registry cannot expose paths' );
}

# touch(): missing paths and a failed open.
{
    local $Developer::Dashboard::File::FILES   = $registry;
    local %Developer::Dashboard::File::ALIASES = ( emptyalias => '' );

    my $error = '';
    eval { Developer::Dashboard::File->touch(undef); 1 } or $error = $@;
    like( $error, qr/\AMissing file path/, 'touch dies when the name cannot resolve to a path' );

    $error = '';
    eval { Developer::Dashboard::File->touch('emptyalias'); 1 } or $error = $@;
    like( $error, qr/\AMissing file path/, 'touch dies when an alias resolves to an empty path' );

    my $untouchable = File::Spec->catfile( $home, 'no-such-dir', 'y.txt' );
    $error = '';
    eval { Developer::Dashboard::File->touch($untouchable); 1 } or $error = $@;
    like( $error, qr/\AUnable to touch \Q$untouchable\E: /, 'touch dies when the destination cannot be opened' );
}

# rm(): nothing to unlink.
{
    local $Developer::Dashboard::File::FILES = $registry;
    is( Developer::Dashboard::File->rm(undef), undef, 'rm returns undef when the name cannot resolve' );
    my $absent = File::Spec->catfile( $home, 'never-created.txt' );
    is( Developer::Dashboard::File->rm($absent), $absent, 'rm returns the resolved path when there is nothing to unlink' );
}

# The alias cache key refuses half-built runtime objects.
is( Developer::Dashboard::File::_configured_alias_cache_key(undef),
    '', 'the alias cache key is empty without a file registry' );
is( Developer::Dashboard::File::_configured_alias_cache_key( {} ),
    '', 'the alias cache key is empty for an unblessed file registry' );
is( Developer::Dashboard::File::_configured_alias_cache_key( DDFileCoverRegistry->new ),
    '', 'the alias cache key is empty when the registry exposes no path registry' );
is( Developer::Dashboard::File::_configured_alias_cache_key( DDFileCoverRegistry->new( paths => {} ) ),
    '', 'the alias cache key is empty for an unblessed path registry' );

# An unkeyable runtime still reloads config-backed aliases every call.
{
    local $Developer::Dashboard::File::FILES              = DDFileCoverRegistry->new( paths => DDFileCoverEmptyPaths->new );
    local %Developer::Dashboard::File::CONFIG_ALIASES     = ( stale => '/tmp/stale.txt' );
    local $Developer::Dashboard::File::CONFIG_ALIASES_KEY = 'stale-key';
    ok( Developer::Dashboard::File::_load_configured_aliases(), 'config-backed aliases load when the runtime yields no cache key' );
    is( $Developer::Dashboard::File::CONFIG_ALIASES_KEY, '', 'an unkeyable runtime clears the alias cache key' );
    is_deeply( \%Developer::Dashboard::File::CONFIG_ALIASES, {}, 'an unkeyable runtime reloads an empty alias table' );
}

# A config layer that reports no file aliases at all.
{
    local $Developer::Dashboard::File::FILES              = $registry;
    local %Developer::Dashboard::File::CONFIG_ALIASES     = ( stale => '/tmp/stale.txt' );
    local $Developer::Dashboard::File::CONFIG_ALIASES_KEY = 'stale-key';

    no warnings 'redefine';
    local *Developer::Dashboard::Config::file_aliases = sub { return undef };
    ok( Developer::Dashboard::File::_load_configured_aliases(), 'config-backed aliases load when the config layer returns nothing' );
    is_deeply( \%Developer::Dashboard::File::CONFIG_ALIASES, {}, 'a config layer without file aliases clears the alias table' );
}

# resolve(): literal paths, registry methods, alias fallbacks, env overrides.
{
    local $Developer::Dashboard::File::FILES = $registry;
    my $absolute = File::Spec->catfile( $home, 'literal.txt' );
    is( Developer::Dashboard::File->resolve($absolute), $absolute, 'resolve passes an absolute path straight through' );
    is( Developer::Dashboard::File->resolve('relative/notes.txt'),
        'relative/notes.txt', 'resolve passes a relative path with a separator straight through' );
    is( Developer::Dashboard::File->resolve('dashboard_log'),
        $registry->dashboard_log, 'resolve answers built-in registry file names' );
}

{
    local $ENV{HOME}                           = '';
    local $Developer::Dashboard::File::FILES   = undef;
    local %Developer::Dashboard::File::ALIASES = ( plain => '/tmp/plain.txt' );
    is( Developer::Dashboard::File->resolve('plain'),
        '/tmp/plain.txt', 'resolve falls back to literal aliases without a runtime registry' );
}

{
    local $Developer::Dashboard::File::FILES                    = $registry;
    local $ENV{DEVELOPER_DASHBOARD_FILE_BLANKENV}               = '';
    is( Developer::Dashboard::File->resolve('blankenv'), undef, 'resolve ignores an empty env override' );
}

# AUTOLOAD(): destructor calls and unknown names.
{
    local $Developer::Dashboard::File::AUTOLOAD = 'Developer::Dashboard::File::DESTROY';
    is( scalar Developer::Dashboard::File->AUTOLOAD, undef, 'AUTOLOAD ignores DESTROY instead of resolving it as a file' );
}

{
    local $Developer::Dashboard::File::FILES = $registry;
    my $error = '';
    eval { Developer::Dashboard::File->zz_unknown_coverage_file; 1 } or $error = $@;
    like( $error, qr/\AUnknown file 'zz_unknown_coverage_file'/, 'AUTOLOAD dies for a name that cannot resolve' );
}

chdir $orig_cwd or die "Unable to chdir back to $orig_cwd: $!";

done_testing;

__END__

=pod

=head1 NAME

t/111-file-coverage.t - branch and condition coverage for the File compatibility layer

=head1 PURPOSE

This test drives every decision inside Developer::Dashboard::File: registry
selection in C<configure>, the empty-inventory guards in C<all>, alias and
literal-path resolution, the failure paths of C<read>, C<write>, and C<touch>,
the no-op paths of C<rm>, the config-backed alias cache, and the AUTOLOAD
fallbacks. It exists to keep the module at 100% on all four Devel::Cover
metrics, including the branches and conditions that only fire when the runtime
is half-built or when file IO fails.

=head1 WHY IT EXISTS

The compatibility layer is the last consumer-facing seam that older bookmark
code uses to reach runtime files, so its defensive guards are exactly the parts
that never run in a healthy runtime and therefore rot unnoticed. The full-suite
coverage baseline showed those guards untested: the missing-home path, the
registry-without-paths path, the empty-alias path, and the IO failure paths. This
file pins each of them so a future refactor cannot quietly delete a guard or turn
a silent skip into a fatal error.

=head1 WHEN TO USE

Use this file when changing how the compatibility file layer resolves names,
when adding or removing a guard in that module, when changing the config-backed
file alias cache, or when the coverage gate reports a new uncovered branch or
condition in the module.

=head1 HOW TO USE

Run C<prove -lv t/111-file-coverage.t> while iterating. To confirm the coverage
contract, run the module under the coverage gate and check that no branch or
condition in the module is reported uncovered. Keep the file green under
C<prove -lr t> before release.

=head1 WHAT USES IT

The repository test suite and the coverage gate use this file. Contributors
touching the compatibility file layer or the layered config alias cache use it as
the executable description of the module's guard behavior.

=head1 EXAMPLES

Example 1:

  prove -lv t/111-file-coverage.t

Run the compatibility file layer coverage checks on their own.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run the whole suite under the coverage gate and confirm the module reports no
uncovered branch or condition.

Example 3:

  prove -lr t

Put the file back through the entire repository suite before release.

=cut
