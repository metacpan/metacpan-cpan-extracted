#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::InternalCLI;

# Hermetic, cwd-isolated runtime. Config root resolution walks the cwd's
# deepest .developer-dashboard layer, so we must chdir into the temp home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $PKG = 'Developer::Dashboard::InternalCLI';

# Alias the module's (mostly private) subs into main:: for readable direct
# calls. Internal bareword calls inside the module still resolve through the
# package symbol table at runtime, so `local *PKG::sub` mocks below continue to
# intercept them regardless of these convenience aliases.
my @aliased = qw(
  canonical_helper_name helper_path dashboard_core_path helper_content
  ensure_helpers ensure_dashboard_core ensure_helper
  _stage_managed_helper _should_defer_windows_helper_refresh
  _running_helper_matches_target _normalized_helper_path
  _write_helper_atomically _replace_helper_file
  _remove_retired_managed_helper _remove_legacy_managed_flat_helpers
  _managed_helper_content _managed_helper_marker _managed_helper_version_marker
  _is_dashboard_managed_helper _is_managed_helper_target
  _managed_helper_file_current _helper_asset_path
  _repo_private_cli_root_candidates _module_source_path
  _module_source_looks_like_blib_build _abs_existing_path
  _shared_private_cli_root _shared_private_cli_root_candidates
  _looks_like_private_cli_root _private_cli_root_has_dashboard_core
  _home_private_cli_root_candidates _helper_uses_dashboard_core
  _helper_install_root _helper_parent_root
);
{
    no strict 'refs';
    for my $name (@aliased) {
        *{"main::$name"} = \&{"${PKG}::${name}"};
    }
}

# Path helpers.
sub cf { File::Spec->catfile(@_) }
sub cd { File::Spec->catdir(@_) }

# fresh($label): isolated PathRegistry rooted at a fresh home subdir.
sub fresh {
    my ($label) = @_;
    my $dir = cd( $home, $label );
    make_path($dir);
    return Developer::Dashboard::PathRegistry->new( home => $dir );
}

# wf($path, $content): write a file.
sub wf {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# we($path): write a zero-byte file.
sub we {
    my ($path) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    close $fh or die "Unable to close $path: $!";
    return $path;
}

my $paths = fresh('main-home');

# ---------------------------------------------------------------------------
# canonical_helper_name: empty/undef guard (line 51) + condition operands.
# ---------------------------------------------------------------------------
is( canonical_helper_name(undef),             '',   'canonical_helper_name undef returns empty' );
is( canonical_helper_name(''),                '',   'canonical_helper_name empty string returns empty' );
is( canonical_helper_name('jq'),              'jq', 'canonical_helper_name passes through a built-in name' );
is( canonical_helper_name('pjq'),             'jq', 'canonical_helper_name resolves an alias' );
is( canonical_helper_name('nonexistent-xyz'), '',   'canonical_helper_name rejects an unknown name' );

# ---------------------------------------------------------------------------
# helper_path / dashboard_core_path: || die guards (lines 65, 78) + success.
# ---------------------------------------------------------------------------
like( ( eval { helper_path( name => 'jq' ); 1 } ? '' : $@ ), qr/Missing paths registry/, 'helper_path dies without paths' );
ok( helper_path( paths => $paths, name => 'jq' ), 'helper_path resolves with paths' );
like( ( eval { dashboard_core_path(); 1 } ? '' : $@ ), qr/Missing paths registry/, 'dashboard_core_path dies without paths' );
ok( dashboard_core_path( paths => $paths ), 'dashboard_core_path resolves with paths' );

# ---------------------------------------------------------------------------
# helper_content: die guard (line 90) + open/close success (lines 92, 94).
# ---------------------------------------------------------------------------
like( helper_content('jq'), qr/./, 'helper_content loads a helper asset body' );
like( helper_content('_dashboard-core'), qr/./, 'helper_content loads the shared core body' );
like( ( eval { helper_content('nonexistent-xyz'); 1 } ? '' : $@ ), qr/Unsupported helper command/, 'helper_content dies on unsupported name' );

# ---------------------------------------------------------------------------
# _helper_uses_dashboard_core: guard (line 474) + delegating regex.
# ---------------------------------------------------------------------------
is( _helper_uses_dashboard_core(undef), 0, '_helper_uses_dashboard_core undef is false' );
is( _helper_uses_dashboard_core(''),    0, '_helper_uses_dashboard_core empty is false' );
is( _helper_uses_dashboard_core('jq'),  0, '_helper_uses_dashboard_core non-delegating helper is false' );
is( _helper_uses_dashboard_core('log'), 1, '_helper_uses_dashboard_core delegating helper is true' );

# ---------------------------------------------------------------------------
# _normalized_helper_path: guard (line 270) + resolved/unresolved (line 272).
# ---------------------------------------------------------------------------
is( _normalized_helper_path(undef), '', '_normalized_helper_path undef returns empty' );
is( _normalized_helper_path(''),    '', '_normalized_helper_path empty returns empty' );
ok( _normalized_helper_path($home) ne '', '_normalized_helper_path resolves an existing path' );
ok( _normalized_helper_path( cf( $home, 'ghost-normalize-dir', 'leaf' ) ) ne '', '_normalized_helper_path falls back to the raw path when abs_path cannot resolve it' );

# ---------------------------------------------------------------------------
# _running_helper_matches_target: guards (257, 259) + comparison (260).
# ---------------------------------------------------------------------------
is( _running_helper_matches_target(undef), 0, '_running_helper_matches_target undef target' );
is( _running_helper_matches_target(''),    0, '_running_helper_matches_target empty target' );
{
    delete local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER};
    is( _running_helper_matches_target( cf( $home, 'rt' ) ), 0, '_running_helper_matches_target with no running marker' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER} = '';
    is( _running_helper_matches_target( cf( $home, 'rt' ) ), 0, '_running_helper_matches_target with empty running marker' );
}
{
    my $t = cf( $home, 'rt-match' );
    local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER} = $t;
    is( _running_helper_matches_target($t), 1, '_running_helper_matches_target matches the running helper' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER} = cf( $home, 'rt-b' );
    is( _running_helper_matches_target( cf( $home, 'rt-a' ) ), 0, '_running_helper_matches_target rejects a different helper' );
}

