#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config ();
use Developer::Dashboard::Folder;
use Developer::Dashboard::PathRegistry;

# Stub registries that answer nothing at all, used to drive the defensive
# "the registry cannot answer this" paths inside Folder.
{

    package DD::Folder::BarePaths;

    sub new { return bless {}, shift }
}

# Stub registry that answers only the alias-cache-key probes, so the cached
# alias key can be pre-seeded without dragging real config loading in.
{

    package DD::Folder::StubPaths;

    sub new                  { return bless {}, shift }
    sub current_project_root { return 'stub-project-root' }
    sub runtime_roots        { return () }
}

# Hermetic runtime rooted in a throwaway home, with the cwd inside it so the
# runtime layer stack resolves from the temporary tree only.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
    project_roots   => [ File::Spec->catdir( $home, 'workspace' ) ],
);

# configure() without an aliases payload must fall back to an empty alias map.
Developer::Dashboard::Folder->configure( paths => $paths );
is_deeply( \%Developer::Dashboard::Folder::ALIASES, {}, 'configure without an aliases payload installs an empty alias map' );
is( $Developer::Dashboard::Folder::CONFIG_ALIASES_KEY, '', 'configure resets the config alias cache key' );

# home() falls back to the empty string when HOME carries no value.
{
    local $ENV{HOME} = '';
    is( Developer::Dashboard::Folder->home, '', 'home() returns an empty string when HOME is empty' );
}

is( Developer::Dashboard::Folder->tmp, File::Spec->tmpdir, 'tmp() reports the system temporary directory' );

# With no HOME and no configured registry there is nothing to resolve, so every
# registry-backed accessor degrades to an empty answer.
{
    local $ENV{HOME}                          = '';
    local $Developer::Dashboard::Folder::PATHS = undef;

    is( Developer::Dashboard::Folder->dd,        '', 'dd() is empty without a resolvable path registry' );
    is( Developer::Dashboard::Folder->bookmarks, '', 'bookmarks() is empty without a resolvable path registry' );
    is( Developer::Dashboard::Folder->configs,   '', 'configs() is empty without a resolvable path registry' );
    is_deeply( Developer::Dashboard::Folder->all, {}, 'all() is empty without a resolvable path registry' );
    ok( Developer::Dashboard::Folder::_load_configured_aliases(), 'alias loading is a no-op without a blessed registry' );
    ok( !defined $Developer::Dashboard::Folder::PATHS, 'no registry is cached when HOME is empty' );
}

# With a usable HOME and no configured registry, a default registry is built
# from the existing conventional workspace directories only.
{
    local $Developer::Dashboard::Folder::PATHS = undef;
    make_path( File::Spec->catdir( $home, 'projects' ) );
    make_path( File::Spec->catdir( $home, 'work' ) );

    my $built = Developer::Dashboard::Folder::_paths_obj();
    isa_ok( $built, 'Developer::Dashboard::PathRegistry', 'a default path registry is built from HOME' );
    is_deeply( [ $built->workspace_roots ], [ "$home/projects", "$home/work" ], 'the default registry keeps only existing workspace roots' );
    is_deeply( [ $built->project_roots ],   [ "$home/projects", "$home/work" ], 'the default registry keeps only existing project roots' );
}

# A registry object that cannot answer the runtime accessors must not be called
# blindly; each accessor reports the empty fallback instead.
{
    local $Developer::Dashboard::Folder::PATHS               = DD::Folder::StubPaths->new;
    local $Developer::Dashboard::Folder::CONFIG_ALIASES_KEY  = 'stub-project-root';

    is( Developer::Dashboard::Folder->dd,        '', 'dd() is empty when the registry lacks runtime_root' );
    is( Developer::Dashboard::Folder->bookmarks, '', 'bookmarks() is empty when the registry lacks dashboards_root' );
    is( Developer::Dashboard::Folder->configs,   '', 'configs() is empty when the registry lacks config_root' );
    is_deeply( Developer::Dashboard::Folder->all, {}, 'all() is empty when the registry lacks all_paths' );
}

# The alias cache key is only meaningful for a blessed registry.
is( Developer::Dashboard::Folder::_configured_alias_cache_key(undef),          '', 'alias cache key is empty without a registry' );
is( Developer::Dashboard::Folder::_configured_alias_cache_key('not-an-object'), '', 'alias cache key is empty for an unblessed registry' );

