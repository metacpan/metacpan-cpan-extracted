#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);
use File::Basename qw(dirname);
use File::Spec;
use Cwd qw(getcwd realpath);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform ();
use Developer::Dashboard::SkillManager;

# ---------------------------------------------------------------------------
# Hermetic runtime rooted in an isolated HOME. Config resolution keys off the
# deepest .developer-dashboard layer discovered from the cwd, so we must chdir
# into the temp HOME before constructing the manager.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# A stub PATH so external dependency commands never touch the real system.
my $fake_bin = tempdir( CLEANUP => 1 );
_stub( 'cpanm',      "#!/bin/sh\nexit 0\n" );
_stub( 'apt-get',    "#!/bin/sh\nexit 0\n" );
_stub( 'apk',        "#!/bin/sh\nif [ \"\$1\" = info ]; then exit 1; fi\nexit 0\n" );
_stub( 'dnf',        "#!/bin/sh\nexit 0\n" );
_stub( 'brew',       "#!/bin/sh\nexit 0\n" );
_stub( 'winget',     "#!/bin/sh\nexit 0\n" );
_stub( 'dpkg-query', "#!/bin/sh\nexit 1\n" );
_stub( 'rpm',        "#!/bin/sh\nexit 1\n" );
_stub( 'sudo',       "#!/bin/sh\nexec \"\$@\"\n" );
_stub( 'dashboard',  "#!/bin/sh\nexit 0\n" );
_stub( 'make',       "#!/bin/sh\nexit 0\n" );
_stub( 'docker',     "#!/bin/sh\nexit 0\n" );
_stub( 'rsync',      "#!/bin/sh\nexit 0\n" );
_stub(
    'npx',
    <<'SH',
#!/bin/sh
shift; shift; shift
for spec in "$@"; do
  name=${spec%%@*}
  mkdir -p "$PWD/node_modules/$name"
done
exit 0
SH
);
_stub( 'python',  "#!/bin/sh\nexit 0\n" );
_stub( 'python3', "#!/bin/sh\nexit 0\n" );
local $ENV{PATH} = "$fake_bin:" . ( $ENV{PATH} || '' );

my $paths   = Developer::Dashboard::PathRegistry->new( home => $home );
my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );

# ===========================================================================
# new(): the paths-fallback branch and the HOME-resolution chain.
# ===========================================================================
{
    my $default = Developer::Dashboard::SkillManager->new();
    isa_ok( $default, 'Developer::Dashboard::SkillManager', 'new() builds its own PathRegistry when none is supplied' );

    my $skip_default = Developer::Dashboard::SkillManager->new( skip_tests => 1 );
    is( $skip_default->{skip_tests}, 1, 'new() records the skip_tests flag' );

    # HOME unset with USERPROFILE set is the Windows shape: the profile
    # directory has to win before the passwd lookup is attempted at all.
    {
        local %ENV = %ENV;
        delete $ENV{HOME};
        my $profile_home = tempdir( CLEANUP => 1 );
        $ENV{USERPROFILE} = $profile_home;
        my $profile_manager = Developer::Dashboard::SkillManager->new();
        is( $profile_manager->{paths}->home, $profile_home,
            'new() resolves USERPROFILE as home when HOME is unset' );
    }

    # Neither home variable set: the passwd database answers on a runtime that
    # has one.
    {
        local %ENV = %ENV;
        delete $ENV{HOME};
        delete $ENV{USERPROFILE};
        my $no_home = Developer::Dashboard::SkillManager->new();
        isa_ok( $no_home, 'Developer::Dashboard::SkillManager', 'new() resolves HOME from the password database when no home variable is set' );
        is( $no_home->{paths}->home, ( getpwuid($>) )[7],
            'new() uses the passwd home directory when no home variable is set' );
    }

    # Nothing can name a home, which is the non-interactive Windows case, so the
    # constructor reports the explicit error instead of dying inside the passwd
    # lookup.
    {
        local %ENV = %ENV;
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        delete $ENV{HOME};
        delete $ENV{USERPROFILE};
        my $unresolved = eval { Developer::Dashboard::SkillManager->new() };
        is( $unresolved, undef, 'new() fails when no home directory is resolvable' );
        like( $@, qr/Missing home directory/, 'new() names the missing home directory' );
    }
}

# ===========================================================================
# Progress task helpers.
# ===========================================================================
{
    my $tasks = Developer::Dashboard::SkillManager->install_progress_tasks;
    is( ref($tasks), 'ARRAY', 'install_progress_tasks returns an array reference' );

    # install_progress_tasks_for_sources: skip undef/empty, keep real sources.
    my $src_tasks = Developer::Dashboard::SkillManager->install_progress_tasks_for_sources( undef, '', 'alpha', 'beta' );
    is( scalar(@$src_tasks), 2, 'install_progress_tasks_for_sources drops undef and empty sources' );

    my $none = Developer::Dashboard::SkillManager->install_progress_tasks_for_sources();
    is_deeply( $none, [], 'install_progress_tasks_for_sources returns an empty list for no sources' );
}

# ===========================================================================
# Direct unit coverage of the small pure helpers and their guard branches.
# ===========================================================================
{
    # _normalize_install_source
    is( $manager->_normalize_install_source(undef), undef, 'normalize passes undef straight through' );
    is( $manager->_normalize_install_source(''), '', 'normalize passes an empty string straight through' );
    is( $manager->_normalize_install_source($home), $home, 'normalize passes an existing directory straight through' );
    is( $manager->_normalize_install_source('https://example.com/x.git'), 'https://example.com/x.git', 'normalize keeps explicit URLs' );
    is( $manager->_normalize_install_source('git@github.com:u/r.git'), 'git@github.com:u/r.git', 'normalize keeps scp-style git URLs' );
    is( $manager->_normalize_install_source('owner/repo'), 'https://github.com/owner/repo', 'normalize expands owner/repo shorthand' );
    is( $manager->_normalize_install_source('bareskill'), 'https://github.com/manif3station/bareskill', 'normalize expands bare skill names' );
    is( $manager->_normalize_install_source('weird name with spaces'), 'weird name with spaces', 'normalize leaves unrecognized sources unchanged' );

    # _ddfile_source_matches_repo_name guards.
    is( $manager->_ddfile_source_matches_repo_name( undef, 'repo' ), 0, 'ddfile match rejects an undef source' );
    is( $manager->_ddfile_source_matches_repo_name( 'src', undef ), 0, 'ddfile match rejects an undef repo name' );
    is( $manager->_ddfile_source_matches_repo_name( '', 'repo' ), 0, 'ddfile match rejects an empty source' );
    is( $manager->_ddfile_source_matches_repo_name( '# comment', 'repo' ), 0, 'ddfile match rejects a comment source' );
    is( $manager->_ddfile_source_matches_repo_name( 'zzznodir', 'repo' ), 0, 'ddfile match rejects a source that resolves to no repo name' );
    is( $manager->_ddfile_source_matches_repo_name( 'https://github.com/u/repo.git', 'repo' ), 1, 'ddfile match resolves a URL to its repo name' );
    is( $manager->_ddfile_source_matches_repo_name( 'https://github.com/u/other.git', 'repo' ), 0, 'ddfile match returns false for a different repo name' );

    # _progress_error_text guards.
    is( $manager->_progress_error_text(undef), 'unknown failure', 'progress error text handles undef' );
    is( $manager->_progress_error_text(''), 'unknown failure', 'progress error text handles empty string' );
    is( $manager->_progress_error_text("  a  \n  b  "), 'a b', 'progress error text collapses whitespace' );

    # _install_version_status full matrix.
    is( $manager->_install_version_status( undef, '1', 0 ), 'installed', 'version status: fresh install when before is undef' );
    is( $manager->_install_version_status( '1', '1', 0 ), 'installed', 'version status: install when nothing existed before' );
    is( $manager->_install_version_status( '1', '2', 1 ), 'updated', 'version status: updated when versions differ' );
    is( $manager->_install_version_status( '1', '1', 1 ), 'no update', 'version status: no update when versions match' );
    is( $manager->_install_version_status( '1', undef, 1 ), 'unknown', 'version status: unknown when after is undef' );
    is( $manager->_install_version_status( undef, undef, 1 ), 'unknown', 'version status: unknown when both are undef' );

    # _remove_tree_error_text formatting.
    is( $manager->_remove_tree_error_text('notarray'), 'unknown remove_tree failure', 'remove_tree error text handles a non-array argument' );
    is( $manager->_remove_tree_error_text( [] ), 'unknown remove_tree failure', 'remove_tree error text handles an empty array' );
    is(
        $manager->_remove_tree_error_text( [ { '/a' => 'boom' }, { '/b' => '' }, 'plain' ] ),
        '/a: boom, /b: unknown error, plain',
        'remove_tree error text formats hash and scalar entries',
    );

    # _install_result_progress_label with a non-hash result and a full result.
    like( $manager->_install_result_progress_label( 'src', undef ), qr/^src done \(- -> -\)$/, 'progress label falls back for a non-hash result' );
    like(
        $manager->_install_result_progress_label( 'src', { repo_name => 'r', status => 'updated', version_before => '1', version_after => '2' } ),
        qr/^r updated \(1 -> 2\)$/,
        'progress label renders a full install result',
    );

    # _skill_install_root strips the trailing separator.
    is( $manager->_skill_install_root( File::Spec->catdir( $home, 'skills', 'x' ) ), File::Spec->catdir( $home, 'skills' ), 'skill install root drops the repo component' );
}

# ===========================================================================
# _dependency_file_lines / _skill_apt_packages / _packages_missing.
# ===========================================================================
{
    my $dir = tempdir( CLEANUP => 1 );

    is_deeply( [ $manager->_dependency_file_lines(undef) ], [], 'dependency file lines returns empty for undef' );
    is_deeply( [ $manager->_dependency_file_lines( File::Spec->catfile( $dir, 'absent' ) ) ], [], 'dependency file lines returns empty for a missing file' );

    my $manifest = File::Spec->catfile( $dir, 'manifest' );
    _spew( $manifest, "  alpha  \n\n# comment\nbeta\n" );
    is_deeply( [ $manager->_dependency_file_lines($manifest) ], [ 'alpha', 'beta' ], 'dependency file lines trims blanks and comments' );

    my $aptfile = File::Spec->catfile( $dir, 'aptfile' );
    is_deeply( [ $manager->_skill_apt_packages($dir) ], [], 'apt packages returns empty when no aptfile exists' );
    _spew( $aptfile, "  git  \n\n# note\ncurl\n" );
    is_deeply( [ $manager->_skill_apt_packages($dir) ], [ 'git', 'curl' ], 'apt packages trims blanks and comments' );

    my %installed = ( git => 1 );
    is_deeply(
        [ $manager->_packages_missing( sub { $installed{ $_[0] } }, 'git', 'curl' ) ],
        ['curl'],
        'packages missing filters out already-installed packages',
    );

    # open failure on a present-but-unreadable file (non-root only).
  SKIP: {
        skip 'cannot deny read to root', 2 if $> == 0;
        chmod 0000, $manifest;
        eval { $manager->_dependency_file_lines($manifest); 1 };
        like( $@, qr/Unable to read/, 'dependency file lines dies when the file cannot be opened' );
        chmod 0000, $aptfile;
        eval { $manager->_skill_apt_packages($dir); 1 };
        like( $@, qr/Unable to read/, 'apt packages dies when the aptfile cannot be opened' );
        chmod 0644, $manifest;
        chmod 0644, $aptfile;
    }
}

# ===========================================================================
# _makefile_targets and _package_json_dependency_specs.
# ===========================================================================
{
    my $dir = tempdir( CLEANUP => 1 );
    is_deeply( [ $manager->_makefile_targets(undef) ], [], 'makefile targets returns empty for undef' );
    is_deeply( [ $manager->_makefile_targets( File::Spec->catfile( $dir, 'absent' ) ) ], [], 'makefile targets returns empty for a missing makefile' );

    my $makefile = File::Spec->catfile( $dir, 'Makefile' );
    _spew(
        $makefile,
        "# leading comment\n"
          . ".PHONY: install\n"
          . "install test:\n\t\@:\n"
          . "\tindented not a target\n"
          . "VAR = value\n"
          . "install:\n\t\@:\n"
          . "clean:\n\t\@:\n",
    );
    is_deeply( [ $manager->_makefile_targets($makefile) ], [ 'install', 'test', 'clean' ], 'makefile targets parses deduplicated top-level targets' );

    is_deeply( [ $manager->_package_json_dependency_specs(undef) ], [], 'package.json specs returns empty for undef' );
    my $pj = File::Spec->catfile( $dir, 'package.json' );
    _spew( $pj, '{"dependencies":{"b":"^1.0.0","a":""},"devDependencies":{"c":"2.0.0"},"scripts":"ignored"}' );
    is_deeply(
        [ $manager->_package_json_dependency_specs($pj) ],
        [ 'a', 'b@^1.0.0', 'c@2.0.0' ],
        'package.json specs sorts names and joins versions, tolerating blank versions',
    );

    my $bad = File::Spec->catfile( $dir, 'bad.json' );
    _spew( $bad, 'null' );
    eval { $manager->_package_json_dependency_specs($bad); 1 };
    like( $@, qr/Unable to parse/, 'package.json specs dies when JSON decodes to a false value' );
}