# ---------------------------------------------------------------------------
# _should_defer_windows_helper_refresh: name condition (line 245).
# ---------------------------------------------------------------------------
is( _should_defer_windows_helper_refresh( 'jq', cf( $home, 'x' ) ), 0, '_should_defer_windows_helper_refresh returns 0 off Windows' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { 1 };
    my $t = cf( $home, 'defer-target' );
    is( _should_defer_windows_helper_refresh( '_dashboard-core', $t ), 1, '_should_defer_windows_helper_refresh always defers core' );
    {
        delete local $ENV{DEVELOPER_DASHBOARD_RUNNING_HELPER};
        is( _should_defer_windows_helper_refresh( 'jq', $t ), 0, '_should_defer_windows_helper_refresh checks the running helper for non-core' );
        is( _should_defer_windows_helper_refresh( undef, $t ), 0, '_should_defer_windows_helper_refresh tolerates an undef helper name' );
    }
}

# ---------------------------------------------------------------------------
# _abs_existing_path: guard (line 645) + abs_path fallback (line 647).
# ---------------------------------------------------------------------------
is( _abs_existing_path(undef), '', '_abs_existing_path undef returns empty' );
is( _abs_existing_path(''),    '', '_abs_existing_path empty returns empty' );
is( _abs_existing_path( cf( $home, 'no-such-abs' ) ), cf( $home, 'no-such-abs' ), '_abs_existing_path returns a missing path unchanged' );
ok( _abs_existing_path($home) ne '', '_abs_existing_path canonicalizes an existing path' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::abs_path = sub { return undef };
    is( _abs_existing_path($home), $home, '_abs_existing_path falls back to the original path when abs_path yields undef' );
}

# ---------------------------------------------------------------------------
# _is_dashboard_managed_helper: core detection (line 488) + POD heuristic (492).
# ---------------------------------------------------------------------------
is( _is_dashboard_managed_helper( "random text\n", '_dashboard-core' ), 0, '_is_dashboard_managed_helper core: no legacy marker' );
is( _is_dashboard_managed_helper( "Missing built-in dashboard command\nfoo\n", '_dashboard-core' ), 0, '_is_dashboard_managed_helper core: missing SeededPages marker' );
ok( _is_dashboard_managed_helper( "Missing built-in dashboard command\nDeveloper::Dashboard::CLI::SeededPages\n", '_dashboard-core' ), '_is_dashboard_managed_helper core: both legacy markers present' );
is( _is_dashboard_managed_helper( "LAZY-THIN-CMD only body\n", 'jq' ), 0, '_is_dashboard_managed_helper: LAZY marker without product name' );
ok( _is_dashboard_managed_helper( "LAZY-THIN-CMD\nDeveloper Dashboard\n", 'jq' ), '_is_dashboard_managed_helper: both POD heuristics present' );
is( _is_dashboard_managed_helper( "plain body\n", 'jq' ), 0, '_is_dashboard_managed_helper: unrelated content is unmanaged' );