# An empty cache key must never short-circuit the alias reload, and an empty
# alias payload must clear the cached aliases rather than keep stale entries.
{
    local *Developer::Dashboard::Config::path_aliases        = sub { return };
    local $Developer::Dashboard::Folder::PATHS               = DD::Folder::BarePaths->new;
    local $Developer::Dashboard::Folder::CONFIG_ALIASES_KEY  = 'stale-cache-key';
    local %Developer::Dashboard::Folder::CONFIG_ALIASES      = ( leftover => '/leftover' );

    ok( Developer::Dashboard::Folder::_load_configured_aliases(), 'alias loading runs when the cache key cannot be derived' );
    is_deeply( \%Developer::Dashboard::Folder::CONFIG_ALIASES, {}, 'an empty alias payload clears the cached aliases' );
    is( $Developer::Dashboard::Folder::CONFIG_ALIASES_KEY, '', 'the empty cache key is recorded after the reload' );
}

# postman() creates its directory once and reuses it afterwards.
Developer::Dashboard::Folder->configure( paths => $paths );
my $postman = Developer::Dashboard::Folder->postman;
ok( -d $postman, 'postman() creates the collection directory on first use' );
is( Developer::Dashboard::Folder->postman, $postman, 'postman() reuses the existing collection directory' );

# cd() refuses everything it cannot safely enter.
my $cd_no_code = Developer::Dashboard::Folder->cd( $home, 'not-a-callback' );
is( $cd_no_code, undef, 'cd() refuses a non-callback' );

my $cd_unknown = Developer::Dashboard::Folder->cd( 'no-such-folder-alias', sub { return 'ran' } );
is( $cd_unknown, undef, 'cd() refuses an unresolvable folder name' );

my $cd_missing = Developer::Dashboard::Folder->cd( File::Spec->catdir( $home, 'missing-dir' ), sub { return 'ran' } );
is( $cd_missing, undef, 'cd() refuses a path that is not a directory' );

my $locked = File::Spec->catdir( $home, 'locked-dir' );
make_path($locked);
chmod 0000, $locked or die "Unable to chmod $locked: $!";
my $cd_locked = Developer::Dashboard::Folder->cd( $locked, sub { return 'ran' } );
is( $cd_locked, undef, 'cd() gives up when the directory cannot be entered' );

# ls() on an unreadable directory reports nothing instead of dying.
my @locked_items = Developer::Dashboard::Folder->ls($locked);
is( scalar @locked_items, 0, 'ls() reports nothing for a directory it cannot open' );
chmod 0700, $locked or die "Unable to restore mode on $locked: $!";

# The cd() context object exposes a stay() hook that ignores empty values.
my $target = File::Spec->catdir( $home, 'cd-target' );
make_path($target);
my @stayed;
my $cd_result = Developer::Dashboard::Folder->cd(
    $target,
    sub {
        my ($ctx) = @_;
        push @stayed, $ctx->{dir};
        $ctx->{stay}->();
        $ctx->{stay}->('');
        $ctx->{stay}->($home);
        return 'callback-ran';
    }
);
is( $cd_result, 'callback-ran', 'cd() returns the callback result' );
is_deeply( \@stayed, [$target], 'cd() hands the resolved directory to the callback' );

# When the caller directory has been removed there is nowhere to return to, so
# cd() must stay in the target instead of chdir-ing to an empty path.
my $dest = File::Spec->catdir( $home, 'cd-dest' );
make_path($dest);
open my $marker_fh, '>', File::Spec->catfile( $dest, 'marker' ) or die "Unable to write marker: $!";
close $marker_fh or die "Unable to close marker: $!";
{
    my $vanishing = File::Spec->catdir( $home, 'vanishing' );
    make_path($vanishing);
    chdir $vanishing or die "Unable to chdir to $vanishing: $!";
    rmdir $vanishing or die "Unable to remove $vanishing: $!";

    # Capture::Tiny keeps the shelled-out pwd probe's complaint off the harness.
    my ( $stdout, $stderr, $vanished_result ) = capture {
        return Developer::Dashboard::Folder->cd( $dest, sub { return 'entered' } );
    };
    is( $vanished_result, 'entered', 'cd() still runs the callback when the caller directory vanished' );
    ok( -f 'marker', 'cd() stays in the target when there is no caller directory to return to' );
}
chdir $home or die "Unable to chdir back to $home: $!";