# ===========================================================================
# _copy_tree / _copy_tree_contents / _sync_local_skill_source.
# ===========================================================================
{
    my $src = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $src, 'sub' ) );
    _spew( File::Spec->catfile( $src, 'file.txt' ), "hello\n" );
    _spew( File::Spec->catfile( $src, 'sub', 'nested.txt' ), "nested\n" );
    chmod 0755, File::Spec->catfile( $src, 'file.txt' );

    my $dst = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'target' );
    my $copied = $manager->_copy_tree( $src, $dst );
    ok( $copied->{success}, '_copy_tree copies a directory tree' );
    ok( -f File::Spec->catfile( $dst, 'file.txt' ), '_copy_tree copies plain files' );
    ok( -f File::Spec->catfile( $dst, 'sub', 'nested.txt' ), '_copy_tree copies nested files' );

    # _copy_tree_contents guard branches.
    eval { $manager->_copy_tree_contents( undef, $dst ); 1 };
    like( $@, qr/Missing source tree/, '_copy_tree_contents rejects a missing source' );
    eval { $manager->_copy_tree_contents( $src, undef ); 1 };
    like( $@, qr/Missing target tree/, '_copy_tree_contents rejects a missing target' );
    eval { $manager->_copy_tree_contents( File::Spec->catdir( $src, 'nope' ), $dst ); 1 };
    like( $@, qr/does not exist/, '_copy_tree_contents rejects a non-existent source' );

    my $dst2 = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'contents' );
    ok( $manager->_copy_tree_contents( $src, $dst2 ), '_copy_tree_contents copies contents into a fresh target' );
    ok( -f File::Spec->catfile( $dst2, 'sub', 'nested.txt' ), '_copy_tree_contents copies nested files into a fresh target' );

    # _sync_local_skill_source guard branches and both sync engines.
    is( $manager->_sync_local_skill_source( '', $dst )->{error}, 'Missing local skill source path', 'sync rejects a missing source path' );
    is( $manager->_sync_local_skill_source( $src, '' )->{error}, 'Missing local skill target path', 'sync rejects a missing target path' );

    my $sync_dst = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'sync' );
    ok( $manager->_sync_local_skill_source( $src, $sync_dst )->{success}, 'sync succeeds through rsync when rsync is available' );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_rsync_available = sub { 0 };
        my $copy_dst = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'copysync' );
        ok( $manager->_sync_local_skill_source( $src, $copy_dst )->{success}, 'sync falls back to a Perl copy when rsync is unavailable' );
        ok( -f File::Spec->catfile( $copy_dst, 'file.txt' ), 'sync copy fallback reproduces the source tree' );
    }

    {
        # rsync failure path.
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_rsync_available = sub { 1 };
        my $bin2 = tempdir( CLEANUP => 1 );
        _spew( File::Spec->catfile( $bin2, 'rsync' ), "#!/bin/sh\nexit 3\n" );
        chmod 0755, File::Spec->catfile( $bin2, 'rsync' );
        local $ENV{PATH} = "$bin2:$ENV{PATH}";
        my $failed = $manager->_sync_local_skill_source( $src, File::Spec->catdir( tempdir( CLEANUP => 1 ), 'rf' ) );
        like( $failed->{error}, qr/Failed to sync local skill source/, 'sync reports rsync failures' );
    }

    # _copy_tree failure surfaces through its eval wrapper (unreadable source).
  SKIP: {
        skip 'cannot deny read to root', 1 if $> == 0;
        my $locked = tempdir( CLEANUP => 1 );
        _spew( File::Spec->catfile( $locked, 'secret' ), "x\n" );
        chmod 0000, File::Spec->catfile( $locked, 'secret' );
        my $res = $manager->_copy_tree( $locked, File::Spec->catdir( tempdir( CLEANUP => 1 ), 'x' ) );
        like( $res->{error}, qr/Failed to sync local skill source .* without rsync/, '_copy_tree reports copy failures through its error wrapper' );
        chmod 0644, File::Spec->catfile( $locked, 'secret' );
    }
}

# ===========================================================================
# _clone_skill_source guards and failure text.
# ===========================================================================
{
    is( $manager->_clone_skill_source( '', 'x' )->{error}, 'Missing remote skill source', 'clone rejects a missing source' );
    is( $manager->_clone_skill_source( 'src', '' )->{error}, 'Missing remote skill target path', 'clone rejects a missing target' );

    # Silent-failing git stub so both stderr and stdout are empty.
    my $bin2 = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin2, 'git' ), "#!/bin/sh\nexit 1\n" );
    chmod 0755, File::Spec->catfile( $bin2, 'git' );
    local $ENV{PATH} = "$bin2:$ENV{PATH}";
    my $failed = $manager->_clone_skill_source( 'file:///nope', File::Spec->catdir( tempdir( CLEANUP => 1 ), 'c' ) );
    like( $failed->{error}, qr/git clone failed without output/, 'clone reports a fallback message when git is silent' );
}

# ===========================================================================
# _run_streaming_command: guards, cwd handling, env, banner, and streaming.
# ===========================================================================
{
    eval { $manager->_run_streaming_command(); 1 };
    like( $@, qr/Missing command/, 'streaming command requires a command' );
    eval { $manager->_run_streaming_command( command => 'notarray' ); 1 };
    like( $@, qr/must be an array reference/, 'streaming command rejects a non-array command' );
    eval { $manager->_run_streaming_command( command => [] ); 1 };
    like( $@, qr/must be an array reference/, 'streaming command rejects an empty command' );
    eval { $manager->_run_streaming_command( command => ['true'], env => 'notahash' ); 1 };
    like( $@, qr/env must be a hash reference/, 'streaming command rejects a non-hash env' );

    # No cwd, no banner, real output on both handles.
    my $run = $manager->_run_streaming_command( command => [ 'sh', '-c', 'printf out; printf err 1>&2' ] );
    is( $run->{exit}, 0, 'streaming command runs without a cwd' );
    is( $run->{stdout}, 'out', 'streaming command captures stdout' );
    is( $run->{stderr}, 'err', 'streaming command captures stderr' );

    # Empty cwd string takes the no-chdir path; empty banner is skipped.
    my $empty_cwd = $manager->_run_streaming_command( command => ['true'], cwd => '', banner => '' );
    is( $empty_cwd->{exit}, 0, 'streaming command treats an empty cwd as no cwd' );

    # Real cwd plus a banner, streamed through an active progress task.
    my @events;
    my $progress_manager = Developer::Dashboard::SkillManager->new(
        paths    => $paths,
        progress => sub { push @events, $_[0] },
    );
    local $progress_manager->{_active_dependency_task_id} = 'install_cpanfile';
    my $work = tempdir( CLEANUP => 1 );
    my $banner_run = $progress_manager->_run_streaming_command(
        command => [ 'sh', '-c', 'printf "line-one\nline-two\n"' ],
        cwd     => $work,
        banner  => 'starting',
        env     => { DD_STREAM_ENV => 'yes' },
    );
    is( $banner_run->{exit}, 0, 'streaming command runs inside a cwd with an env and banner' );
    ok( ( grep { ( $_->{detail_line} || '' ) eq 'starting' } @events ), 'streaming command emits the banner as a detail line' );

    # chdir failure into a non-existent cwd.
    eval { $manager->_run_streaming_command( command => ['true'], cwd => File::Spec->catdir( $home, 'no-such-cwd' ) ); 1 };
    like( $@, qr/Unable to chdir to/, 'streaming command dies when the cwd cannot be entered' );

    # launcher failure (exec of a missing binary) is rethrown after chdir back.
    my $before_cwd = getcwd();
    eval { $manager->_run_streaming_command( command => ['/nonexistent-binary-xyz'], cwd => $work ); 1 };
    ok( $@, 'streaming command rethrows a launcher failure' );
    is( getcwd(), $before_cwd, 'streaming command restores the original cwd after a launcher failure' );
}

# ===========================================================================
# _progress_emit / _progress_detail_line.
# ===========================================================================
{
    ok( $manager->_progress_emit( { task_id => 'x' } ), 'progress emit is a no-op without a callback' );
    my $bad = Developer::Dashboard::SkillManager->new( paths => $paths, progress => 'notcode' );
    ok( $bad->_progress_emit( {} ), 'progress emit ignores a non-code progress handler' );

    my @lines;
    my $pm = Developer::Dashboard::SkillManager->new( paths => $paths, progress => sub { push @lines, $_[0] } );
    ok( $pm->_progress_detail_line( 'hi', task_id => 't' ), 'detail line emits with an explicit task id' );
    ok( $pm->_progress_detail_line('no-active-task'), 'detail line is a no-op without an active task id' );
    ok( $pm->_progress_detail_line( undef, task_id => 't' ), 'detail line ignores an undef line' );
    ok( $pm->_progress_detail_line( "   \r\n", task_id => 't' ), 'detail line ignores a blank line' );
    is_deeply( [ map { $_->{detail_line} } @lines ], ['hi'], 'detail line only forwards real content' );
}

# ===========================================================================
# _host_progress_system_task_ids across simulated hosts, and
# _current_os / _is_debian_like / _is_alpine / _is_fedora / _is_windows.
# ===========================================================================
{
    my %os = (
        MSWin32 => 'install_wingetfile',
        darwin  => 'install_brewfile',
    );
    for my $os ( sort keys %os ) {
        local $ENV{DD_TEST_OS} = $os;
        is_deeply( [ $manager->_host_progress_system_task_ids ], [ $os{$os} ], "host progress task ids on $os" );
    }
    {
        local $ENV{DD_TEST_OS}     = 'linux';
        local $ENV{DD_TEST_ALPINE} = 1;
        is_deeply( [ $manager->_host_progress_system_task_ids ], ['install_apkfile'], 'host progress task ids on Alpine' );
    }
    {
        local $ENV{DD_TEST_OS}     = 'linux';
        local $ENV{DD_TEST_FEDORA} = 1;
        is_deeply( [ $manager->_host_progress_system_task_ids ], ['install_dnfile'], 'host progress task ids on Fedora' );
    }
    {
        local $ENV{DD_TEST_OS}          = 'linux';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        is_deeply( [ $manager->_host_progress_system_task_ids ], ['install_aptfile'], 'host progress task ids on Debian-like hosts' );
    }
    {
        # A non-linux, non-mac, non-windows host yields no system tasks.
        local $ENV{DD_TEST_OS} = 'solaris';
        delete local $ENV{DD_TEST_DEBIAN_LIKE};
        delete local $ENV{DD_TEST_ALPINE};
        delete local $ENV{DD_TEST_FEDORA};
        is_deeply( [ $manager->_host_progress_system_task_ids ], [], 'host progress task ids empty on an unsupported host' );
    }

    # The OS predicate helpers on a forced non-linux OS.
    {
        local $ENV{DD_TEST_OS} = 'solaris';
        delete local $ENV{DD_TEST_DEBIAN_LIKE};
        delete local $ENV{DD_TEST_ALPINE};
        delete local $ENV{DD_TEST_FEDORA};
        is( $manager->_is_debian_like, 0, 'debian detection is false on a non-linux OS' );
        is( $manager->_is_alpine,      0, 'alpine detection is false on a non-linux OS' );
        is( $manager->_is_fedora,      0, 'fedora detection is false on a non-linux OS' );
        is( $manager->_is_windows,     0, 'windows detection is false on a non-windows OS' );
    }
    {
        local $ENV{DD_TEST_OS} = 'MSWin32';
        is( $manager->_is_windows, 1, 'windows detection is true on MSWin32' );
    }
    {
        # With no DD_TEST_OS override, _current_os falls through to $^O.
        delete local $ENV{DD_TEST_OS};
        is( $manager->_current_os, $^O, 'current OS falls back to the real OS when unset' );
        is( $manager->_is_windows, 0, 'windows detection falls back to the real OS when unset' );
    }
    {
        # Linux host, env overrides off: exercises the -f probes on the real host.
        local $ENV{DD_TEST_OS} = 'linux';
        delete local $ENV{DD_TEST_DEBIAN_LIKE};
        delete local $ENV{DD_TEST_ALPINE};
        delete local $ENV{DD_TEST_FEDORA};
        ok( defined $manager->_is_debian_like, 'debian detection probes the filesystem on linux' );
        ok( defined $manager->_is_alpine,      'alpine detection probes the filesystem on linux' );
        ok( defined $manager->_is_fedora,      'fedora detection probes the filesystem on linux' );
    }
}