# ---------------------------------------------------------------------------
# _is_managed_helper_target: guard operands (line 525) + resolution.
# ---------------------------------------------------------------------------
is( _is_managed_helper_target( undef, '/x' ), 0, '_is_managed_helper_target requires paths' );
is( _is_managed_helper_target( $paths, undef ), 0, '_is_managed_helper_target requires a defined target' );
is( _is_managed_helper_target( $paths, '' ), 0, '_is_managed_helper_target rejects an empty target' );
ok( _is_managed_helper_target( $paths, cf( _helper_install_root($paths), 'jq' ) ), '_is_managed_helper_target accepts a path under the managed root' );
ok( !_is_managed_helper_target( $paths, cf( $home, 'outside-managed' ) ), '_is_managed_helper_target rejects a path outside the managed root' );

# ---------------------------------------------------------------------------
# _managed_helper_file_current: guard (541), read success (542/544),
# ownership (545), version marker (546).
# ---------------------------------------------------------------------------
is( _managed_helper_file_current( undef, 'jq' ), 0, '_managed_helper_file_current undef path' );
is( _managed_helper_file_current( '', 'jq' ),    0, '_managed_helper_file_current empty path' );
is( _managed_helper_file_current( cf( $home, 'no-such-current' ), 'jq' ), 0, '_managed_helper_file_current missing file' );
{
    my $marker  = _managed_helper_marker('jq');
    my $current = cf( $home, 'mfc-current' );
    wf( $current, _managed_helper_content('jq') );
    is( _managed_helper_file_current( $current, 'jq' ), 1, '_managed_helper_file_current true for a current managed helper' );

    my $stale = cf( $home, 'mfc-stale' );
    wf( $stale, "#!/usr/bin/env perl\n$marker\nbody\n" );
    is( _managed_helper_file_current( $stale, 'jq' ), 0, '_managed_helper_file_current false for a managed helper without the version marker' );

    my $user = cf( $home, 'mfc-user' );
    wf( $user, "hello\n" );
    is( _managed_helper_file_current( $user, 'jq' ), 0, '_managed_helper_file_current false for a user-owned file' );
}

# ---------------------------------------------------------------------------
# _managed_helper_content: version-marker short-circuit (line 437).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $marker  = _managed_helper_marker('jq');
    my $vmarker = _managed_helper_version_marker();
    {
        local *Developer::Dashboard::InternalCLI::helper_content = sub { return "#!/usr/bin/env perl\n$marker\n$vmarker\nbody\n" };
        my $content = _managed_helper_content('jq');
        like( $content, qr/\Q$vmarker\E/, '_managed_helper_content returns content unchanged when the version marker is already present' );
    }
    {
        local *Developer::Dashboard::InternalCLI::helper_content = sub { return "#!/usr/bin/env perl\n$marker\nbody\n" };
        my $content = _managed_helper_content('jq');
        like( $content, qr/\Q$vmarker\E/, '_managed_helper_content injects the version marker when only the ownership marker is present' );
    }
}

