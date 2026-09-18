#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Digest::MD5 ();
use POSIX qw(WNOHANG);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PaxCache;

# Loaded eagerly here (rather than left to _pax_bin's own lazy `require`) so
# that later blocks in this file can `local *Developer::Dashboard::InternalCLI::*`
# to force _pax_bin's degradation paths: overriding a glob BEFORE the module
# has ever been require'd gets silently clobbered the moment _pax_bin's own
# `require Developer::Dashboard::InternalCLI` first fires and (re)defines the
# real subs over the override, mid-scope, inside the very call being tested.
require Developer::Dashboard::InternalCLI;

# Hermetic runtime: isolated home so PathRegistry::home_cache_root resolves
# into a controlled scratch tree, never the real ~/.developer-dashboard.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

# DD-936: resolve() defaults to disabled (returns undef immediately) unless
# DD_PAX=on. This file exercises resolve()'s pre-existing cache/spawn
# mechanics, so opt in for the whole file; the DD_PAX-off default itself is
# asserted separately, further down, with its own explicit local override.
local $ENV{DD_PAX} = 'on';

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

# A fake PATH containing a stub 'pax' script that just records its argv and
# writes a fixed-content "binary" - lets us test the cache mechanics without
# ever invoking a real, minutes-long PAX build.
#
# Each block gets its OWN fresh bin dir (never a shared, mutable script
# path) - a background compile spawned by one block is a detached process
# this test does not always wait to exit, and rewriting a still-in-flight
# process's script file out from under it makes that leftover process
# execute whatever content happens to be on disk at ITS exec time, not the
# content its own args were spawned against. That cross-block contamination
# is what produced a phantom second compile-log entry during AC-5's
# development (source paths from two different blocks in one log file).
sub write_fake_pax {
    my (%opts) = @_;
    my $bin_dir = tempdir( CLEANUP => 1 );
    my $pax_path = File::Spec->catfile( $bin_dir, 'pax' );
    my $sleep_seconds = $opts{sleep} || 0;
    my $log_file      = $opts{log_file} || File::Spec->catfile( $bin_dir, 'pax-calls.log' );
    open my $fh, '>', $pax_path or die "Unable to write fake pax: $!";
    print {$fh} "#!/usr/bin/env perl\n";
    print {$fh} "open my \$log, '>>', '$log_file' or die \$!;\n";
    print {$fh} "print {\$log} \"\$\$ \@ARGV\\n\"; close \$log;\n";
    print {$fh} "sleep($sleep_seconds);\n" if $sleep_seconds;
    print {$fh} "my \$out;\n";
    print {$fh} "for (my \$i = 0; \$i < \@ARGV; \$i++) { \$out = \$ARGV[\$i+1] if \$ARGV[\$i] eq '-o'; }\n";
    print {$fh} "if (\$out) { open my \$ofh, '>', \$out or die \$!; print {\$ofh} \"fake-compiled-binary\\n\"; close \$ofh; chmod 0755, \$out; }\n";
    close $fh;
    chmod 0755, $pax_path;
    return ( $bin_dir, $pax_path, $log_file );
}

sub source_file_with_content {
    my ($content) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    my $path = File::Spec->catfile( $dir, 'ps1' );
    open my $fh, '>', $path or die $!;
    print {$fh} $content;
    close $fh;
    return $path;
}

# --------------------------------------------------------------------------
# PAX genuinely unavailable: always undef, never touches the cache or
# spawns. Since PAX is now vendored (DD-882) and staged as an internal
# command, this is no longer reachable via a bare PATH clear - the staged
# copy is found regardless of the caller's shell PATH, which is the whole
# point ("no more excuses pax isn't there"). To exercise the still-real
# last-resort degradation contract, force the ONE remaining way _pax_bin()
# can fail both resolution paths: an explicit pax_bin override pointing at
# a path that does not exist, which _pax_bin() returns verbatim (it does
# not itself validate existence, matching resolve()'s own "verify the
# subject actually ran" discipline lower down) - the compile attempt itself
# then fails at exec time, but resolve() must still return undef cleanly.
# --------------------------------------------------------------------------
{
    my $nonexistent_pax = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'nonexistent-pax' );
    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $nonexistent_pax );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 1;\n");
    my $result = $cache->resolve($source);
    is( $result, undef, 'AC-4: a misconfigured/missing pax_bin override -> resolve() returns undef, never dies' );
}