# ===========================================================================
# _dependency_progress_label and dependency_progress_tasks_for_skill_path.
# ===========================================================================
{
    my $skill = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $skill, 'ddfile' ), "dep\n" );

    is( $manager->_dependency_progress_label( 'install_ddfile', $skill ), "Install ddfile dependencies from " . File::Spec->catfile( $skill, 'ddfile' ), 'label reports the manifest path when present' );
    is( $manager->_dependency_progress_label( 'unknown_task', $skill ), 'unknown_task', 'label falls back to the task id for tasks without a file' );

    my $absent = tempdir( CLEANUP => 1 );
    is( $manager->_dependency_progress_label( 'install_ddfile', $absent ), 'Install ddfile dependencies', 'label without a present manifest omits the path' );

    is(
        $manager->_dependency_progress_label( 'install_ddfile', $skill, result => { skipped => 1, skip_reason => 'nothing to do' } ),
        'Install ddfile dependencies (skipped: nothing to do)',
        'label reports an explicit skip reason',
    );
    is(
        $manager->_dependency_progress_label( 'install_ddfile', $skill, result => { skipped => 1 } ),
        "Install ddfile dependencies (skipped: ddfile not present)",
        'label reports a default skip reason',
    );
    is(
        $manager->_dependency_progress_label( 'install_ddfile', $skill, result => { skipped => 1, skip_reason => '' } ),
        "Install ddfile dependencies (skipped: ddfile not present)",
        'label ignores an empty skip reason',
    );
    like(
        $manager->_dependency_progress_label( 'install_ddfile', $skill, result => { error => 'boom' } ),
        qr/\(error: boom\)$/,
        'label reports an error with the manifest path when the file is present',
    );
    is(
        $manager->_dependency_progress_label( 'install_ddfile', $skill, result => { error => '' } ),
        "Install ddfile dependencies from " . File::Spec->catfile( $skill, 'ddfile' ),
        'label ignores an empty error string',
    );
    like(
        $manager->_dependency_progress_label( 'install_ddfile', $absent, result => { error => 'boom' } ),
        qr/^Install ddfile dependencies \(error: boom\)$/,
        'label reports an error without a path when the manifest is absent',
    );

    is_deeply( [ $manager->_dependency_progress_task_ids_for_skill_path(undef) ], [], 'task ids for an undef skill path are empty' );
    is_deeply( [ $manager->_dependency_progress_task_ids_for_skill_path('') ], [], 'task ids for an empty skill path are empty' );

    my $full = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $full, 'package.json' ), "{}\n" );
    _spew( File::Spec->catfile( $full, 'aptfile' ),      "git\n" );
    local $ENV{DD_TEST_OS}          = 'linux';
    local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
    my $tasks = $manager->dependency_progress_tasks_for_skill_path($full);
    ok( ( grep { $_->{id} eq 'install_package_json' } @$tasks ), 'dependency tasks include cross-platform manifests' );
    ok( ( grep { $_->{id} eq 'install_aptfile' } @$tasks ),      'dependency tasks include host-relevant system manifests' );
}

# ===========================================================================
# _skill_package_runner_prefix (root vs non-root).
# ===========================================================================
{
    is_deeply( [ $manager->_skill_package_runner_prefix ], ( $> == 0 ? [] : ['sudo'] ), 'runner prefix uses sudo for non-root users' );
}

# ===========================================================================
# Skill metadata / config reading helpers on a synthetic skill tree.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'meta-skill' );
    make_path( File::Spec->catdir( $skill, 'cli', 'run.d' ) );
    make_path( File::Spec->catdir( $skill, 'config', 'docker', 'db' ) );
    make_path( File::Spec->catdir( $skill, 'dashboards', 'nav' ) );
    _spew( File::Spec->catfile( $skill, 'cli', 'run' ), "#!/bin/sh\n:\n" );
    _spew( File::Spec->catfile( $skill, 'cli', 'run.d', '00-pre' ), "#!/bin/sh\n:\n" );
    _spew( File::Spec->catfile( $skill, 'config', 'docker', 'db', 'compose.yml' ), "services: {}\n" );
    _spew( File::Spec->catfile( $skill, 'dashboards', 'welcome' ), "TITLE: Hi\n" );
    _spew( File::Spec->catfile( $skill, 'dashboards', 'nav', 'menu.tt' ), "<nav></nav>\n" );
    _spew(
        File::Spec->catfile( $skill, 'config', 'config.json' ),
        '{"collectors":[{"name":"status","indicator":{"label":"S"}},{"name":"meta-skill.raw"},"notahash",{"name":""}]}',
    );

    my $meta = $manager->_skill_metadata( 'meta-skill', $skill );
    is( $meta->{name}, 'meta-skill', 'skill metadata reports the repo name' );
    is_deeply( $meta->{cli_commands}, ['run'], 'skill metadata lists cli commands' );
    is( $meta->{docker_services_count}, 1, 'skill metadata counts docker services' );
    is( $meta->{collectors_count}, 2, 'skill metadata counts only well-formed collectors' );
    is( $meta->{indicators_count}, 1, 'skill metadata counts collectors carrying an indicator' );
    is( $meta->{has_config}, JSON::XS::true(), 'skill metadata reports config presence' );

    my $collectors = $manager->_collector_details( 'meta-skill', $skill );
    my ($status) = grep { $_->{name} eq 'status' } @$collectors;
    is( $status->{qualified_name}, 'meta-skill.status', 'collector names are repo-qualified' );
    my ($already) = grep { $_->{name} eq 'meta-skill.raw' } @$collectors;
    is( $already->{qualified_name}, 'meta-skill.raw', 'already-qualified collector names are preserved' );

    my $usage = $manager->_skill_usage( 'meta-skill', $skill );
    is( $usage->{config}{merged_key}, '_meta-skill', 'usage exposes the merged config key' );

    # config reading edge cases.
    is_deeply( $manager->_read_skill_config_file( tempdir( CLEANUP => 1 ) ), {}, 'config reader returns empty when config.json is missing' );
    my $badcfg = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'bad' );
    make_path( File::Spec->catdir( $badcfg, 'config' ) );
    _spew( File::Spec->catfile( $badcfg, 'config', 'config.json' ), 'not json' );
    is_deeply( $manager->_read_skill_config_file($badcfg), {}, 'config reader returns empty for invalid JSON' );
    my $arraycfg = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'arr' );
    make_path( File::Spec->catdir( $arraycfg, 'config' ) );
    _spew( File::Spec->catfile( $arraycfg, 'config', 'config.json' ), '[]' );
    is_deeply( $manager->_read_skill_config_file($arraycfg), {}, 'config reader rejects a non-hash JSON document' );

    my $noncollector = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'nc' );
    make_path( File::Spec->catdir( $noncollector, 'config' ) );
    _spew( File::Spec->catfile( $noncollector, 'config', 'config.json' ), '{"collectors":"notarray"}' );
    is_deeply( $manager->_collector_details( 'nc', $noncollector ), [], 'collector details returns empty for a non-array collectors field' );

    is_deeply( [ $manager->_sorted_files(undef) ], [], 'sorted files returns empty for a false root' );
    is_deeply( [ $manager->_sorted_files( File::Spec->catdir( $home, 'no-such-dir' ) ) ], [], 'sorted files returns empty for a missing root' );

    # opendir failures on unreadable directories (non-root only).
  SKIP: {
        skip 'cannot deny read to root', 4 if $> == 0;
        my $locked = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'locked-skill' );
        make_path( File::Spec->catdir( $locked, 'cli' ) );
        make_path( File::Spec->catdir( $locked, 'dashboards' ) );
        make_path( File::Spec->catdir( $locked, 'config', 'docker' ) );
        chmod 0000, File::Spec->catdir( $locked, 'cli' );
        eval { $manager->_cli_command_details($locked); 1 };
        like( $@, qr/Unable to read/, 'cli command details dies on an unreadable cli root' );
        chmod 0000, File::Spec->catdir( $locked, 'dashboards' );
        eval { $manager->_page_details($locked); 1 };
        like( $@, qr/Unable to read/, 'page details dies on an unreadable dashboards root' );
        chmod 0000, File::Spec->catdir( $locked, 'config', 'docker' );
        eval { $manager->_docker_service_details($locked); 1 };
        like( $@, qr/Unable to read/, 'docker service details dies on an unreadable docker root' );
        my $sortlocked = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'sl' );
        make_path($sortlocked);
        chmod 0000, $sortlocked;
        eval { $manager->_sorted_files($sortlocked); 1 };
        like( $@, qr/Unable to read/, 'sorted files dies on an unreadable root' );
        chmod 0755, File::Spec->catdir( $locked, 'cli' );
        chmod 0755, File::Spec->catdir( $locked, 'dashboards' );
        chmod 0755, File::Spec->catdir( $locked, 'config', 'docker' );
        chmod 0755, $sortlocked;
    }
}

# ===========================================================================
# _local_checked_out_source and _local_skill_has_version.
# ===========================================================================
{
    is( $manager->_local_checked_out_source(undef), undef, 'local source detection ignores an undef source' );
    is( $manager->_local_checked_out_source('https://example.com/x'), undef, 'local source detection ignores a URL' );
    is( $manager->_local_checked_out_source( File::Spec->catdir( $home, 'not-a-dir' ) ), undef, 'local source detection ignores a non-directory' );

    my $checkout = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'checkout' );
    make_path( File::Spec->catdir( $checkout, 'sub' ) );
    is( $manager->_local_checked_out_source($checkout)->{error}, "Local skill source '$checkout' is missing a .git directory", 'local source detection requires a .git directory' );

    make_path( File::Spec->catdir( $checkout, '.git' ) );
    is( $manager->_local_checked_out_source($checkout)->{error}, "Local skill source '$checkout' is missing a .env file with VERSION", 'local source detection requires a versioned .env file' );

    _spew( File::Spec->catfile( $checkout, '.env' ), "NOTVERSION=1\n" );
    is( $manager->_local_checked_out_source($checkout)->{error}, "Local skill source '$checkout' is missing a .env file with VERSION", 'local source detection requires a VERSION assignment' );

    _spew( File::Spec->catfile( $checkout, '.env' ), "VERSION=1.00\n" );
    is( $manager->_local_checked_out_source($checkout), realpath($checkout), 'local source detection returns the resolved checkout path' );

    # _local_skill_has_version open failure (non-root only).
  SKIP: {
        skip 'cannot deny read to root', 1 if $> == 0;
        chmod 0000, File::Spec->catfile( $checkout, '.env' );
        eval { $manager->_local_skill_has_version($checkout); 1 };
        like( $@, qr/Unable to read/, 'version detection dies when the .env file cannot be read' );
        chmod 0644, File::Spec->catfile( $checkout, '.env' );
    }
}

# ===========================================================================
# _skill_env_version edge cases.
# ===========================================================================
{
    my $dir = tempdir( CLEANUP => 1 );
    is( $manager->_skill_env_version($dir), undef, 'env version is undef without a .env file' );
    _spew( File::Spec->catfile( $dir, '.env' ), "# comment\n\nOTHER=1\nVERSION = '2.5' \nMORE=x\n" );
    is( $manager->_skill_env_version($dir), '2.5', 'env version reads and unquotes the VERSION line' );
    my $noversion = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $noversion, '.env' ), "FOO=bar\n" );
    is( $manager->_skill_env_version($noversion), undef, 'env version is undef when VERSION is absent' );

  SKIP: {
        skip 'cannot deny read to root', 1 if $> == 0;
        chmod 0000, File::Spec->catfile( $dir, '.env' );
        eval { $manager->_skill_env_version($dir); 1 };
        like( $@, qr/Unable to read/, 'env version dies when the .env file cannot be read' );
        chmod 0644, File::Spec->catfile( $dir, '.env' );
    }
}

# ===========================================================================
# _prepare_skill_layout: fresh creation and a config write failure.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'layout' );
    ok( $manager->_prepare_skill_layout($skill), 'prepare layout creates the isolated skill tree' );
    ok( -f File::Spec->catfile( $skill, 'config', 'config.json' ), 'prepare layout writes a default config' );

    # If config.json already exists as a directory, the config write fails.
    my $skill2 = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'layout2' );
    make_path( File::Spec->catdir( $skill2, 'config', 'config.json' ) );
    eval { $manager->_prepare_skill_layout($skill2); 1 };
    like( $@, qr/Unable to write/, 'prepare layout dies when the config file cannot be written' );
}

# ===========================================================================
# _remove_existing_skill_path.
# ===========================================================================
{
    is( $manager->_remove_existing_skill_path( File::Spec->catdir( $home, 'no-such-skill' ) )->{success}, 1, 'removing a missing skill path succeeds' );
    my $present = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'present' );
    make_path($present);
    is( $manager->_remove_existing_skill_path($present)->{success}, 1, 'removing an existing skill path succeeds' );
    ok( !-e $present, 'removing an existing skill path deletes it' );
}