# ---------------------------------------------------------------------------
# _stage_managed_helper: die guards (212, 213), zero-byte + managed-target
# condition (218), read/ownership (222/224/225).
# ---------------------------------------------------------------------------
like( ( eval { _stage_managed_helper( name => 'jq' ); 1 } ? '' : $@ ), qr/Missing helper target/, '_stage_managed_helper requires a target' );
like( ( eval { _stage_managed_helper( target => cf( $home, 't' ) ); 1 } ? '' : $@ ), qr/Missing helper name/, '_stage_managed_helper requires a name' );
{
    my $p    = fresh('stage-home');
    my $root = _helper_install_root($p);
    make_path($root);

    # Zero-byte file under the managed root: overwrite-and-return-1 branch.
    my $inside = cf( $root, 'jq' );
    we($inside);
    is( _stage_managed_helper( paths => $p, name => 'jq', target => $inside ), 1, '_stage_managed_helper rewrites a zero-byte managed-root helper' );

    # Now the managed helper is byte-identical: same-content early return.
    is( _stage_managed_helper( paths => $p, name => 'jq', target => $inside ), 0, '_stage_managed_helper skips a byte-identical managed helper' );

    # Zero-byte file outside the managed root: not a managed target.
    my $outside = cf( $home, 'loose-zero-stage' );
    we($outside);
    is( _stage_managed_helper( paths => $p, name => 'jq', target => $outside ), 0, '_stage_managed_helper preserves a zero-byte file outside the managed root' );

    # Non-empty user-owned file: preserved.
    my $userfile = cf( $home, 'loose-user-stage' );
    wf( $userfile, "user script\n" );
    is( _stage_managed_helper( paths => $p, name => 'jq', target => $userfile ), 0, '_stage_managed_helper preserves a user-owned helper file' );
}

# ---------------------------------------------------------------------------
# _write_helper_atomically: open failure (line 285) + success/close (287).
# ---------------------------------------------------------------------------
like( ( eval { _write_helper_atomically( cf( $home, 'no-such-dir', 'file' ), 'x' ); 1 } ? '' : $@ ), qr/Unable to write/, '_write_helper_atomically dies when the temp file cannot be opened' );
{
    my $target = cf( $home, 'atomic-write' );
    ok( _write_helper_atomically( $target, "content\n" ), '_write_helper_atomically writes a helper body' );
    ok( -f $target, '_write_helper_atomically leaves the target in place' );
}