# --------------------------------------------------------------------------
# Cache miss: first resolve() returns undef (run interpreted now) and spawns
# exactly one background compile.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'v1';\n");

    my $result = $cache->resolve($source);
    is( $result, undef, 'AC-1: cache miss returns undef (run interpreted this invocation)' );

    # Give the detached child a moment to actually run and write its log/output.
    my $waited = 0;
    while ( $waited < 50 && !-e $log_file ) {
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    ok( -e $log_file, 'AC-1: a background compile process actually ran' );

    open my $lfh, '<', $log_file or die $!;
    my @log_lines = <$lfh>;
    close $lfh;
    is( scalar(@log_lines), 1, 'AC-1: exactly one compile invocation for a single cache-miss' );
}

# --------------------------------------------------------------------------
# Cache hit: after the background compile finishes, a second resolve() with
# the SAME source content returns the cached binary path.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'v2';\n");

    my $first = $cache->resolve($source);
    is( $first, undef, 'cache-hit test: first call is a miss as expected' );

    # Wait for the background compile (our fake pax is instant) to finish and
    # write both the binary and the cache metadata.
    my $md5 = Digest::MD5->new;
    open my $sfh, '<', $source or die $!;
    $md5->addfile($sfh);
    close $sfh;
    my $expected_md5 = $md5->hexdigest;

    my $waited = 0;
    my $second;
    while ( $waited < 50 ) {
        $second = $cache->resolve($source);
        last if defined $second;
        select( undef, undef, undef, 0.1 );
        $waited++;
    }

    ok( defined $second, 'AC-2: second resolve() eventually returns a cached binary path' );
    ok( -x $second, 'AC-2: the returned cached binary path is executable' ) if defined $second;

    open my $out_fh, '<', $second or die $! if defined $second;
    my $content = defined $second ? do { local $/; <$out_fh> } : '';
    close $out_fh if defined $second;
    like( $content, qr/fake-compiled-binary/, 'AC-2: cached binary is the one the fake pax compiler produced' );
}

# --------------------------------------------------------------------------
# MD5 mismatch: editing the source after a cache entry exists must be
# detected - never silently reuse a stale binary.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'v3';\n");

    $cache->resolve($source);
    my $waited = 0;
    my $hit;
    while ( $waited < 50 ) {
        $hit = $cache->resolve($source);
        last if defined $hit;
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    ok( defined $hit, 'mismatch test: cache became warm before editing the source' );

    # Now edit the source - the cached binary must stop being trusted.
    open my $efh, '>>', $source or die $!;
    print {$efh} "\n# edited\n";
    close $efh;

    my $after_edit = $cache->resolve($source);
    is( $after_edit, undef, 'AC-3: MD5 mismatch after editing the source falls back to interpreted, not the stale binary' );
}

# --------------------------------------------------------------------------
# AC-5 (owner correction, msg #1975): overlapping resolve() calls on the SAME
# stale source while a compile is already in flight must NOT each spawn their
# own compile process - exactly one compile process total.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax( sleep => 2 );
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'v4';\n");

    # Fire 5 overlapping resolve() calls in quick succession, all against the
    # same never-before-cached source, simulating 5 near-simultaneous
    # invocations of `dashboard ps1` before the first compile finishes.
    for ( 1 .. 5 ) {
        my $result = $cache->resolve($source);
        is( $result, undef, "AC-5: overlapping call $_ still returns undef (runs interpreted)" );
    }

    # Give the (slow, 2s) fake compile time to finish and flush its log.
    my $waited = 0;
    while ( $waited < 50 && !-e $log_file ) {
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    select( undef, undef, undef, 2.2 );    # let the slow fake pax actually finish

    open my $lfh, '<', $log_file or die $!;
    my @log_lines = <$lfh>;
    close $lfh;
    is( scalar(@log_lines), 1, 'AC-5: 5 overlapping cache-misses on the same source produced exactly ONE compile process, not 5' );
}