# ===========================================================================
# OS-specific dependency installers driven directly.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'os-skill' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'apkfile' ),    "git\n" );
    _spew( File::Spec->catfile( $skill, 'dnfile' ),     "git\n" );
    _spew( File::Spec->catfile( $skill, 'wingetfile' ), "Git.Git\n" );
    _spew( File::Spec->catfile( $skill, 'brewfile' ),   "jq\n" );
    _spew( File::Spec->catfile( $skill, 'aptfile' ),    "git\n" );

    {
        local $ENV{DD_TEST_OS} = 'linux';
        local $ENV{DD_TEST_ALPINE} = 1;
        ok( !$manager->_install_skill_apkfile($skill)->{error}, 'apkfile install runs on Alpine' );
    }
    {
        local $ENV{DD_TEST_OS} = 'linux';
        local $ENV{DD_TEST_FEDORA} = 1;
        ok( !$manager->_install_skill_dnfile($skill)->{error}, 'dnfile install runs on Fedora' );
    }
    {
        local $ENV{DD_TEST_OS} = 'MSWin32';
        ok( !$manager->_install_skill_wingetfile($skill)->{error}, 'wingetfile install runs on Windows' );
    }
    {
        local $ENV{DD_TEST_OS} = 'darwin';
        ok( !$manager->_install_skill_brewfile($skill)->{error}, 'brewfile install runs on macOS' );
    }
    {
        local $ENV{DD_TEST_OS} = 'linux';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        ok( !$manager->_install_skill_aptfile($skill)->{error}, 'aptfile install runs on Debian-like hosts' );
    }

    # Skips when the manifest is absent or the host is wrong.
    my $empty = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'empty' );
    make_path($empty);
    ok( $manager->_install_skill_apkfile($empty)->{skipped},        'apkfile install skips without a manifest' );
    ok( $manager->_install_skill_dnfile($empty)->{skipped},         'dnfile install skips without a manifest' );
    ok( $manager->_install_skill_wingetfile($empty)->{skipped},     'wingetfile install skips without a manifest' );
    ok( $manager->_install_skill_brewfile($empty)->{skipped},       'brewfile install skips without a manifest' );
    ok( $manager->_install_skill_aptfile($empty)->{skipped},        'aptfile install skips without a manifest' );
    ok( $manager->_install_skill_makefile($empty)->{skipped},       'makefile install skips without a Makefile' );
    ok( $manager->_install_skill_dockerfile($empty)->{skipped},     'dockerfile install skips without a dockerfile' );
    ok( $manager->_install_skill_package_json($empty)->{skipped},   'package.json install skips without a manifest' );
    ok( $manager->_install_skill_requirements_txt($empty)->{skipped}, 'requirements.txt install skips without a manifest' );
    ok( $manager->_install_skill_cpanfile($empty)->{skipped},       'cpanfile install skips without a manifest' );
    ok( $manager->_install_skill_cpanfile_local($empty)->{skipped}, 'cpanfile.local install skips without a manifest' );

    # Failure paths: the package manager exits non-zero.
    my $failbin = tempdir( CLEANUP => 1 );
    for my $cmd (qw(apk dnf winget brew apt-get docker cpanm npx python make dpkg-query)) {
        _spew( File::Spec->catfile( $failbin, $cmd ), "#!/bin/sh\nexit 7\n" );
        chmod 0755, File::Spec->catfile( $failbin, $cmd );
    }
    {
        local $ENV{PATH} = "$failbin:$ENV{PATH}";
        {
            local $ENV{DD_TEST_OS} = 'linux';
            local $ENV{DD_TEST_ALPINE} = 1;
            like( $manager->_install_skill_apkfile($skill)->{error}, qr/apk dependencies/, 'apkfile install reports failures' );
        }
        {
            local $ENV{DD_TEST_OS} = 'linux';
            local $ENV{DD_TEST_FEDORA} = 1;
            like( $manager->_install_skill_dnfile($skill)->{error}, qr/dnf dependencies/, 'dnfile install reports failures' );
        }
        {
            local $ENV{DD_TEST_OS} = 'MSWin32';
            like( $manager->_install_skill_wingetfile($skill)->{error}, qr/winget dependencies/, 'wingetfile install reports failures' );
        }
        {
            local $ENV{DD_TEST_OS} = 'darwin';
            like( $manager->_install_skill_brewfile($skill)->{error}, qr/brew dependencies/, 'brewfile install reports failures' );
        }
        {
            local $ENV{DD_TEST_OS} = 'linux';
            local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
            like( $manager->_install_skill_aptfile($skill)->{error}, qr/apt dependencies/, 'aptfile install reports failures' );
        }
    }
}

# ===========================================================================
# _install_skill_package_json success (npx stub) and the full dependency chain.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'node-skill' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'package.json' ), '{"dependencies":{"leftpad":"^1.0.0"}}' );
    my $res = $manager->_install_skill_package_json($skill);
    ok( !$res->{error}, 'package.json install merges node dependencies via npx' ) or diag $res->{error};
    ok( -d File::Spec->catdir( $home, 'node_modules', 'leftpad' ), 'package.json install populates HOME node_modules' );

    # A package.json with no dependency sections skips.
    my $skill2 = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'node-skill-2' );
    make_path($skill2);
    _spew( File::Spec->catfile( $skill2, 'package.json' ), '{"name":"x"}' );
    ok( $manager->_install_skill_package_json($skill2)->{skipped}, 'package.json install skips when there are no dependencies' );

    # requirements.txt success (python stub).
    my $pyskill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'py-skill' );
    make_path($pyskill);
    _spew( File::Spec->catfile( $pyskill, 'requirements.txt' ), "requests\n" );
    ok( !$manager->_install_skill_requirements_txt($pyskill)->{error}, 'requirements.txt install runs pip' );

    # cpanfile and cpanfile.local success (cpanm stub).
    my $perlskill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'perl-skill' );
    make_path($perlskill);
    _spew( File::Spec->catfile( $perlskill, 'cpanfile' ), "requires 'JSON::XS';\n" );
    _spew( File::Spec->catfile( $perlskill, 'cpanfile.local' ), "requires 'JSON::XS';\n" );
    ok( !$manager->_install_skill_cpanfile($perlskill)->{error}, 'cpanfile install runs cpanm' );
    ok( !$manager->_install_skill_cpanfile_local($perlskill)->{error}, 'cpanfile.local install runs cpanm' );

    # Makefile with tests + clean targets, and skip_tests behaviour.
    my $makeskill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'make-skill' );
    make_path($makeskill);
    _spew( File::Spec->catfile( $makeskill, 'Makefile' ), "install:\n\t\@:\ntest:\n\t\@:\nclean:\n\t\@:\n" );
    ok( !$manager->_install_skill_makefile($makeskill)->{error}, 'makefile install runs make targets' );
    my $skipmanager = Developer::Dashboard::SkillManager->new( paths => $paths, skip_tests => 1 );
    ok( !$skipmanager->_install_skill_makefile($makeskill)->{error}, 'makefile install skips tests when skip_tests is set' );

    my $testsonly = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'tests-skill' );
    make_path($testsonly);
    _spew( File::Spec->catfile( $testsonly, 'Makefile' ), "install:\n\t\@:\ntests:\n\t\@:\n" );
    ok( !$manager->_install_skill_makefile($testsonly)->{error}, 'makefile install runs the tests target when present' );

    # Makefile failure surfaces through the eval wrapper.
    {
        my $failbin = tempdir( CLEANUP => 1 );
        _spew( File::Spec->catfile( $failbin, 'make' ), "#!/bin/sh\necho boom 1>&2\nexit 2\n" );
        chmod 0755, File::Spec->catfile( $failbin, 'make' );
        local $ENV{PATH} = "$failbin:$ENV{PATH}";
        like( $manager->_install_skill_makefile($makeskill)->{error}, qr/Failed to run skill Makefile target/, 'makefile install reports a target failure' );
    }

    # dockerfile success.
    my $dockerskill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'docker-skill' );
    make_path($dockerskill);
    _spew( File::Spec->catfile( $dockerskill, 'dockerfile' ), "FROM scratch\n" );
    ok( !$manager->_install_skill_dockerfile($dockerskill)->{error}, 'dockerfile install builds an image' );
    {
        my $failbin = tempdir( CLEANUP => 1 );
        _spew( File::Spec->catfile( $failbin, 'docker' ), "#!/bin/sh\nexit 5\n" );
        chmod 0755, File::Spec->catfile( $failbin, 'docker' );
        local $ENV{PATH} = "$failbin:$ENV{PATH}";
        like( $manager->_install_skill_dockerfile($dockerskill)->{error}, qr/Failed to build Docker image/, 'dockerfile install reports build failures' );
    }
}

# ===========================================================================
# End-to-end install / reinstall / update / list / usage / enable / disable /
# uninstall using a real local git repository and offline clone.
# ===========================================================================
my $repos = tempdir( CLEANUP => 1 );
{
    my $repo = _make_git_skill( 'rich-skill', version => '1.00', with_all => 1 );

    my $installed = $manager->install( 'file://' . $repo );
    ok( !$installed->{error}, 'install clones and installs a rich skill' ) or diag $installed->{error};
    is( $installed->{repo_name}, 'rich-skill', 'install derives the repo name' );
    is( $installed->{status}, 'installed', 'first install reports an installed status' );
    ok( -f File::Spec->catfile( $paths->home_runtime_root, 'ddfile' ), 'install registers the source in the home ddfile' );

    # Second install with the same version is a reinstall reporting no update,
    # and the source is already present in the ddfile.
    my $reinstalled = $manager->install( 'file://' . $repo );
    is( $reinstalled->{status}, 'no update', 'reinstall of the same version reports no update' );

    # Change the source version and reinstall to report an update.
    _bump_git_skill_version( $repo, '2.00' );
    my $updated = $manager->install( 'file://' . $repo );
    is( $updated->{status}, 'updated', 'reinstall after a version bump reports an update' );

    my $list = $manager->list;
    ok( ( grep { $_->{name} eq 'rich-skill' } @$list ), 'list reports the installed skill' );

    ok( $manager->is_enabled('rich-skill'), 'is_enabled reports an installed skill as enabled' );
    is( $manager->is_enabled(''), 0, 'is_enabled rejects an empty repo name' );
    is( $manager->is_enabled('absent'), 0, 'is_enabled returns false for an unknown skill' );

    my $usage = $manager->usage('rich-skill');
    is( $usage->{name}, 'rich-skill', 'usage reports the installed skill metadata' );

    # get_skill_path guards.
    is( $manager->get_skill_path(''), undef, 'get_skill_path rejects an empty repo name' );
    ok( $manager->get_skill_path('rich-skill'), 'get_skill_path resolves an installed skill' );

    # enable / disable round trip.
    my $disabled = $manager->disable('rich-skill');
    ok( !$disabled->{error}, 'disable marks the skill disabled' );
    ok( !$manager->is_enabled('rich-skill'), 'a disabled skill is not enabled' );
    my $enabled = $manager->enable('rich-skill');
    ok( !$enabled->{error}, 'enable clears the disabled marker' );
    # enable with no marker present exercises the marker-absent branch.
    ok( !$manager->enable('rich-skill')->{error}, 'enable is idempotent when no marker exists' );

    # update pulls from the origin remote.
    my $update = $manager->update('rich-skill');
    ok( !$update->{error}, 'update pulls the latest checkout' ) or diag $update->{error};

    # Guard branches for the repo-name-required methods.
    is( $manager->install(undef)->{error}, 'Missing skill source', 'install requires a source' );
    is( $manager->uninstall(undef)->{error}, 'Missing repo name', 'uninstall requires a repo name' );
    is( $manager->update(undef)->{error}, 'Missing repo name', 'update requires a repo name' );
    is( $manager->enable(undef)->{error}, 'Missing repo name', 'enable requires a repo name' );
    is( $manager->disable(undef)->{error}, 'Missing repo name', 'disable requires a repo name' );
    is( $manager->usage(undef)->{error}, 'Missing repo name', 'usage requires a repo name' );

    # not-found branches.
    is( $manager->uninstall('ghost')->{error}, "Skill 'ghost' not found", 'uninstall reports a missing skill' );
    is( $manager->update('ghost')->{error}, "Skill 'ghost' not found", 'update reports a missing skill' );
    is( $manager->enable('ghost')->{error}, "Skill 'ghost' not found", 'enable reports a missing skill' );
    is( $manager->disable('ghost')->{error}, "Skill 'ghost' not found", 'disable reports a missing skill' );
    is( $manager->usage('ghost')->{error}, "Skill 'ghost' not found", 'usage reports a missing skill' );

    # update failure: git pull fails against a broken remote.
    {
        my $failbin = tempdir( CLEANUP => 1 );
        _spew( File::Spec->catfile( $failbin, 'git' ), "#!/bin/sh\necho nope 1>&2\nexit 1\n" );
        chmod 0755, File::Spec->catfile( $failbin, 'git' );
        local $ENV{PATH} = "$failbin:$ENV{PATH}";
        like( $manager->update('rich-skill')->{error}, qr/Failed to update skill/, 'update reports git pull failures' );
    }

    # uninstall.
    my $uninstalled = $manager->uninstall('rich-skill');
    ok( !$uninstalled->{error}, 'uninstall removes the skill' ) or diag $uninstalled->{error};
    ok( !$manager->get_skill_path('rich-skill'), 'uninstall deletes the skill path' );
}