# ---------------------------------------------------------------------------
# _replace_helper_file: non-Windows failure (302 A-false, 310 false), the
# Windows retry branch (302/303/306) and its escalation paths.
# ---------------------------------------------------------------------------
like( ( eval { _replace_helper_file( cf( $home, 'r1-src' ), cf( $home, 'r1-tgt' ) ); 1 } ? '' : $@ ), qr/Unable to rename/, '_replace_helper_file dies when a plain rename fails' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { 1 };

    # 302 is_windows true but target absent -> skip the retry block.
    like( ( eval { _replace_helper_file( cf( $home, 'r2-src' ), cf( $home, 'r2-tgt' ) ); 1 } ? '' : $@ ), qr/Unable to rename/, '_replace_helper_file (Windows) dies when the target is absent and rename fails' );

    # Windows retry succeeds on the second rename.
    {
        my @rename = ( 0, 1 );
        local *Developer::Dashboard::InternalCLI::_rename_path = sub { return shift(@rename) // 0 };
        my $src = wf( cf( $home, 'r3-src' ), "s\n" );
        my $tgt = wf( cf( $home, 'r3-tgt' ), "t\n" );
        is( _replace_helper_file( $src, $tgt ), 1, '_replace_helper_file retries the Windows rename after removing the target' );
    }

    # Windows retry fails; source still present -> cleanup then die.
    {
        local *Developer::Dashboard::InternalCLI::_rename_path = sub { return 0 };
        my $src = wf( cf( $home, 'r4-src' ), "s\n" );
        my $tgt = wf( cf( $home, 'r4-tgt' ), "t\n" );
        like( ( eval { _replace_helper_file( $src, $tgt ); 1 } ? '' : $@ ), qr/Unable to rename/, '_replace_helper_file dies after a failed Windows retry with an existing source' );
    }

    # Windows target removal fails -> die at the unlink guard.
    {
        local *Developer::Dashboard::InternalCLI::_rename_path = sub { return 0 };
        local *Developer::Dashboard::InternalCLI::_unlink_path = sub { return 0 };
        my $src = wf( cf( $home, 'r5-src' ), "s\n" );
        my $tgt = wf( cf( $home, 'r5-tgt' ), "t\n" );
        like( ( eval { _replace_helper_file( $src, $tgt ); 1 } ? '' : $@ ), qr/before Windows helper replace retry/, '_replace_helper_file dies when the Windows target cannot be removed' );
    }
}

# ---------------------------------------------------------------------------
# _remove_retired_managed_helper: die guards (342, 343), non-file (346),
# ownership (350), removal (351).
# ---------------------------------------------------------------------------
like( ( eval { _remove_retired_managed_helper( name => 'skill' ); 1 } ? '' : $@ ), qr/Missing paths registry/, '_remove_retired_managed_helper requires paths' );
like( ( eval { _remove_retired_managed_helper( paths => $paths ); 1 } ? '' : $@ ), qr/Missing retired helper name/, '_remove_retired_managed_helper requires a name' );
{
    my $p    = fresh('retire-dir');
    my $root = _helper_install_root($p);
    make_path( cf( $root, 'skill' ) );    # a directory where the helper would live
    is( _remove_retired_managed_helper( paths => $p, name => 'skill' ), 0, '_remove_retired_managed_helper ignores a non-file target' );
}
{
    my $p    = fresh('retire-user');
    my $root = _helper_install_root($p);
    make_path($root);
    wf( cf( $root, 'skill' ), "user script\n" );
    is( _remove_retired_managed_helper( paths => $p, name => 'skill' ), 0, '_remove_retired_managed_helper preserves a user-owned retired file' );
}
{
    my $p    = fresh('retire-managed');
    my $root = _helper_install_root($p);
    make_path($root);
    wf( cf( $root, 'skill' ), "#!/usr/bin/env perl\n" . _managed_helper_marker('skill') . "\nbody\n" );
    is( _remove_retired_managed_helper( paths => $p, name => 'skill' ), 1, '_remove_retired_managed_helper removes a managed retired helper' );
    ok( !-e cf( $root, 'skill' ), '_remove_retired_managed_helper unlinks the managed retired helper' );
}

# ---------------------------------------------------------------------------
# _remove_legacy_managed_flat_helpers: die guard (362), non-file condition
# (367), read/removal (368/370/372).
# ---------------------------------------------------------------------------
like( ( eval { _remove_legacy_managed_flat_helpers(); 1 } ? '' : $@ ), qr/Missing paths registry/, '_remove_legacy_managed_flat_helpers requires paths' );
{
    my $p      = fresh('legacy');
    my $parent = _helper_parent_root($p);
    make_path($parent);
    make_path( cf( $parent, 'jq' ) );    # directory at a legacy helper name
    wf( cf( $parent, 'config' ), "#!/usr/bin/env perl\n" . _managed_helper_marker('config') . "\nbody\n" );
    wf( cf( $parent, 'auth' ),   "user script\n" );
    my $removed = _remove_legacy_managed_flat_helpers( paths => $p );
    is( ref($removed), 'ARRAY', '_remove_legacy_managed_flat_helpers returns an array reference' );
    ok( -d cf( $parent, 'jq' ),   '_remove_legacy_managed_flat_helpers leaves a directory in place' );
    ok( !-e cf( $parent, 'config' ), '_remove_legacy_managed_flat_helpers removes a managed legacy helper' );
    ok( -e cf( $parent, 'auth' ), '_remove_legacy_managed_flat_helpers preserves a user-owned legacy file' );
}

# ---------------------------------------------------------------------------
# ensure_dashboard_core: die guard (141), current check (146), stage (147).
# ---------------------------------------------------------------------------
like( ( eval { ensure_dashboard_core(); 1 } ? '' : $@ ), qr/Missing paths registry/, 'ensure_dashboard_core requires paths' );
{
    my $p = fresh('edc-fresh');
    my $written = ensure_dashboard_core( paths => $p );
    is( ref($written), 'ARRAY', 'ensure_dashboard_core returns an array reference' );
    ok( scalar(@$written) >= 1, 'ensure_dashboard_core stages the core on the first run' );
    is_deeply( ensure_dashboard_core( paths => $p ), [], 'ensure_dashboard_core is a no-op once the core is current' );
}
{
    my $p    = fresh('edc-dir');
    my $root = _helper_install_root($p);
    make_path( cf( $root, '_dashboard-core' ) );    # a directory blocks the core file
    is_deeply( ensure_dashboard_core( paths => $p ), [], 'ensure_dashboard_core writes nothing when the core path is a directory' );
}

# ---------------------------------------------------------------------------
# ensure_helper: die guards (163, 165), core stage (174), staging (189).
# ---------------------------------------------------------------------------
like( ( eval { ensure_helper( name => 'log' ); 1 } ? '' : $@ ), qr/Missing paths registry/, 'ensure_helper requires paths' );
like( ( eval { ensure_helper( paths => $paths, name => 'nonexistent-xyz' ); 1 } ? '' : $@ ), qr/Unsupported helper command/, 'ensure_helper rejects an unknown helper' );
{
    my $p = fresh('eh-fresh-core');
    my $written = ensure_helper( paths => $p, name => 'log' );
    ok( scalar(@$written) >= 1, 'ensure_helper stages the core and a delegating helper on the first run' );
}
{
    my $p    = fresh('eh-core-dir');
    my $root = _helper_install_root($p);
    make_path( cf( $root, '_dashboard-core' ) );    # a directory blocks the core stage
    my $written = ensure_helper( paths => $p, name => 'log' );
    is( ref($written), 'ARRAY', 'ensure_helper tolerates a directory at the core path' );
}
{
    my $p = fresh('eh-jq-fresh');
    my $written = ensure_helper( paths => $p, name => 'jq' );
    ok( scalar(@$written) >= 1, 'ensure_helper stages a standalone helper' );
}
{
    my $p    = fresh('eh-jq-dir');
    my $root = _helper_install_root($p);
    make_path( cf( $root, 'jq' ) );    # a directory blocks the helper stage
    my $written = ensure_helper( paths => $p, name => 'jq' );
    is( ref($written), 'ARRAY', 'ensure_helper preserves a directory at the helper path' );
}

# ---------------------------------------------------------------------------
# ensure_helper on Windows: the locked-helper short-circuit (lines 182-186).
# ---------------------------------------------------------------------------
{
    my $p = fresh('eh-win');
    ensure_helper( paths => $p, name => 'log' );    # non-Windows pre-stage (managed core + log)
    my $logf = cf( _helper_install_root($p), 'log' );
    ok( -f $logf, 'ensure_helper pre-stages the delegating helper' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::InternalCLI::is_windows = sub { 1 };
        is( ref( ensure_helper( paths => $p, name => 'log' ) ), 'ARRAY', 'ensure_helper (Windows) short-circuits on an already-managed delegating helper' );
        wf( $logf, "hello\n" );
        is( ref( ensure_helper( paths => $p, name => 'log' ) ), 'ARRAY', 'ensure_helper (Windows) continues past the short-circuit for an unmanaged helper' );
    }
}
{
    my $p = fresh('eh-win-jq');
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { 1 };
    is( ref( ensure_helper( paths => $p, name => 'jq' ) ), 'ARRAY', 'ensure_helper (Windows) skips the lock check for a non-delegating helper' );
}
{
    my $p = fresh('eh-win-fresh');
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { 1 };
    is( ref( ensure_helper( paths => $p, name => 'log' ) ), 'ARRAY', 'ensure_helper (Windows) skips the lock check when the target is absent' );
}

# ---------------------------------------------------------------------------
# ensure_helpers: die guard (105) + skip-name filter (line 106).
# ---------------------------------------------------------------------------
like( ( eval { ensure_helpers(); 1 } ? '' : $@ ), qr/Missing paths registry/, 'ensure_helpers requires paths' );
{
    my $p = fresh('ensure-all');
    my $written = ensure_helpers( paths => $p, skip_names => [ undef, '', 'jq' ] );
    is( ref($written), 'ARRAY', 'ensure_helpers returns an array reference and tolerates undef/empty skip names' );

    is( ref( ensure_helpers( paths => fresh('ensure-all-noskip') ) ), 'ARRAY', 'ensure_helpers stages every helper when no skip list is supplied' );
}

# ---------------------------------------------------------------------------
# _repo_private_cli_root_candidates: undef/empty filtering (line 613).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my @seq = ( undef, '', cd( $home, 'cand-a' ), cd( $home, 'cand-b' ) );
    local *Developer::Dashboard::InternalCLI::_abs_existing_path = sub { return shift @seq };
    is_deeply(
        [ _repo_private_cli_root_candidates() ],
        [ cd( $home, 'cand-a' ), cd( $home, 'cand-b' ) ],
        '_repo_private_cli_root_candidates filters out undef and empty candidates',
    );
}