# --------------------------------------------------------------------------
# _run_compile_and_install is only ever reached via the double-forked
# grandchild path in production, which Devel::Cover cannot observe (it
# instruments the process that loaded the module, not a later fork/exec's
# detached descendant). Call it directly - both the success path (pax
# exits 0 and writes the output) and the failure path (pax exits nonzero,
# no output written) - so both branches of its top-level if/else are
# genuinely exercised, not merely annotated.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'direct-success';\n");
    my $work_dir  = tempdir( CLEANUP => 1 );
    my $bin_file  = File::Spec->catfile( $work_dir, 'out.pax' );
    my $md5_file  = File::Spec->catfile( $work_dir, 'out.md5' );
    my $lock_file = File::Spec->catfile( $work_dir, 'out.lock' );
    open my $lfh, '>', $lock_file or die $!;
    close $lfh;

    $cache->_run_compile_and_install(
        source_path => $source,
        pax_bin     => $pax_path,
        md5         => 'deadbeef',
        md5_file    => $md5_file,
        bin_file    => $bin_file,
        lock_file   => $lock_file,
    );

    ok( -x $bin_file, 'direct _run_compile_and_install: success path installs the compiled binary' );
    ok( -f $md5_file, 'direct _run_compile_and_install: success path writes the md5 marker file' );
    ok( !-e $lock_file, 'direct _run_compile_and_install: success path releases the lock file' );
}

{
    my $work_dir     = tempdir( CLEANUP => 1 );
    my $failing_bin  = File::Spec->catfile( $work_dir, 'pax-fail' );
    open my $ffh, '>', $failing_bin or die $!;
    print {$ffh} "#!/usr/bin/env perl\nexit 1;\n";
    close $ffh;
    chmod 0755, $failing_bin;

    my $cache    = Developer::Dashboard::PaxCache->new( paths => $paths );
    my $source   = source_file_with_content("#!/usr/bin/env perl\nprint 'direct-fail';\n");
    my $bin_file  = File::Spec->catfile( $work_dir, 'out2.pax' );
    my $md5_file  = File::Spec->catfile( $work_dir, 'out2.md5' );
    my $lock_file = File::Spec->catfile( $work_dir, 'out2.lock' );
    open my $lfh, '>', $lock_file or die $!;
    close $lfh;

    $cache->_run_compile_and_install(
        source_path => $source,
        pax_bin     => $failing_bin,
        md5         => 'deadbeef',
        md5_file    => $md5_file,
        bin_file    => $bin_file,
        lock_file   => $lock_file,
    );

    ok( !-e $bin_file, 'direct _run_compile_and_install: failing pax never installs a binary' );
    ok( !-e $md5_file, 'direct _run_compile_and_install: failing pax never writes an md5 marker' );
    ok( !-e $lock_file, 'direct _run_compile_and_install: failure path still releases the lock file' );
}

# --------------------------------------------------------------------------
# _spawn_background_compile_windows is the Win32 detach path (no
# fork/setsid available in production Windows Perl builds), entirely
# annotated uncoverable for statement/branch/condition purposes since its
# real target platform cannot run in this Linux gate host - but Devel::
# Cover's SUBROUTINE metric still requires the sub to actually be called at
# least once. Call it directly, matching this project's own documented
# "forced-Windows unit tests on Linux" convention (CLAUDE.md) for
# is_windows()-guarded code: the underlying fork() it uses is real on any
# POSIX host, so calling it here genuinely exercises the sub body.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'winpath';\n");
    my $work_dir  = tempdir( CLEANUP => 1 );
    my $bin_file  = File::Spec->catfile( $work_dir, 'win.pax' );
    my $md5_file  = File::Spec->catfile( $work_dir, 'win.md5' );
    my $lock_file = File::Spec->catfile( $work_dir, 'win.lock' );
    open my $lfh, '>', $lock_file or die $!;
    close $lfh;

    $cache->_spawn_background_compile_windows(
        source_path => $source,
        pax_bin     => $pax_path,
        md5         => 'deadbeef',
        md5_file    => $md5_file,
        bin_file    => $bin_file,
        lock_file   => $lock_file,
    );

    my $waited = 0;
    while ( $waited < 50 && !-e $bin_file ) {
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    ok( -x $bin_file, 'direct _spawn_background_compile_windows: detached fork installs the binary' );
}