# ls() sorts folders before files, breaks ties by name, and reports zero for
# empty files.
my $listing = File::Spec->catdir( $home, 'listing' );
make_path( File::Spec->catdir( $listing, 'sub-alpha' ) );
make_path( File::Spec->catdir( $listing, 'sub-beta' ) );
open my $one_fh, '>', File::Spec->catfile( $listing, 'file-one.txt' ) or die "Unable to write file-one.txt: $!";
print {$one_fh} "content\n" or die "Unable to fill file-one.txt: $!";
close $one_fh or die "Unable to close file-one.txt: $!";
open my $two_fh, '>', File::Spec->catfile( $listing, 'file-two.txt' ) or die "Unable to write file-two.txt: $!";
close $two_fh or die "Unable to close file-two.txt: $!";

my @items = Developer::Dashboard::Folder->ls($listing);
is_deeply(
    [ map { $_->{NAME} } @items ],
    [ qw(sub-alpha sub-beta file-one.txt file-two.txt) ],
    'ls() lists folders before files and sorts same-type entries by name',
);
is_deeply( [ map { $_->{type} } @items ], [ qw(folder folder file file) ], 'ls() classifies folders and files' );
is( $items[3]{size}, 0, 'ls() reports zero size for an empty file' );
ok( $items[2]{size} > 0, 'ls() reports the real size of a non-empty file' );

# ls() refuses unresolvable and non-directory inputs.
my @unknown_items = Developer::Dashboard::Folder->ls('no-such-folder-alias');
is( scalar @unknown_items, 0, 'ls() reports nothing for an unresolvable folder name' );

my @missing_items = Developer::Dashboard::Folder->ls( File::Spec->catdir( $home, 'missing-dir' ) );
is( scalar @missing_items, 0, 'ls() reports nothing for a path that is not a directory' );

my @undef_items = Developer::Dashboard::Folder->ls(undef);
is( scalar @undef_items, 0, 'ls() reports nothing for an undefined folder name' );

my @blank_items = Developer::Dashboard::Folder->ls('');
is( scalar @blank_items, 0, 'ls() reports nothing for an empty folder name' );

# A relative directory name that exists in the cwd resolves as a literal path.
my $relative = 'relative-listing';
make_path( File::Spec->catdir( $home, $relative, 'inner' ) );
my @relative_items = Developer::Dashboard::Folder->ls($relative);
is_deeply( [ map { $_->{NAME} } @relative_items ], ['inner'], 'ls() resolves an existing relative directory name' );

# A named accessor on the class wins over alias and environment lookups.
my @home_items = Developer::Dashboard::Folder->ls('home');
ok( scalar @home_items > 0, 'ls() resolves the named home accessor' );

# Legacy alias resolution is skipped for an invocant without the accessor.
my $foreign = Developer::Dashboard::Folder::_resolve_path( 'DD::Folder::BarePaths', 'runtime_root' );
is( $foreign, undef, 'legacy alias resolution is skipped when the invocant lacks the accessor' );

# locate() walks configured workspace roots, skipping missing roots and files.
{
    my $workspace = File::Spec->catdir( $home, 'workspace' );
    make_path( File::Spec->catdir( $workspace, 'match-me' ) );
    make_path( File::Spec->catdir( $workspace, 'other-thing' ) );
    open my $plain_fh, '>', File::Spec->catfile( $workspace, 'plain.txt' ) or die "Unable to write plain.txt: $!";
    close $plain_fh or die "Unable to close plain.txt: $!";

    local $Developer::Dashboard::Folder::PATHS = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ File::Spec->catdir( $home, 'no-such-workspace' ), $workspace ],
    );

    my @found = Developer::Dashboard::Folder->locate('match');
    is_deeply( \@found, [ File::Spec->catdir( $workspace, 'match-me' ) ], 'locate() finds matching directories and skips files and misses' );

    my @no_parts = Developer::Dashboard::Folder->locate( undef, '' );
    is( scalar @no_parts, 0, 'locate() reports nothing when every name fragment is empty' );
}