# ---------------------------------------------------------------------------
# _module_source_path: lazy assignment (line 622) + normal read.
# ---------------------------------------------------------------------------
is( _module_source_looks_like_blib_build(), 0, '_module_source_looks_like_blib_build is false for a source checkout' );
{
    local $Developer::Dashboard::InternalCLI::MODULE_SOURCE_PATH = undef;
    my $resolved = _module_source_path();
    ok( defined $resolved && $resolved ne '', '_module_source_path lazily resolves the module path when unset' );
}

# ---------------------------------------------------------------------------
# _module_source_looks_like_blib_build: guard operands (line 633).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    {
        local *Developer::Dashboard::InternalCLI::_module_source_path = sub { return undef };
        is( _module_source_looks_like_blib_build(), 0, '_module_source_looks_like_blib_build tolerates an undef source path' );
    }
    {
        local *Developer::Dashboard::InternalCLI::_module_source_path = sub { return '' };
        is( _module_source_looks_like_blib_build(), 0, '_module_source_looks_like_blib_build tolerates an empty source path' );
    }
}

# ---------------------------------------------------------------------------
# _helper_asset_path: repo-candidate loop (559/561), blib loop (565/567),
# and the shared-candidate loop (572), including undef/empty roots.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $good = cd( $home, 'asset-repo' );
    make_path($good);
    wf( cf( $good, 'jq' ), "asset\n" );
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root            = sub { return cd( $home, 'asset-repo-nope' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates = sub { return ( undef, '', $good ) };
    is( _helper_asset_path('jq'), cf( $good, 'jq' ), '_helper_asset_path resolves a repo-candidate root after skipping undef/empty entries' );
}
{
    no warnings 'redefine';
    my $empty = cd( $home, 'asset-blib-empty' );
    my $good  = cd( $home, 'asset-blib-good' );
    make_path($empty);
    make_path($good);
    wf( cf( $good, 'jq' ), "asset\n" );
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root              = sub { return cd( $home, 'asset-blib-nope' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates   = sub { return () };
    local *Developer::Dashboard::InternalCLI::_module_source_looks_like_blib_build = sub { return 1 };
    local *Developer::Dashboard::InternalCLI::_shared_private_cli_root_candidates = sub { return ( undef, '', $empty, $good ) };
    is( _helper_asset_path('jq'), cf( $good, 'jq' ), '_helper_asset_path resolves a shared blib-build root' );
}
{
    no warnings 'redefine';
    my $empty = cd( $home, 'asset-shared-empty' );
    my $good  = cd( $home, 'asset-shared-good' );
    make_path($empty);
    make_path($good);
    wf( cf( $good, 'jq' ), "asset\n" );
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root              = sub { return cd( $home, 'asset-shared-nope' ) };
    local *Developer::Dashboard::InternalCLI::_repo_private_cli_root_candidates   = sub { return () };
    local *Developer::Dashboard::InternalCLI::_module_source_looks_like_blib_build = sub { return 0 };
    local *Developer::Dashboard::InternalCLI::_shared_private_cli_root_candidates = sub { return ( undef, '', $empty, $good ) };
    is( _helper_asset_path('jq'), cf( $good, 'jq' ), '_helper_asset_path resolves a shared install root' );
}

# ---------------------------------------------------------------------------
# _shared_private_cli_root: undef/empty candidate skipping (line 657).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $core_dir = cd( $home, 'shared-core' );
    make_path($core_dir);
    wf( cf( $core_dir, '_dashboard-core' ), "core\n" );
    local *Developer::Dashboard::InternalCLI::_shared_private_cli_root_candidates = sub { return ( undef, '', $core_dir ) };
    is( _shared_private_cli_root(), $core_dir, '_shared_private_cli_root skips undef/empty candidates and returns a core-bearing root' );
}

# ---------------------------------------------------------------------------
# _shared_private_cli_root_candidates: module-root condition (line 676).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    {
        local *Developer::Dashboard::InternalCLI::_module_install_lib_root = sub { return undef };
        is( ref( [ _shared_private_cli_root_candidates() ] ), 'ARRAY', '_shared_private_cli_root_candidates tolerates an undef module root' );
    }
    {
        local *Developer::Dashboard::InternalCLI::_module_install_lib_root = sub { return '' };
        is( ref( [ _shared_private_cli_root_candidates() ] ), 'ARRAY', '_shared_private_cli_root_candidates tolerates an empty module root' );
    }
    is( ref( [ _shared_private_cli_root_candidates() ] ), 'ARRAY', '_shared_private_cli_root_candidates includes the resolved module root' );
}