# --------------------------------------------------------------------------
# resolve() with an invalid source_path (undef, empty, or a path that does
# not exist) must return undef without ever touching pax or the cache -
# the early-exit branch this project's own coverage rule requires be tested
# rather than merely annotated, since it is genuinely reachable input.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";
    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );

    is( $cache->resolve(undef), undef, 'resolve(undef) returns undef' );
    is( $cache->resolve(''),    undef, 'resolve("") returns undef' );
    is( $cache->resolve('/nonexistent-source-file-for-this-test'), undef, 'resolve() on a missing file returns undef' );
    ok( !-e $log_file, 'invalid source_path never spawns a compile' );
}

# --------------------------------------------------------------------------
# A constructor-supplied pax_bin override takes priority over PATH lookup.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    # A sane PATH (still resolves perl/env for the fake pax script's own
    # shebang) but deliberately excluding $bin_dir, so a bare 'pax' lookup
    # would fail - only the constructor override's absolute path can work.
    local $ENV{PATH} = '/usr/bin:/bin';

    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'override';\n");

    my $result = $cache->resolve($source);
    is( $result, undef, 'resolve() with a pax_bin override still returns undef on first (miss) call' );

    my $waited = 0;
    while ( $waited < 50 && !-e $log_file ) {
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    ok( -e $log_file, 'constructor pax_bin override was actually used to spawn the compile' );
}

# --------------------------------------------------------------------------
# A stale lock (owning PID no longer alive) must be discarded and a fresh
# compile spawned, rather than leaving the source permanently uncompilable.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'stale-lock';\n");

    # Pre-create a lock file naming a PID that is guaranteed to be dead: fork
    # a child, let it exit immediately, and use its now-reaped PID.
    my $dead_pid = fork();
    if ( defined $dead_pid && $dead_pid == 0 ) {
        POSIX::_exit(0);    # uncoverable statement - test-harness fixture, not product code
    }
    waitpid( $dead_pid, 0 ) if defined $dead_pid;

    my $key       = Digest::MD5::md5_hex($source);
    my $cache_dir = File::Spec->catdir( $paths->home_cache_root, 'pax' );
    require File::Path;
    File::Path::make_path($cache_dir);
    my $lock_file = File::Spec->catfile( $cache_dir, "$key.compiling" );
    open my $lfh, '>', $lock_file or die $!;
    print {$lfh} $dead_pid;
    close $lfh;

    my $result = $cache->resolve($source);
    is( $result, undef, 'resolve() with a stale lock still returns undef (spawns a fresh compile)' );

    my $waited = 0;
    while ( $waited < 50 && !-e $log_file ) {
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    ok( -e $log_file, 'a stale lock was discarded and a new compile was spawned' );
}

# --------------------------------------------------------------------------
# A lock file whose content is not a plain PID (malformed) is also treated
# as stale - _lock_is_stale's !$pid =~ /^\d+\z/ branch.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'malformed-lock';\n");

    my $key       = Digest::MD5::md5_hex($source);
    my $cache_dir = File::Spec->catdir( $paths->home_cache_root, 'pax' );
    require File::Path;
    File::Path::make_path($cache_dir);
    my $lock_file = File::Spec->catfile( $cache_dir, "$key.compiling" );
    open my $lfh, '>', $lock_file or die $!;
    print {$lfh} 'not-a-pid';
    close $lfh;

    my $result = $cache->resolve($source);
    is( $result, undef, 'resolve() with a malformed lock still returns undef (spawns a fresh compile)' );

    my $waited = 0;
    while ( $waited < 50 && !-e $log_file ) {
        select( undef, undef, undef, 0.1 );
        $waited++;
    }
    ok( -e $log_file, 'a malformed lock was treated as stale and a new compile was spawned' );
}