# ===========================================================================
# install() failure and registration-error propagation via monkeypatching.
# ===========================================================================
{
    my $repo = _make_git_skill( 'reg-skill', version => '1.00' );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_register_home_gitignore_skill = sub { return { error => 'gitignore boom' } };
        is( $manager->install( 'file://' . $repo )->{error}, 'gitignore boom', 'install propagates a gitignore registration error' );
    }
    $manager->uninstall('reg-skill');
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_register_root_ddfile_source = sub { return { error => 'ddfile boom' } };
        is( $manager->install( 'file://' . $repo )->{error}, 'ddfile boom', 'install propagates a ddfile registration error' );
    }
    $manager->uninstall('reg-skill');

    # install honours the skip-registry environment flag.
    {
        local $ENV{DEVELOPER_DASHBOARD_SKIP_SKILL_REGISTRY} = 1;
        my $skipped = $manager->install( 'file://' . $repo );
        ok( !$skipped->{error}, 'install succeeds while skipping the source registry' );
        ok( !exists $skipped->{registered_ddfile}, 'install skips ddfile registration when requested' );
    }
    $manager->uninstall('reg-skill');

    # _install_to_skills_root guards.
    is( $manager->_install_to_skills_root( '', 'root' )->{error}, 'Missing skill source', '_install_to_skills_root requires a source' );
    is( $manager->_install_to_skills_root( 'src', '' )->{error}, 'Missing skills root', '_install_to_skills_root requires a skills root' );
    is( $manager->_install_to_skills_root( 'http://', $paths->skills_root )->{error}, 'Unable to extract repo name from http://', '_install_to_skills_root requires a resolvable repo name' );

    # A local checkout that fails validation propagates its error.
    my $bad_checkout = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'bad-checkout' );
    make_path($bad_checkout);
    like( $manager->_install_to_skills_root( $bad_checkout, $paths->skills_root )->{error}, qr/missing a \.git directory/, '_install_to_skills_root surfaces a local checkout validation error' );

    # A local checkout sync failure removes the partial target and reports.
    my $checkout = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'good-checkout' );
    make_path( File::Spec->catdir( $checkout, '.git' ) );
    _spew( File::Spec->catfile( $checkout, '.env' ), "VERSION=1.00\n" );
    _spew( File::Spec->catfile( $checkout, 'cli' ), "not-a-dir\n" );
    {
        # Sync failure that leaves a partial directory behind (drives the -d cleanup).
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_sync_local_skill_source = sub {
            my ( $self, undef, $target ) = @_;
            make_path($target);
            return { error => 'sync boom' };
        };
        is( $manager->_install_to_skills_root( $checkout, $paths->skills_root )->{error}, 'sync boom', '_install_to_skills_root surfaces a local sync failure' );
    }
    {
        # Sync failure that left no directory behind (drives the -d false side).
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_sync_local_skill_source = sub { return { error => 'sync boom 2' } };
        is( $manager->_install_to_skills_root( $checkout, $paths->skills_root )->{error}, 'sync boom 2', '_install_to_skills_root surfaces a local sync failure without a partial target' );
    }
    # A clone failure that created a partial target removes it and reports.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_clone_skill_source = sub {
            my ( $self, undef, $target ) = @_;
            make_path($target);
            return { error => 'clone boom' };
        };
        is( $manager->_install_to_skills_root( 'someskill', $paths->skills_root )->{error}, 'clone boom', '_install_to_skills_root surfaces a clone failure' );
    }
    # A clone failure that created no target still reports (drives the -d false side).
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_clone_skill_source = sub { return { error => 'clone boom 2' } };
        is( $manager->_install_to_skills_root( 'someskill', $paths->skills_root )->{error}, 'clone boom 2', '_install_to_skills_root surfaces a clone failure without a partial target' );
    }
    # A remove-existing failure propagates.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_remove_existing_skill_path = sub { return { error => 'remove boom' } };
        is( $manager->_install_to_skills_root( 'file://' . $repo, $paths->skills_root )->{error}, 'remove boom', '_install_to_skills_root surfaces a remove-existing failure' );
    }
    # A dependency failure during install propagates.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_install_skill_dependencies = sub { return { error => 'dep boom' } };
        is( $manager->_install_to_skills_root( 'file://' . $repo, $paths->skills_root )->{error}, 'dep boom', '_install_to_skills_root surfaces a dependency failure' );
    }
    $manager->uninstall('reg-skill');
}

# ===========================================================================
# install_many variations.
# ===========================================================================
{
    is( $manager->install_many()->{error}, 'Missing skill source', 'install_many requires at least one source' );
    is( $manager->install_many( undef, '' )->{error}, 'Missing skill source', 'install_many drops undef and empty sources' );

    my $repo = _make_git_skill( 'many-skill', version => '1.00' );
    my $single = $manager->install_many( 'file://' . $repo );
    ok( $single->{success}, 'install_many installs a single source' );
    is( $single->{message}, 'Installed skill successfully', 'install_many uses the singular success message' );
    $manager->uninstall('many-skill');

    my $repo2 = _make_git_skill( 'many-skill-2', version => '1.00' );
    my $multi = $manager->install_many( undef, 'file://' . $repo, 'file://' . $repo2 );
    ok( $multi->{success}, 'install_many installs multiple sources' );
    is( $multi->{message}, 'Installed skills successfully', 'install_many uses the plural success message' );
    $manager->uninstall('many-skill');
    $manager->uninstall('many-skill-2');

    # A failing source aborts the batch and returns completed results.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::install = sub { return { error => 'install boom' } };
        my $failed = Developer::Dashboard::SkillManager->new( paths => $paths )->install_many('anything');
        like( $failed->{error}, qr/Failed to install skill source anything: install boom/, 'install_many aborts on the first failure' );
        is( scalar( @{ $failed->{results} } ), 1, 'install_many returns the completed results' );
    }
}

# ===========================================================================
# install_from_ddfiles / install_registered_skills / registered_skill_sources.
# ===========================================================================
{
    # No manifest files present anywhere.
    my $empty = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'empty-base' );
    make_path($empty);
    like( $manager->install_from_ddfiles($empty)->{error}, qr/No ddfile or ddfile\.local found/, 'install_from_ddfiles requires a manifest' );

    # realpath fallback: a non-existent base directory.
    like( $manager->install_from_ddfiles('/no/such/base/xyz')->{error}, qr{/no/such/base/xyz}, 'install_from_ddfiles falls back to the raw base when realpath fails' );

    # default base directory.
    like( $manager->install_from_ddfiles(undef)->{error}, qr/No ddfile or ddfile\.local found/, 'install_from_ddfiles defaults to the current directory' );

    my $repo = _make_git_skill( 'ddfile-skill', version => '1.00' );

    # A base with a ddfile (global manifest) installs into the home skills root.
    my $global_base = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'global-base' );
    make_path($global_base);
    _spew( File::Spec->catfile( $global_base, 'ddfile' ), 'file://' . $repo . "\n" );
    my $global = $manager->install_from_ddfiles($global_base);
    ok( $global->{success}, 'install_from_ddfiles installs from a global ddfile' ) or diag $global->{error};
    $manager->uninstall('ddfile-skill');

    # A base with only ddfile.local installs into the nested skills root.
    my $local_base = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'local-base' );
    make_path($local_base);
    _spew( File::Spec->catfile( $local_base, 'ddfile.local' ), 'file://' . $repo . "\n" );
    my $local = $manager->install_from_ddfiles($local_base);
    ok( $local->{success}, 'install_from_ddfiles installs from a ddfile.local manifest' ) or diag $local->{error};

    # A global ddfile whose source fails aborts with the global error.
    my $badglobal = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'bad-global' );
    make_path($badglobal);
    my $unversioned = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'unversioned' );
    make_path( File::Spec->catdir( $unversioned, '.git' ) );
    _spew( File::Spec->catfile( $badglobal, 'ddfile' ), $unversioned . "\n" );
    like( $manager->install_from_ddfiles($badglobal)->{error}, qr/missing a \.env file with VERSION/, 'install_from_ddfiles surfaces a global manifest failure' );

    # A ddfile.local whose source fails aborts with the local error.
    my $badlocal = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'bad-local' );
    make_path($badlocal);
    _spew( File::Spec->catfile( $badlocal, 'ddfile.local' ), $unversioned . "\n" );
    like( $manager->install_from_ddfiles($badlocal)->{error}, qr/missing a \.env file with VERSION/, 'install_from_ddfiles surfaces a local manifest failure' );

    # registered_skill_sources: none, then after registration.
    is_deeply( [ $manager->registered_skill_sources ], [], 'registered_skill_sources is empty without a home ddfile' );

    # install_registered_skills: missing ddfile, empty ddfile, populated ddfile, failing ddfile.
    my $home_ddfile = File::Spec->catfile( $paths->home_runtime_root, 'ddfile' );
    unlink $home_ddfile if -f $home_ddfile;
    like( $manager->install_registered_skills->{error}, qr/No root ddfile found/, 'install_registered_skills requires a home ddfile' );

    _spew( $home_ddfile, "# only comments\n\n" );
    like( $manager->install_registered_skills->{error}, qr/does not list any skills/, 'install_registered_skills requires at least one source' );

    _spew( $home_ddfile, 'file://' . $repo . "\n" );
    is_deeply( [ $manager->registered_skill_sources ], [ 'file://' . $repo ], 'registered_skill_sources lists the registered source' );
    my $registered = $manager->install_registered_skills;
    ok( $registered->{success}, 'install_registered_skills installs from the home ddfile' ) or diag $registered->{error};
    $manager->uninstall('ddfile-skill');

    _spew( $home_ddfile, $unversioned . "\n" );
    like( $manager->install_registered_skills->{error}, qr/missing a \.env file with VERSION/, 'install_registered_skills surfaces install failures' );
    unlink $home_ddfile;

    # _install_manifest_file guards.
    is( $manager->_install_manifest_file( File::Spec->catfile( $empty, 'absent' ) )->{skipped}, 1, '_install_manifest_file skips a missing manifest' );
    my $mf = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'mf' );
    _spew( $mf, 'file://' . $repo . "\n" );
    is( $manager->_install_manifest_file( $mf )->{error}, 'Missing skills root for mf', '_install_manifest_file requires a skills root' );
    my $blankmf = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'blank' );
    _spew( $blankmf, "# comment only\n" );
    is( $manager->_install_manifest_file( $blankmf, skills_root => $paths->skills_root )->{skipped}, 1, '_install_manifest_file skips a manifest with no sources' );

    # _install_manifest_file with a progress callback and an operations list.
    my @ops;
    my @emitted;
    my $pm = Developer::Dashboard::SkillManager->new( paths => $paths, progress => sub { push @emitted, $_[0] } );
    my $ok = $pm->_install_manifest_file(
        $mf,
        manifest_name => 'ddfile',
        skills_root   => $paths->skills_root,
        operations    => \@ops,
        progress      => 1,
    );
    ok( $ok->{success}, '_install_manifest_file installs sources with progress' ) or diag $ok->{error};
    is( scalar(@ops), 1, '_install_manifest_file records operations' );
    ok( ( grep { ( $_->{status} || '' ) eq 'running' } @emitted ), '_install_manifest_file emits running progress' );
    $manager->uninstall('ddfile-skill');

    # _install_manifest_file where a source fails, with progress.
    my $badmf = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'badmf' );
    _spew( $badmf, $unversioned . "\n" );
    my $fail = $pm->_install_manifest_file( $badmf, skills_root => $paths->skills_root, progress => 1 );
    like( $fail->{error}, qr/missing a \.env file with VERSION/, '_install_manifest_file surfaces a source failure with progress' );
}