# ---------------------------------------------------------------------------
# _looks_like_private_cli_root: guard (732) + trailing-segment check (734).
# ---------------------------------------------------------------------------
is( _looks_like_private_cli_root(undef), 0, '_looks_like_private_cli_root undef' );
is( _looks_like_private_cli_root(''),    0, '_looks_like_private_cli_root empty' );
is( _looks_like_private_cli_root( cd( $home, 'foo', 'bar' ) ), 0, '_looks_like_private_cli_root rejects a non private-cli tail' );
{
    my $pcli = cd( $home, 'stuff', 'private-cli' );
    make_path($pcli);
    is( _looks_like_private_cli_root($pcli), 0, '_looks_like_private_cli_root requires the core payload under a private-cli tail' );
}

# ---------------------------------------------------------------------------
# _private_cli_root_has_dashboard_core: guard (line 745) + detection.
# ---------------------------------------------------------------------------
is( _private_cli_root_has_dashboard_core(undef), 0, '_private_cli_root_has_dashboard_core undef' );
is( _private_cli_root_has_dashboard_core(''),    0, '_private_cli_root_has_dashboard_core empty' );
is( _private_cli_root_has_dashboard_core( cd( $home, 'no-such-cli-root' ) ), 0, '_private_cli_root_has_dashboard_core missing directory' );
{
    my $has = cd( $home, 'has-core' );
    make_path($has);
    wf( cf( $has, '_dashboard-core' ), "core\n" );
    ok( _private_cli_root_has_dashboard_core($has), '_private_cli_root_has_dashboard_core detects the core payload' );
}