# --------------------------------------------------------------------------
# A cache entry whose MD5 matches but whose binary is not executable (e.g.
# an interrupted install) must not be trusted as a hit.
# --------------------------------------------------------------------------
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";    # pax IS available, so the code reaches the cache-hit check

    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'not-executable';\n");

    my $md5 = Digest::MD5->new;
    open my $sfh, '<', $source or die $!;
    $md5->addfile($sfh);
    close $sfh;
    my $expected_md5 = $md5->hexdigest;

    my $key       = Digest::MD5::md5_hex($source);
    my $cache_dir = File::Spec->catdir( $paths->home_cache_root, 'pax' );
    require File::Path;
    File::Path::make_path($cache_dir);
    my $md5_file = File::Spec->catfile( $cache_dir, "$key.md5" );
    my $bin_file = File::Spec->catfile( $cache_dir, "$key.pax" );
    open my $mfh, '>', $md5_file or die $!;
    print {$mfh} $expected_md5;
    close $mfh;
    open my $bfh, '>', $bin_file or die $!;
    print {$bfh} 'not-executable-content';
    close $bfh;
    chmod 0644, $bin_file;    # deliberately NOT executable

    my $result = $cache->resolve($source);
    is( $result, undef, 'an MD5-matched but non-executable cached binary is not trusted as a hit' );
}

# --------------------------------------------------------------------------
# _run_compile_and_install: pax can exit 0 (success) without actually
# writing the expected -o output file (e.g. a pax bug, or an unexpected
# argument-parsing mismatch) - that combination must still be treated as a
# failed compile, not installed.
# --------------------------------------------------------------------------
{
    my $work_dir      = tempdir( CLEANUP => 1 );
    my $silent_ok_bin = File::Spec->catfile( $work_dir, 'pax-silent-ok' );
    open my $sfh, '>', $silent_ok_bin or die $!;
    print {$sfh} "#!/usr/bin/env perl\nexit 0;\n";    # exits clean, writes nothing
    close $sfh;
    chmod 0755, $silent_ok_bin;

    my $cache    = Developer::Dashboard::PaxCache->new( paths => $paths );
    my $source   = source_file_with_content("#!/usr/bin/env perl\nprint 'silent-ok';\n");
    my $bin_file  = File::Spec->catfile( $work_dir, 'out3.pax' );
    my $md5_file  = File::Spec->catfile( $work_dir, 'out3.md5' );
    my $lock_file = File::Spec->catfile( $work_dir, 'out3.lock' );
    open my $lfh, '>', $lock_file or die $!;
    close $lfh;

    $cache->_run_compile_and_install(
        source_path => $source,
        pax_bin     => $silent_ok_bin,
        md5         => 'deadbeef',
        md5_file    => $md5_file,
        bin_file    => $bin_file,
        lock_file   => $lock_file,
    );

    ok( !-e $bin_file, 'direct _run_compile_and_install: exit-0-but-no-output is not installed' );
    ok( !-e $md5_file, 'direct _run_compile_and_install: exit-0-but-no-output writes no md5 marker' );
    ok( !-e $lock_file, 'direct _run_compile_and_install: exit-0-but-no-output still releases the lock file' );
}