# ===========================================================================
# Root ddfile registration/unregistration helpers, direct.
# ===========================================================================
{
    my $rp = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm = Developer::Dashboard::SkillManager->new( paths => $rp );

    is( $rm->_register_root_ddfile_source(undef)->{error}, 'Missing skill source', 'register requires a source' );

    my $first = $rm->_register_root_ddfile_source('alpha');
    is( $first->{registered}, 1, 'register appends a new source' );
    my $again = $rm->_register_root_ddfile_source('alpha');
    is( $again->{registered}, 0, 'register is idempotent for an existing source' );

    # A ddfile without a trailing newline gets a separator before the append.
    my $ddfile = File::Spec->catfile( $rp->home_runtime_root, 'ddfile' );
    _spew( $ddfile, "# comment\n\nbeta" );
    my $sep = $rm->_register_root_ddfile_source('gamma');
    is( $sep->{registered}, 1, 'register handles a manifest lacking a trailing newline' );

    is( $rm->_unregister_root_ddfile_source(undef)->{error}, 'Missing repo name', 'unregister requires a repo name' );

    # unregister against an absent ddfile.
    my $rp2 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm2 = Developer::Dashboard::SkillManager->new( paths => $rp2 );
    is( $rm2->_unregister_root_ddfile_source('x')->{removed}, 0, 'unregister is a no-op without a ddfile' );

    # unregister that removes a matching entry (removed > 0).
    my $ddfile2 = File::Spec->catfile( $rp2->home_runtime_root, 'ddfile' );
    _spew( $ddfile2, "# keep\nhttps://github.com/u/target.git\n\nother\n" );
    my $removed = $rm2->_unregister_root_ddfile_source('target');
    is( $removed->{removed}, 1, 'unregister removes matching entries' );

    # unregister where nothing matches (removed == 0, so no rewrite).
    is( $rm2->_unregister_root_ddfile_source('nomatch')->{removed}, 0, 'unregister leaves the file untouched when nothing matches' );

  SKIP: {
        skip 'cannot deny access to root', 4 if $> == 0;

        # register read failure.
        my $rp3 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
        my $rm3 = Developer::Dashboard::SkillManager->new( paths => $rp3 );
        my $dd3 = File::Spec->catfile( $rp3->home_runtime_root, 'ddfile' );
        _spew( $dd3, "https://github.com/u/alpha.git\n" );
        chmod 0000, $dd3;
        like( $rm3->_register_root_ddfile_source('beta')->{error}, qr/Unable to read root ddfile/, 'register reports a read failure' );

        # register append failure: readable but not writable.
        chmod 0400, $dd3;
        like( $rm3->_register_root_ddfile_source('beta')->{error}, qr/Unable to update root ddfile/, 'register reports an append failure' );

        # unregister read failure.
        chmod 0000, $dd3;
        like( $rm3->_unregister_root_ddfile_source('alpha')->{error}, qr/Unable to read root ddfile/, 'unregister reports a read failure' );

        # unregister write failure: readable, matching, but not writable.
        chmod 0400, $dd3;
        like( $rm3->_unregister_root_ddfile_source('alpha')->{error}, qr/Unable to update root ddfile/, 'unregister reports a write failure' );
        chmod 0600, $dd3;
    }

    # register read of an empty ddfile hits the readline // '' fallback.
    my $rp4 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm4 = Developer::Dashboard::SkillManager->new( paths => $rp4 );
    my $dd4 = File::Spec->catfile( $rp4->home_runtime_root, 'ddfile' );
    _spew( $dd4, '' );
    is( $rm4->_register_root_ddfile_source('alpha')->{registered}, 1, 'register handles an empty existing ddfile' );

    # unregister read of an empty ddfile hits the readline // '' fallback.
    my $rp5 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm5 = Developer::Dashboard::SkillManager->new( paths => $rp5 );
    my $dd5 = File::Spec->catfile( $rp5->home_runtime_root, 'ddfile' );
    _spew( $dd5, '' );
    is( $rm5->_unregister_root_ddfile_source('alpha')->{removed}, 0, 'unregister handles an empty existing ddfile' );
}

# ===========================================================================
# Home .gitignore registration helper, direct.
# ===========================================================================
{
    is( $manager->_register_home_gitignore_skill(undef)->{error}, 'Missing repo name', 'gitignore registration requires a repo name' );

    # No home .gitignore present -> skipped.
    my $rpn = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rmn = Developer::Dashboard::SkillManager->new( paths => $rpn );
    ok( $rmn->_register_home_gitignore_skill('skill')->{skipped}, 'gitignore registration skips when no .gitignore exists' );

    # Empty .gitignore -> readline fallback and no separator.
    my $rp1 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm1 = Developer::Dashboard::SkillManager->new( paths => $rp1 );
    my $gi1 = File::Spec->catfile( $rp1->home_runtime_root, '.gitignore' );
    _spew( $gi1, '' );
    is( $rm1->_register_home_gitignore_skill('skill')->{registered}, 1, 'gitignore registration appends to an empty file' );

    # Existing content ending with a newline, plus comment/blank lines.
    my $rp2 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm2 = Developer::Dashboard::SkillManager->new( paths => $rp2 );
    my $gi2 = File::Spec->catfile( $rp2->home_runtime_root, '.gitignore' );
    _spew( $gi2, "# comment\n\nother/\n" );
    is( $rm2->_register_home_gitignore_skill('skill')->{registered}, 1, 'gitignore registration appends after existing content' );
    is( $rm2->_register_home_gitignore_skill('skill')->{registered}, 0, 'gitignore registration is idempotent' );

    # Existing content without a trailing newline gets a separator.
    my $rp3 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm3 = Developer::Dashboard::SkillManager->new( paths => $rp3 );
    my $gi3 = File::Spec->catfile( $rp3->home_runtime_root, '.gitignore' );
    _spew( $gi3, "existing/" );
    is( $rm3->_register_home_gitignore_skill('skill')->{registered}, 1, 'gitignore registration adds a separator when needed' );

  SKIP: {
        skip 'cannot deny access to root', 2 if $> == 0;
        my $rp4 = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
        my $rm4 = Developer::Dashboard::SkillManager->new( paths => $rp4 );
        my $gi4 = File::Spec->catfile( $rp4->home_runtime_root, '.gitignore' );
        _spew( $gi4, "keep/\n" );
        chmod 0000, $gi4;
        like( $rm4->_register_home_gitignore_skill('skill')->{error}, qr/Unable to read home gitignore/, 'gitignore registration reports a read failure' );
        chmod 0400, $gi4;
        like( $rm4->_register_home_gitignore_skill('skill')->{error}, qr/Unable to update home gitignore/, 'gitignore registration reports an append failure' );
        chmod 0600, $gi4;
    }
}

# ===========================================================================
# uninstall path-safety guard: refuse to remove outside the skills roots.
# ===========================================================================
{
    my $outside = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'outside' );
    make_path($outside);
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::get_skill_path = sub { return $outside };
    like( $manager->uninstall('outside')->{error}, qr/Refusing to uninstall path outside skills root/, 'uninstall refuses a path outside the skills roots' );
}

# ===========================================================================
# uninstall remove_tree failure via monkeypatched remove-existing helper is
# covered through File::Path behaviour on a read-only parent (non-root only).
# ===========================================================================
{
  SKIP: {
        skip 'cannot deny access to root', 1 if $> == 0;
        my $repo = _make_git_skill( 'rmfail-skill', version => '1.00' );
        my $installed = $manager->install( 'file://' . $repo );
        ok( !$installed->{error}, 'install a skill to exercise a protected uninstall' ) or diag $installed->{error};
        my $skill_path = $manager->get_skill_path('rmfail-skill');
        my $skills_root = $paths->skills_root;
        chmod 0500, $skills_root;
        my $result = $manager->uninstall('rmfail-skill');
        chmod 0755, $skills_root;
        like( $result->{error}, qr/Failed to uninstall skill/, 'uninstall reports a remove_tree failure' );
        $manager->uninstall('rmfail-skill');
    }
}

# ===========================================================================
# registered_skill_sources with no home ddfile at all (fresh home).
# ===========================================================================
{
    my $rp = Developer::Dashboard::PathRegistry->new( home => tempdir( CLEANUP => 1 ) );
    my $rm = Developer::Dashboard::SkillManager->new( paths => $rp );
    is_deeply( [ $rm->registered_skill_sources ], [], 'registered_skill_sources returns nothing when the home ddfile is absent' );
}

# ===========================================================================
# uninstall: registration error propagation, and a non-existent skills-root
# layer that drives the realpath fallback.
# ===========================================================================
{
    # _unregister error propagation.
    my $repo = _make_git_skill( 'unreg-skill', version => '1.00' );
    $manager->install( 'file://' . $repo );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_unregister_root_ddfile_source = sub { return { error => 'unreg boom' } };
        is( $manager->uninstall('unreg-skill')->{error}, 'unreg boom', 'uninstall propagates an unregister failure' );
    }
    $manager->uninstall('unreg-skill');

    # A layer whose skills root does not exist exercises the realpath fallback.
    my $probe_root = File::Spec->catdir( $paths->skills_root, 'probe262' );
    make_path($probe_root);
    my $projdir = File::Spec->catdir( $home, 'proj262' );
    make_path( File::Spec->catdir( $projdir, '.developer-dashboard' ) );
    my $save = getcwd();
    chdir $projdir or die "Unable to chdir to $projdir: $!";
    my $pp  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $pm  = Developer::Dashboard::SkillManager->new( paths => $pp );
    my $res = $pm->uninstall('probe262');
    chdir $save or die "Unable to chdir back to $save: $!";
    ok( !$res->{error}, 'uninstall resolves a skill across a layer whose skills root does not exist' ) or diag $res->{error};
}

# ===========================================================================
# update: a dependency failure propagates.
# ===========================================================================
{
    my $repo = _make_git_skill( 'updep-skill', version => '1.00' );
    $manager->install( 'file://' . $repo );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::SkillManager::_install_skill_dependencies = sub { return { error => 'update dep boom' } };
        is( $manager->update('updep-skill')->{error}, 'update dep boom', 'update propagates a dependency failure' );
    }
    $manager->uninstall('updep-skill');
}

# ===========================================================================
# enable/disable marker write and unlink failures (non-root only).
# ===========================================================================
{
  SKIP: {
        skip 'cannot deny write to root', 2 if $> == 0;
        my $sk = File::Spec->catdir( $paths->skills_root, 'marker-skill' );
        make_path($sk);
        chmod 0500, $sk;
        like( $manager->disable('marker-skill')->{error}, qr/Unable to write disabled marker/, 'disable reports a marker write failure' );
        chmod 0755, $sk;
        $manager->disable('marker-skill');
        chmod 0500, $sk;
        like( $manager->enable('marker-skill')->{error}, qr/Unable to remove disabled marker/, 'enable reports a marker removal failure' );
        chmod 0755, $sk;
        $manager->uninstall('marker-skill');
    }
}

# ===========================================================================
# _clone_skill_source failure with real git stderr output.
# ===========================================================================
{
    my $target = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'clone-real-fail' );
    my $failed = $manager->_clone_skill_source( File::Spec->catdir( tempdir( CLEANUP => 1 ), 'no-such-repo.git' ), $target );
    like( $failed->{error}, qr/Failed to clone/, 'clone reports a real git failure with captured stderr' );
}

# ===========================================================================
# _remove_tree_error_text: undef entry value and an empty-hash entry.
# ===========================================================================
{
    is(
        $manager->_remove_tree_error_text( [ { '/c' => undef } ] ),
        '/c: unknown error',
        'remove_tree error text handles an undef message',
    );
    is(
        $manager->_remove_tree_error_text( [ {} ] ),
        'unknown remove_tree failure',
        'remove_tree error text falls back when no parts are produced',
    );
}

# ===========================================================================
# _is_debian_like defers to alpine detection, and _host_progress detects the
# Debian filesystem marker when no environment override is present.
# ===========================================================================
{
    {
        local $ENV{DD_TEST_OS}     = 'linux';
        local $ENV{DD_TEST_ALPINE} = 1;
        delete local $ENV{DD_TEST_DEBIAN_LIKE};
        is( $manager->_is_debian_like, 0, 'debian detection defers to alpine detection' );
    }
    {
        # No DD_TEST_OS override: $os falls through to the real $^O (linux here).
        delete local $ENV{DD_TEST_OS};
        delete local $ENV{DD_TEST_DEBIAN_LIKE};
        delete local $ENV{DD_TEST_ALPINE};
        delete local $ENV{DD_TEST_FEDORA};
        is_deeply( [ $manager->_host_progress_system_task_ids ], ['install_aptfile'], 'host progress detects Debian from the filesystem marker' );
    }
}

# ===========================================================================
# _apt_package_is_installed status matching.
# ===========================================================================
{
    my $bin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin, 'dpkg-query' ), "#!/bin/sh\nprintf 'install ok installed'\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin, 'dpkg-query' );
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    is( $manager->_apt_package_is_installed('git'), 1, 'apt detection recognizes an installed package' );

    my $bin2 = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin2, 'dpkg-query' ), "#!/bin/sh\nprintf 'unknown'\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin2, 'dpkg-query' );
    local $ENV{PATH} = "$bin2:$ENV{PATH}";
    is( $manager->_apt_package_is_installed('nope'), 0, 'apt detection rejects an unmatched dpkg status' );
}