# ---------------------------------------------------------------------------
# _home_private_cli_root_candidates: HOME guard operands (line 757).
# ---------------------------------------------------------------------------
{
    delete local $ENV{HOME};
    is_deeply( [ _home_private_cli_root_candidates() ], [], '_home_private_cli_root_candidates returns nothing when HOME is unset' );
}
{
    local $ENV{HOME} = '';
    is_deeply( [ _home_private_cli_root_candidates() ], [], '_home_private_cli_root_candidates returns nothing when HOME is empty' );
}
{
    my @candidates = _home_private_cli_root_candidates();
    is( scalar @candidates, 2, '_home_private_cli_root_candidates returns both staged home roots when HOME is set' );
}

done_testing;

__END__

=head1 NAME

t/96-internalcli-coverage.t - branch and condition coverage closure for the private helper manager

=head1 PURPOSE

This test drives the residual branch and condition edges of
C<Developer::Dashboard::InternalCLI> so the module holds at 100 percent on every
Devel::Cover metric. It exercises helper-name normalization, asset loading,
managed-helper staging and replacement, retired/legacy helper removal, private
CLI root resolution, and the Windows-specific locked-helper handling that never
runs on the Linux test host without a mocked platform probe.

=head1 WHY IT EXISTS

The helper-staging module is almost entirely defensive: most of its work is
deciding when NOT to overwrite a user-owned or already-current file, and its
Windows retry paths cannot execute on the coverage host. Those decision edges
are easy to leave half-covered from the higher-level CLI flows, so this file
pins each one - the empty-name guards, the zero-byte managed-target rewrite, the
same-content skip, the atomic-write open failure, the rename/unlink replacement
retries under a faked C<is_windows()>, and the undef/empty candidate filtering -
with a direct, hermetic assertion.

=head1 WHEN TO USE

Use this file when changing which built-in helpers exist, how managed helpers
are staged, replaced, or removed, how private CLI asset roots are discovered, or
the Windows helper-locking behavior. Re-run it whenever a coverage report shows
InternalCLI dropping below 100 percent on branch or condition.

=head1 HOW TO USE

Run C<perl -Ilib t/96-internalcli-coverage.t> or C<prove -lv
t/96-internalcli-coverage.t> while iterating. Confirm the branch and condition
columns with C<cover -report text -select_re 'InternalCLI\.pm' -coverage branch
-coverage condition> after a coverage run, and keep it green under C<prove -lr
t> before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep InternalCLI's staging and
root-resolution decisions from regressing.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/96-internalcli-coverage.t

Run the focused coverage-closure test directly from a source checkout.

Example 2:

  prove -lv t/96-internalcli-coverage.t

Run the same test through the harness with verbose per-assertion output.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck InternalCLI under the repository coverage gate rather than a load-only
probe.

Example 4:

  prove -lr t

Put any InternalCLI change back through the entire repository suite before
release.

=cut