# --------------------------------------------------------------------------
# _pax_bin() full degradation chain: when the staged internal helper cannot
# be resolved (InternalCLI's staging throws) AND no `pax` is found on PATH,
# _pax_bin() returns undef, and resolve() must then also return undef via
# its own separate "pax entirely unavailable" branch (resolve()'s line 43,
# `!defined $pax_bin`) - every other block in this file bypasses that branch
# by supplying an explicit pax_bin constructor override.
# --------------------------------------------------------------------------
{
    local $ENV{PATH} = '/nonexistent-empty-path-dir-for-this-test';
    local *Developer::Dashboard::InternalCLI::ensure_helper =
      sub { die "staging deliberately fails for this test\n" };
    local *Developer::Dashboard::InternalCLI::helper_path =
      sub { die "staging deliberately fails for this test\n" };

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths );
    is( $cache->_pax_bin, undef, '_pax_bin: staging failure + no PATH pax -> undef' );

    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'no-pax-anywhere';\n");
    is( $cache->resolve($source), undef, 'resolve(): pax entirely unavailable -> undef, never dies' );
}

# --------------------------------------------------------------------------
# _pax_bin()'s "staged path resolves but the file does not exist" sub-case:
# InternalCLI's staging succeeds (no die) and returns a path, but nothing
# actually lives there - `defined $staged` is true while `-f $staged` is
# false, which must still fall through to the PATH lookup rather than
# returning a dangling path. Covers the remaining condition sub-case of
# `defined $staged && -f $staged` that the block above does not reach.
# --------------------------------------------------------------------------
{
    local $ENV{PATH} = '/nonexistent-empty-path-dir-for-this-test';
    local *Developer::Dashboard::InternalCLI::ensure_helper = sub { return 1 };
    local *Developer::Dashboard::InternalCLI::helper_path =
      sub { return '/nonexistent/staged/pax/path/for/this/test' };

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths );
    is( $cache->_pax_bin, undef,
        '_pax_bin: staged path resolves but file does not exist -> falls through to PATH, finds nothing -> undef' );
}

# --------------------------------------------------------------------------
# _pax_bin()'s genuine success path: no constructor override, InternalCLI's
# REAL (unmocked) staging runs and actually writes the helper file, so
# `defined $staged && -f $staged` is true on both sides and _pax_bin returns
# the staged path directly, never reaching the PATH-lookup fallback. Every
# other no-override block in this file happens to call _run_compile_and_install
# directly rather than going through resolve()/_pax_bin, so this is the one
# place the real staging success itself is exercised.
# --------------------------------------------------------------------------
{
    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths );
    my $staged = $cache->_pax_bin;
    ok( defined $staged, '_pax_bin: real (unmocked) staging resolves a defined path' );
    ok( defined $staged && -f $staged, '_pax_bin: the resolved staged path genuinely exists on disk' ) if defined $staged;
}

# --------------------------------------------------------------------------
# DD-936: DD_PAX opt-in gate, scoped to ONLY the spawn-a-new-compile path
# (Q-167: option A, owner-answered 2026-09-17, after option B as originally
# implemented was found to break bin/d2's own self-exec feature in
# t/184-d2-self-compile.t - a pre-existing valid cache hit must NOT require
# DD_PAX). Default (unset) disables spawning a NEW background compile on a
# cache MISS; it does not affect reporting an already-existing, valid cache
# HIT. Every other block in this file locally sets DD_PAX=on at file scope
# (see top of file) specifically so it can keep exercising resolve()'s
# pre-existing mechanics unaffected by this gate - these blocks are what
# actually prove the gate, so they override that file-scope value back off.
# --------------------------------------------------------------------------
{
    local $ENV{DD_PAX} = undef;
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'dd936-unset';\n");

    my $result = $cache->resolve($source);
    is( $result, undef, 'DD-936 AC-1: DD_PAX unset, cache MISS -> resolve() returns undef' );

    # Give a wrongly-spawned background compile a moment to have started and
    # written its call-log entry, then assert it never did.
    select( undef, undef, undef, 0.3 );
    ok( !-e $log_file, 'DD-936 AC-1: DD_PAX unset, cache MISS -> the fake pax binary was never invoked at all' );
}