{
    local $ENV{HOME}                          = '';
    local $Developer::Dashboard::Folder::PATHS = undef;
    my @no_registry = Developer::Dashboard::Folder->locate('anything');
    is( scalar @no_registry, 0, 'locate() reports nothing without a resolvable path registry' );
}

{
    local $Developer::Dashboard::Folder::PATHS = DD::Folder::StubPaths->new;
    my @no_roots = Developer::Dashboard::Folder->locate('anything');
    is( scalar @no_roots, 0, 'locate() reports nothing when the registry lacks workspace_roots' );
}

# AUTOLOAD ignores destruction, dies on unknown names, and only creates missing
# absolute alias directories.
my $destroy = Developer::Dashboard::Folder->DESTROY;
is( $destroy, undef, 'AUTOLOAD ignores DESTROY' );

my $unknown_error = do { local $@; eval { Developer::Dashboard::Folder->definitely_not_a_folder }; $@ };
like( $unknown_error, qr/Unknown folder 'definitely_not_a_folder'/, 'AUTOLOAD dies for an unknown folder name' );

{
    local $ENV{DEVELOPER_DASHBOARD_PATH_EMPTYENV} = '';
    my $empty_env_error = do { local $@; eval { Developer::Dashboard::Folder->emptyenv }; $@ };
    like( $empty_env_error, qr/Unknown folder 'emptyenv'/, 'an empty environment override does not resolve a folder' );
}

my $created = File::Spec->catdir( $home, 'made-by-autoload' );
Developer::Dashboard::Folder->configure(
    paths   => $paths,
    aliases => {
        blankalias    => '',
        relativealias => 'relative/alias',
        createdalias  => $created,
    },
);
is( Developer::Dashboard::Folder->blankalias,    '',                'an empty alias resolves without creating a directory' );
is( Developer::Dashboard::Folder->relativealias, 'relative/alias',  'a relative alias resolves without creating a directory' );
ok( !-e 'relative/alias', 'AUTOLOAD does not create a relative alias directory' );
is( Developer::Dashboard::Folder->createdalias, $created, 'an absolute alias resolves to its configured path' );
ok( -d $created, 'AUTOLOAD creates a missing absolute alias directory' );
is( Developer::Dashboard::Folder->createdalias, $created, 'an existing absolute alias is returned unchanged' );

# Leave the compatibility layer configured with the plain runtime registry.
Developer::Dashboard::Folder->configure( paths => $paths );

done_testing;

__END__

=pod

=head1 NAME

t/112-folder-coverage.t - branch and condition coverage for the Folder compatibility layer

=head1 PURPOSE

This test drives every decision inside
C<Developer::Dashboard::Folder>: the alias configuration entry point, the
registry-backed runtime accessors, the lazily built default registry, the
config-backed alias cache, C<cd>, C<ls>, C<locate>, literal and named path
resolution, and the C<AUTOLOAD> alias resolver. It asserts the observable
behavior of each of those paths, including the defensive ones that only run
when a registry, directory, or alias value is missing.

=head1 WHY IT EXISTS

The Folder layer is the compatibility surface older bookmark and helper code
still calls, so its fallbacks matter: an unresolvable name must return nothing
instead of dying, an unreadable directory must not abort a listing, a vanished
caller directory must not send the process to an empty path, and an alias
payload that disappears must clear the cache instead of leaving stale entries.
Those paths were previously unexercised, which meant a regression in any of
them would have shipped silently. This file exists to keep them executed and
asserted, and to hold the module at full branch and condition coverage.

=head1 WHEN TO USE

Use this file when changing folder-name resolution, the legacy or configured
alias maps, the environment path overrides, the directory listing or workspace
search helpers, or the lazily constructed default path registry.

=head1 HOW TO USE

Run C<prove -lv t/112-folder-coverage.t> while iterating on the Folder layer,
then keep it green under C<prove -lr t> and under the repository coverage gate
before release.

=head1 WHAT USES IT

The repository test suite and the coverage gate use this file to keep the
Folder compatibility layer's resolution and fallback behavior intact.

=head1 EXAMPLES

Example 1:

  prove -lv t/112-folder-coverage.t

Run the Folder compatibility coverage checks on their own.

Example 2:

  prove -lr t

Run them inside the full repository suite before release.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/112-folder-coverage.t

Recheck the Folder branch and condition coverage this file is responsible for.

=cut