# ===========================================================================
# _install_skill_dependencies: success with output, and failures with the
# progress task visible and hidden.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'dep-run-skill' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'aptfile' ), "pkg\n" );

    # Success with output: apt-get echoes and exits 0.
    my $okbin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $okbin, 'apt-get' ),    "#!/bin/sh\nprintf 'installing pkg\\n'\nprintf 'apt-note\\n' 1>&2\nexit 0\n" );
    _spew( File::Spec->catfile( $okbin, 'dpkg-query' ), "#!/bin/sh\nexit 1\n" );
    chmod 0755, File::Spec->catfile( $okbin, 'apt-get' );
    chmod 0755, File::Spec->catfile( $okbin, 'dpkg-query' );
    {
        local $ENV{PATH}                = "$okbin:$ENV{PATH}";
        local $ENV{DD_TEST_OS}          = 'linux';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        my $res = $manager->_install_skill_dependencies($skill);
        ok( !$res->{error}, 'dependency install succeeds and collects output' ) or diag $res->{error};
        like( $res->{stdout}, qr/installing pkg/, 'dependency install accumulates step stdout' );
    }

    # Failure with the aptfile task visible (Debian host view).
    my $failbin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $failbin, 'apt-get' ),    "#!/bin/sh\nprintf 'boom\\n' 1>&2\nexit 9\n" );
    _spew( File::Spec->catfile( $failbin, 'dpkg-query' ), "#!/bin/sh\nexit 1\n" );
    chmod 0755, File::Spec->catfile( $failbin, 'apt-get' );
    chmod 0755, File::Spec->catfile( $failbin, 'dpkg-query' );
    {
        local $ENV{PATH}                = "$failbin:$ENV{PATH}";
        local $ENV{DD_TEST_OS}          = 'linux';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        like( $manager->_install_skill_dependencies($skill)->{error}, qr/apt dependencies/, 'dependency install reports a visible-task failure' );
    }

    # Failure with the aptfile task hidden (macOS host view) but still executed.
    {
        local $ENV{PATH}                = "$failbin:$ENV{PATH}";
        local $ENV{DD_TEST_OS}          = 'darwin';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        like( $manager->_install_skill_dependencies($skill)->{error}, qr/apt dependencies/, 'dependency install reports a hidden-task failure' );
    }
}

# ===========================================================================
# _install_skill_dependency_manifest: running the recursive install loop.
# ===========================================================================
{
    # Successful loop with output.
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'parent', 'loop-skill' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'ddfile' ), "loop-dep\n" );
    my $bin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin, 'dashboard' ), "#!/bin/sh\nprintf out\nprintf err 1>&2\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin, 'dashboard' );
    {
        local $ENV{PATH} = "$bin:$ENV{PATH}";
        my $res = $manager->_install_skill_ddfile($skill);
        ok( !$res->{error}, 'dependency manifest install runs a dependent skill' ) or diag $res->{error};
        is( $res->{stdout}, 'out', 'dependency manifest install collects dependent stdout' );
    }

    # A pre-seeded install stack short-circuits the split fallback and marks
    # the running skill and stack entries as already-seen dependencies.
    {
        local $ENV{PATH} = "$bin:$ENV{PATH}";
        local $ENV{DEVELOPER_DASHBOARD_INSTALL_STACK} = 'loop-dep:already';
        ok( $manager->_install_skill_ddfile($skill)->{skipped}, 'dependency manifest install honours a pre-seeded install stack' );
    }

    # Silent loop: no output at all -> skipped.
    my $skill2 = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'parent', 'silent-skill' );
    make_path($skill2);
    _spew( File::Spec->catfile( $skill2, 'ddfile' ), "silent-dep\n" );
    my $bin2 = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin2, 'dashboard' ), "#!/bin/sh\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin2, 'dashboard' );
    {
        local $ENV{PATH} = "$bin2:$ENV{PATH}";
        ok( $manager->_install_skill_ddfile($skill2)->{skipped}, 'dependency manifest install skips when the dependent is silent' );
    }

    # Stderr-only loop: covers the "@stdout empty but @stderr present" case.
    my $skill3 = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'parent', 'stderr-skill' );
    make_path($skill3);
    _spew( File::Spec->catfile( $skill3, 'ddfile' ), "stderr-dep\n" );
    my $bin3 = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin3, 'dashboard' ), "#!/bin/sh\nprintf warn 1>&2\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin3, 'dashboard' );
    {
        local $ENV{PATH} = "$bin3:$ENV{PATH}";
        my $res = $manager->_install_skill_ddfile($skill3);
        is( $res->{stderr}, 'warn', 'dependency manifest install collects dependent stderr alone' );
    }

    # chdir into the skills root fails (relative skill path -> empty root).
    {
        my $save = getcwd();
        chdir $home or die "Unable to chdir to $home: $!";
        make_path( File::Spec->catdir( $home, 'relskill' ) );
        _spew( File::Spec->catfile( $home, 'relskill', 'ddfile' ), "rel-dep\n" );
        eval { $manager->_install_skill_ddfile('relskill'); 1 };
        my $err = $@;
        chdir $save or die "Unable to chdir back to $save: $!";
        like( $err, qr/Unable to chdir to/, 'dependency manifest install dies when the skills root cannot be entered' );
    }

    # chdir back to the caller cwd fails: the dependent install removes it.
    {
        my $depskill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'depparent', 'chdirfail-skill' );
        make_path($depskill);
        _spew( File::Spec->catfile( $depskill, 'ddfile' ), "chdirfail-dep\n" );
        my $victim = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'victim-cwd' );
        make_path($victim);
        my $killbin = tempdir( CLEANUP => 1 );
        _spew( File::Spec->catfile( $killbin, 'dashboard' ), "#!/bin/sh\nrmdir '$victim'\nexit 0\n" );
        chmod 0755, File::Spec->catfile( $killbin, 'dashboard' );
        my $save = getcwd();
        chdir $victim or die "Unable to chdir to $victim: $!";
        {
            local $ENV{PATH} = "$killbin:$ENV{PATH}";
            eval { $manager->_install_skill_ddfile($depskill); 1 };
        }
        my $err = $@;
        chdir $save or die "Unable to chdir back to $save: $!";
        ok( $err, 'dependency manifest install rethrows a chdir-back failure' );
    }
}

# ===========================================================================
# _install_skill_package_json merge failure; requirements/python resolution.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'node-merge-fail' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'package.json' ), '{"dependencies":{"leftpad":"^1.0.0"}}' );
    no warnings 'redefine';
    local *Developer::Dashboard::SkillManager::_copy_tree_contents = sub { die "merge boom\n" };
    like( $manager->_install_skill_package_json($skill)->{error}, qr/Failed to merge skill Node dependencies/, 'package.json install reports a merge failure' );
}
{
    # requirements.txt install failure.
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'py-fail' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'requirements.txt' ), "requests\n" );
    my $bin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin, 'python' ),  "#!/bin/sh\nexit 4\n" );
    _spew( File::Spec->catfile( $bin, 'python3' ), "#!/bin/sh\nexit 4\n" );
    chmod 0755, File::Spec->catfile( $bin, 'python' );
    chmod 0755, File::Spec->catfile( $bin, 'python3' );
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    like( $manager->_install_skill_requirements_txt($skill)->{error}, qr/Failed to install skill Python dependencies/, 'requirements.txt install reports pip failures' );
}
{
    # _python_dependency_command resolution order.
    my $only3 = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $only3, 'python3' ), "#!/bin/sh\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $only3, 'python3' );
    {
        local $ENV{PATH} = $only3;
        like( Developer::Dashboard::SkillManager::_python_dependency_command(), qr/python3$/, 'python resolution falls back to python3' );
    }
    {
        local $ENV{PATH} = tempdir( CLEANUP => 1 );
        is( Developer::Dashboard::SkillManager::_python_dependency_command(), 'python', 'python resolution falls back to the bare command name' );
    }
}

# ===========================================================================
# _package_json_dependency_specs edge cases.
# ===========================================================================
{
    is_deeply( [ $manager->_package_json_dependency_specs( File::Spec->catfile( $home, 'no-such.json' ) ) ], [], 'package.json specs returns empty for a defined but missing path' );

    my $nullver = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'null.json' );
    _spew( $nullver, '{"dependencies":{"n":null,"v":"^1.0.0"}}' );
    is_deeply( [ $manager->_package_json_dependency_specs($nullver) ], [ 'n', 'v@^1.0.0' ], 'package.json specs handles a null version as a bare name' );

  SKIP: {
        skip 'cannot deny read to root', 1 if $> == 0;
        my $locked = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'locked.json' );
        _spew( $locked, '{}' );
        chmod 0000, $locked;
        eval { $manager->_package_json_dependency_specs($locked); 1 };
        like( $@, qr/Unable to read/, 'package.json specs dies when the file cannot be opened' );
        chmod 0644, $locked;
    }
}

# ===========================================================================
# _copy_tree_contents empty argument guards and a copy failure.
# ===========================================================================
{
    my $src = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'src' );
    make_path($src);
    _spew( File::Spec->catfile( $src, 'x' ), "data\n" );
    eval { $manager->_copy_tree_contents( '', File::Spec->catdir( $home, 't' ) ); 1 };
    like( $@, qr/Missing source tree/, '_copy_tree_contents rejects an empty source' );
    eval { $manager->_copy_tree_contents( $src, '' ); 1 };
    like( $@, qr/Missing target tree/, '_copy_tree_contents rejects an empty target' );

  SKIP: {
        skip 'cannot deny write to root', 1 if $> == 0;
        my $dst = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'dst' );
        make_path($dst);
        chmod 0500, $dst;    # read-only target dir makes the file copy fail
        eval { $manager->_copy_tree_contents( $src, $dst ); 1 };
        my $err = $@;
        chmod 0755, $dst;
        like( $err, qr/Unable to copy/, '_copy_tree_contents dies when a file cannot be copied' );
    }
}

# ===========================================================================
# _install_manifest_file guards: undef manifest, and installs without an
# operations list.
# ===========================================================================
{
    is( $manager->_install_manifest_file(undef)->{skipped}, 1, '_install_manifest_file skips an undef manifest' );

    my $repo = _make_git_skill( 'mf-noops-skill', version => '1.00' );
    my $mf   = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'mf' );
    _spew( $mf, 'file://' . $repo . "\n" );
    my $ok = $manager->_install_manifest_file( $mf, skills_root => $paths->skills_root );
    ok( $ok->{success}, '_install_manifest_file installs without an operations list' ) or diag $ok->{error};
    $manager->uninstall('mf-noops-skill');
}

# ===========================================================================
# _install_result_progress_label with a hash that lacks the optional keys.
# ===========================================================================
{
    like( $manager->_install_result_progress_label( 'src', {} ), qr/^src done \(- -> -\)$/, 'progress label handles a hash missing every optional key' );
}

# ===========================================================================
# _install_skill_aptfile skip when packages exist but the host is not Debian.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'apt-nondebian' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'aptfile' ), "git\n" );
    local $ENV{DD_TEST_OS} = 'darwin';
    delete local $ENV{DD_TEST_DEBIAN_LIKE};
    ok( $manager->_install_skill_aptfile($skill)->{skipped}, 'aptfile install skips on a non-Debian host even with packages' );
}

# ===========================================================================
# _install_skill_wingetfile accumulates per-package output.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'winget-out' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'wingetfile' ), "Git.Git\n" );
    my $bin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin, 'winget' ), "#!/bin/sh\nprintf out\nprintf err 1>&2\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin, 'winget' );
    local $ENV{PATH}       = "$bin:$ENV{PATH}";
    local $ENV{DD_TEST_OS} = 'MSWin32';
    my $res = $manager->_install_skill_wingetfile($skill);
    ok( !$res->{error}, 'wingetfile install runs and accumulates output' ) or diag $res->{error};
    is( $res->{stdout}, 'out', 'wingetfile install accumulates per-package stdout' );
}

# ===========================================================================
# _install_skill_makefile with only an install target, and with make output.
# ===========================================================================
{
    my $skill = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'make-installonly' );
    make_path($skill);
    _spew( File::Spec->catfile( $skill, 'Makefile' ), "install:\n\t\@:\n" );
    ok( !$manager->_install_skill_makefile($skill)->{error}, 'makefile install runs with only an install target' );

    my $skill2 = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'make-emit' );
    make_path($skill2);
    _spew( File::Spec->catfile( $skill2, 'Makefile' ), "install:\n\t\@:\n" );
    my $bin = tempdir( CLEANUP => 1 );
    _spew( File::Spec->catfile( $bin, 'make' ), "#!/bin/sh\nprintf out\nprintf err 1>&2\nexit 0\n" );
    chmod 0755, File::Spec->catfile( $bin, 'make' );
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    ok( !$manager->_install_skill_makefile($skill2)->{error}, 'makefile install collects make stdout and stderr' );
}

# ===========================================================================
# _makefile_targets open failure (non-root only).
# ===========================================================================
{
  SKIP: {
        skip 'cannot deny read to root', 1 if $> == 0;
        my $mk = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'Makefile' );
        _spew( $mk, "install:\n\t\@:\n" );
        chmod 0000, $mk;
        eval { $manager->_makefile_targets($mk); 1 };
        like( $@, qr/Unable to read/, 'makefile target parsing dies on an unreadable makefile' );
        chmod 0644, $mk;
    }
}