# --------------------------------------------------------------------------
# Q-167 option A's own contract: an ALREADY-EXISTING, valid cache HIT is
# reported regardless of DD_PAX - this is the exact scenario t/184's own
# seed_cache_for_d2 depends on (seed a real cache entry directly, no compile
# involved, expect it reported/used). No fake pax binary needed here at all;
# a cache hit never invokes pax_bin.
# --------------------------------------------------------------------------
{
    local $ENV{DD_PAX} = undef;
    my $cache  = Developer::Dashboard::PaxCache->new( paths => $paths );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'dd936-hit';\n");

    # Seed a valid cache entry directly, exactly as resolve()'s own
    # cache-hit check reads it: matching MD5 + an executable binary file.
    my $md5 = do {
        open my $fh, '<:raw', $source or die $!;
        Digest::MD5->new->addfile($fh)->hexdigest;
    };
    my $key       = Digest::MD5::md5_hex($source);
    my $cache_dir = File::Spec->catdir( $paths->home_cache_root, 'pax' );
    make_path($cache_dir);
    my $md5_file = File::Spec->catfile( $cache_dir, "$key.md5" );
    my $bin_file = File::Spec->catfile( $cache_dir, "$key.pax" );
    open my $mfh, '>', $md5_file or die $!;
    print {$mfh} $md5;
    close $mfh;
    open my $bfh, '>', $bin_file or die $!;
    print {$bfh} "fake-compiled-binary\n";
    close $bfh;
    chmod 0755, $bin_file;

    is(
        $cache->resolve($source),
        $bin_file,
        'DD-936 AC-1b (Q-167 option A): DD_PAX unset, a pre-existing valid cache HIT is still reported normally - only new spawns are gated'
    );
}

{
    local $ENV{DD_PAX} = 'off';
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'dd936-off';\n");

    my $result = $cache->resolve($source);
    is( $result, undef, 'DD-936: DD_PAX=off (anything other than "on") -> resolve() returns undef' );
    select( undef, undef, undef, 0.3 );
    ok( !-e $log_file, 'DD-936: DD_PAX=off -> the fake pax binary was never invoked' );
}

{
    local $ENV{DD_PAX} = 'on';
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax();
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'dd936-on';\n");

    my $result = $cache->resolve($source);
    is( $result, undef, 'DD-936 AC-2: DD_PAX=on -> resolve() still returns undef on a genuine cache miss (unchanged behavior)' );

    for ( 1 .. 50 ) {
        last if -e $log_file;
        select( undef, undef, undef, 0.1 );
    }
    ok( -e $log_file, 'DD-936 AC-2: DD_PAX=on -> the background compile WAS spawned, exactly as before this change' );
}

done_testing();

__END__

=head1 NAME

t/181-paxcache-coverage.t - coverage tests for Developer::Dashboard::PaxCache

=head1 PURPOSE

Exercises Developer::Dashboard::PaxCache's cache-hit/miss/mismatch decision
logic, its graceful degradation when PAX is not installed, and its
concurrency guard against overlapping invocations each spawning their own
redundant background compile.

=head1 WHY IT EXISTS

DD-877 introduces PaxCache as the first real implementation ticket under the
PAX-compiled-d2/dashboard SOW (DDS-001). A stale or duplicated compile is a
worse outcome than never compiling at all - a race that spawns N compile
processes for one source file would waste CPU/IO proportional to concurrent
invocation count, which the owner explicitly flagged (Telegram msg #1975,
2026-09-15) as a "disaster" to guard against - hence this file's AC-5 block.

=head1 WHEN TO USE

Run this file whenever PaxCache.pm or its concurrency-lock/cache-file
mechanics change, to confirm the four cache-decision states (miss / hit /
stale-MD5 / no-pax-installed) and the overlapping-invocation guard still
hold.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/181-paxcache-coverage.t

=head1 WHAT USES IT

Confirms the contract that C<bin/dashboard>'s C<_exec_switchboard_command>
hook (for the C<ps1> command) depends on: C<resolve()> never blocks, never
reuses a stale binary, and never lets overlapping invocations pile up
redundant compiles.

=head1 EXAMPLES

A cache-miss decision, using a fake C<pax> binary on PATH so the test suite
never has to wait for a real, multi-minute PAX compile:

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths );
    my $result = $cache->resolve('/path/to/ps1');   # undef on first call

=cut