# ===========================================================================
# Skill metadata / usage on a bare skill and a full-manifest skill.
# ===========================================================================
{
    my $bare = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'bare-skill' );
    make_path($bare);
    my $meta = $manager->_skill_metadata( 'bare-skill', $bare );
    is( $meta->{has_config}, JSON::XS::false(), 'metadata reports missing config as false' );
    is_deeply( $meta->{cli_commands}, [], 'metadata reports no cli commands without a cli root' );
    is( $meta->{docker_services_count}, 0, 'metadata reports no docker services without a docker root' );
    is( $meta->{pages_count}, 0, 'metadata reports no pages without a dashboards root' );
    my $usage = $manager->_skill_usage( 'bare-skill', $bare );
    is( $usage->{config}{has_config}, JSON::XS::false(), 'usage reports missing config as false' );

    my $full = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'full-skill' );
    make_path( File::Spec->catdir( $full, 'config' ) );
    _spew( File::Spec->catfile( $full, 'config', 'config.json' ), '{}' );
    for my $f (qw(apkfile dnfile brewfile cpanfile cpanfile.local aptfile Makefile dockerfile ddfile)) {
        _spew( File::Spec->catfile( $full, $f ), "x\n" );
    }
    my $full_usage = $manager->_skill_usage( 'full-skill', $full );
    is( $full_usage->{config}{has_apkfile}, JSON::XS::true(), 'usage reports apkfile presence' );
    is( $full_usage->{config}{has_cpanfile_local}, JSON::XS::true(), 'usage reports cpanfile.local presence' );
}

# ===========================================================================
# _collector_details skips a collector without a name.
# ===========================================================================
{
    my $sk = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'coll-skill' );
    make_path( File::Spec->catdir( $sk, 'config' ) );
    _spew( File::Spec->catfile( $sk, 'config', 'config.json' ), '{"collectors":[{"command":"x"},{"name":"good"}]}' );
    my $collectors = $manager->_collector_details( 'coll-skill', $sk );
    is( scalar(@$collectors), 1, 'collector details skips a collector without a name' );
}

# ===========================================================================
# _read_skill_config_file open failure returns an empty hash (non-root only).
# ===========================================================================
{
  SKIP: {
        skip 'cannot deny read to root', 1 if $> == 0;
        my $sk = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'cfg-locked' );
        make_path( File::Spec->catdir( $sk, 'config' ) );
        _spew( File::Spec->catfile( $sk, 'config', 'config.json' ), '{}' );
        chmod 0000, File::Spec->catfile( $sk, 'config', 'config.json' );
        is_deeply( $manager->_read_skill_config_file($sk), {}, 'config reader returns empty when the config cannot be opened' );
        chmod 0644, File::Spec->catfile( $sk, 'config', 'config.json' );
    }
}

# ===========================================================================
# DD-426: install must never join an unvalidated repo name onto a skills root.
#
# _extract_repo_name yields '..' for several ordinary-looking install sources,
# and File::Spec->catdir never collapses a parent-directory component, so the
# install destination used to resolve to the PARENT of the skills root - which
# install then remove_tree'd, because install doubles as reinstall. The whole
# runtime layer (config, bookmarks, installed skills) was emptied before the
# operator saw a message that read like a benign install failure.
# ===========================================================================
{
    my $traversal_home = tempdir( CLEANUP => 1 );
    my $traversal_paths = Developer::Dashboard::PathRegistry->new( home => $traversal_home );
    my $traversal_manager = Developer::Dashboard::SkillManager->new( paths => $traversal_paths );
    my $traversal_root = $traversal_paths->skills_root;
    $traversal_paths->ensure_dir($traversal_root);

    # A canary in the runtime layer that owns the skills root: the traversal
    # target. It must still be there after every refused install.
    my $layer_root = dirname($traversal_root);
    my $canary = File::Spec->catfile( $layer_root, 'canary.txt' );
    _spew( $canary, "precious\n" );

    # Every source form the hunter reproduced, plus the single-dot sibling that
    # resolves to the skills root itself.
    my @traversal_sources = (
        'owner/..',
        'file:///x/..',
        'git@github.com:owner/..',
        'https://github.com/owner/../..',
        'owner/.',
    );
    for my $source (@traversal_sources) {
        my $result = $traversal_manager->_install_to_skills_root( $source, $traversal_root );
        like(
            $result->{error},
            qr/\ARefusing to install skill outside skills root/,
            "install refuses the traversal source $source before touching the filesystem",
        );
        ok( -f $canary, "the runtime layer canary survives the traversal source $source" );
    }
    ok( -d $traversal_root, 'the skills root itself survives every refused traversal install' );

    # The same refusal reaches the public install entrypoint.
    like(
        $traversal_manager->install('owner/..')->{error},
        qr/\ARefusing to install skill outside skills root/,
        'install() refuses a traversal source through the public entrypoint',
    );
    ok( -f $canary, 'the runtime layer canary survives the public install entrypoint' );

    # _is_safe_skill_name whitelist: exactly one ordinary path segment.
    ok( Developer::Dashboard::SkillManager::_is_safe_skill_name('alpha-skill'), 'a plain repo name is a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name(undef), 'an undefined repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name(''), 'an empty repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name('..'), 'a parent-directory repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name('.'), 'a current-directory repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name('a/b'), 'a multi-segment repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name('a\\b'), 'a backslash-separated repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name('/abs'), 'an absolute repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name('C:name'), 'a drive-qualified repo name is not a safe skill name' );
    ok( !Developer::Dashboard::SkillManager::_is_safe_skill_name("na\x00me"), 'a NUL-bearing repo name is not a safe skill name' );

    # _install_path_contained: the second, independent guard. A validated name
    # still has to resolve to somewhere strictly beneath the skills root.
    ok(
        $traversal_manager->_install_path_contained( File::Spec->catdir( $traversal_root, 'fresh' ), $traversal_root ),
        'a not-yet-created destination under the skills root is contained',
    );
    my $real_child = File::Spec->catdir( $traversal_root, 'real-child' );
    make_path($real_child);
    ok(
        $traversal_manager->_install_path_contained( $real_child, $traversal_root ),
        'an existing real directory under the skills root is contained',
    );
    ok(
        !$traversal_manager->_install_path_contained(
            File::Spec->catdir( $traversal_root, 'no-such-root', 'deeper', 'fresh' ),
            File::Spec->catdir( $traversal_root, 'no-such-root', 'deeper' )
        ),
        'an unresolvable skills root is refused instead of assumed safe',
    );

  SKIP: {
        skip 'symlinks unavailable on this host', 4 if !eval { symlink q{}, q{}; 1 };

        my $outside = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'outside-tree' );
        make_path($outside);
        my $escape_link = File::Spec->catdir( $traversal_root, 'escape-link' );
        symlink( $outside, $escape_link ) or die "Unable to create escape symlink: $!";
        ok(
            !$traversal_manager->_install_path_contained( $escape_link, $traversal_root ),
            'a planted symlink that resolves outside the skills root is refused',
        );
        like(
            $traversal_manager->_install_to_skills_root( 'owner/escape-link', $traversal_root )->{error},
            qr/\ARefusing to install skill outside skills root/,
            'install refuses to replace a destination that resolves outside the skills root',
        );
        ok( -d $outside, 'the symlink target tree survives the refused install' );

        my $dangling = File::Spec->catdir( $traversal_root, 'dangling-link' );
        symlink( File::Spec->catdir( $outside, 'gone-parent', 'gone' ), $dangling )
          or die "Unable to create dangling symlink: $!";
        ok(
            !$traversal_manager->_install_path_contained( $dangling, $traversal_root ),
            'a destination whose resolved target cannot be established is refused',
        );
    }
}

done_testing;

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

# _stub($name, $body): writes an executable stub into the fake PATH bin.
sub _stub {
    my ( $name, $body ) = @_;
    my $path = File::Spec->catfile( $fake_bin, $name );
    _spew( $path, $body );
    chmod 0755, $path or die "Unable to chmod $path: $!";
    return $path;
}

# _spew($path, $content): writes a file, creating parent directories.
sub _spew {
    my ( $path, $content ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($path);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return 1;
}

# _make_git_skill($name, %opts): builds a local git skill repo for offline
# clone-based installs. Options: version (for .env), with_all (add every
# manifest type).
sub _make_git_skill {
    my ( $name, %opts ) = @_;
    my $repo = File::Spec->catdir( $repos, $name );
    make_path($repo);
    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";

    _run_or_die(qw(git init --quiet));
    _run_or_die(qw(git config user.email test@example.com));
    _run_or_die(qw(git config user.name Test));

    make_path('cli');
    make_path( File::Spec->catdir( 'config', 'docker', 'db' ) );
    make_path('dashboards');
    _spew( File::Spec->catfile( 'cli', 'run' ), "#!/bin/sh\n:\n" );
    chmod 0755, File::Spec->catfile( 'cli', 'run' );
    _spew( File::Spec->catfile( 'config', 'config.json' ), qq|{"skill_name":"$name"}\n| );
    _spew( File::Spec->catfile( 'config', 'docker', 'db', 'compose.yml' ), "services: {}\n" );
    _spew( File::Spec->catfile( 'dashboards', 'welcome' ), "TITLE: Hi\n" );
    _spew( '.env', "VERSION=$opts{version}\n" ) if defined $opts{version};

    if ( $opts{with_all} ) {
        _spew( 'cpanfile',         "requires 'JSON::XS';\n" );
        _spew( 'cpanfile.local',   "requires 'JSON::XS';\n" );
        _spew( 'aptfile',          "git\n" );
        _spew( 'package.json',     '{"dependencies":{"leftpad":"^1.0.0"}}' );
        _spew( 'requirements.txt', "requests\n" );
        _spew( 'Makefile',         "install:\n\t\@:\ntest:\n\t\@:\nclean:\n\t\@:\n" );
        _spew( 'dockerfile',       "FROM scratch\n" );
        _spew( 'ddfile',           "# no dependent skills\n" );
        _spew( 'ddfile.local',     "# no dependent skills\n" );
    }

    _run_or_die(qw(git add -A));
    _run_or_die( 'git', 'commit', '--quiet', '-m', "Initial $name" );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return $repo;
}

# _bump_git_skill_version($repo, $version): rewrites .env and commits.
sub _bump_git_skill_version {
    my ( $repo, $version ) = @_;
    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    _spew( '.env', "VERSION=$version\n" );
    _run_or_die(qw(git add -A));
    _run_or_die( 'git', 'commit', '--quiet', '-m', "Bump to $version" );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return 1;
}

# _run_or_die(@command): runs a command, dying on failure.
sub _run_or_die {
    my (@command) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system(@command);
    };
    die "Command failed: @command\n$stderr" if $exit != 0;
    return $stdout;
}

__END__

=pod

=head1 NAME

t/102-skillmanager-coverage.t - branch and condition coverage closure for the skill manager

=head1 PURPOSE

This test drives C<Developer::Dashboard::SkillManager> across every install,
update, uninstall, listing, metadata, dependency-install, manifest, and
registration path so the module reaches full branch and condition coverage. It
exercises the guard clauses, error returns, platform-specific dependency
installers, streaming command runner, and ddfile/gitignore registration helpers
that the broader skill-system regression does not individually reach.

=head1 WHY IT EXISTS

The skill manager owns a large, side-effect-heavy surface: cloning or copying
skill checkouts, preparing the isolated layout, installing system and language
dependencies per host, streaming progress, and keeping the home ddfile and
gitignore registries in sync. Many of its defensive branches (missing arguments,
unreadable files, package-manager failures, alternate operating systems) only
run under conditions the happy-path regression never creates. This file exists
to hold those branches down so a refactor cannot silently drop an error path or
a platform case.

=head1 WHEN TO USE

Use this file when changing skill installation, dependency bootstrap ordering,
manifest-driven installs, skill metadata, or the root ddfile and gitignore
registration logic, and whenever the coverage gate flags a regression in the
skill manager's branch or condition totals.

=head1 HOW TO USE

Run C<perl -Ilib t/102-skillmanager-coverage.t> or C<prove -lv
t/102-skillmanager-coverage.t> while iterating. The test builds a hermetic HOME,
prepends a stub PATH so no real package managers run, and constructs the manager
against a temporary L<Developer::Dashboard::PathRegistry>. Keep it green under
C<prove -lr t> and under the Devel::Cover gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the all-metric
Devel::Cover coverage gate use this file to keep the skill manager fully
exercised.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/102-skillmanager-coverage.t

Run the coverage-closure test directly from a source checkout.

Example 2:

  prove -lv t/102-skillmanager-coverage.t

Run it through the test harness with verbose output while iterating.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate after changing it.

=cut
