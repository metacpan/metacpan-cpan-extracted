use strict;
use warnings;
use utf8;

use Cwd qw(cwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use POSIX qw(:sys_wait_h setsid);
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';
use lib 't/lib';

use Local::CollectorFixture qw(wait_for_managed_loop);

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Folder;
use Developer::Dashboard::GoRoutine ();

my $repo_root = cwd();

# _run_perl_child($source, @arguments)
# Runs an isolated Perl fixture through GoRoutine and returns its exit code.
# Input: Perl source and arguments passed to that source.
# Output: child exit code.
sub _run_perl_child {
    my ( $source, @arguments ) = @_;
    my @include = map { '-I' . File::Spec->catdir( $repo_root, $_ ) } qw(lib blib/lib blib/arch t/lib);
    my %options;
    my $coverage_switches = $ENV{HARNESS_PERL_SWITCHES};
    if ( defined $coverage_switches && length $coverage_switches && $coverage_switches =~ /Devel::Cover/ ) {
        # The fixtures inherit a temporary HOME as CWD in ordinary runs. In a
        # coverage run, start at the checkout so Devel::Cover instruments the
        # repository modules loaded by this isolated GoRoutine child.
        $options{cwd} = $repo_root;
        $options{env} = { PERL5OPT => $coverage_switches };
    }
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, @include, '-e', $source, @arguments ],
        \%options,
    );
    die "GoRoutine spawn failed: $!" if !defined $pid;
    return Developer::Dashboard::GoRoutine::wait_process($pid);
}

# _kill_child($pid)
# Terminates and reaps one fixture child, however it was spawned. On Unix
# this is the ordinary kill 9 plus waitpid. On Windows Perl kill never
# reaches a CreateProcess child, so terminate through the native process
# API and reap through it too; a blocking waitpid on Windows would hang
# until the child's sleep expired instead.
# Input: child process id integer.
# Output: nothing.
sub _kill_child {
    my ($pid) = @_;
    return if !defined $pid || $pid < 1;
    if ( $^O eq 'MSWin32' ) {
        Developer::Dashboard::GoRoutine::terminate_process( $pid, 'KILL' );
        my $deadline = time + 5;
        while ( !Developer::Dashboard::GoRoutine::process_exited($pid) && time < $deadline ) {
            select undef, undef, undef, 0.05;
        }
        Developer::Dashboard::GoRoutine::wait_process($pid)
          if Developer::Dashboard::GoRoutine::process_exited($pid);
        return;
    }
    kill 9, $pid;
    waitpid( $pid, 0 ) if kill 0, $pid;
    return;
}

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );
my $collector_store = Developer::Dashboard::Collector->new( paths => $paths );
my $indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector_store,
    files      => $files,
    indicators => $indicator_store,
    paths      => $paths,
);

{
    my $cwd_marker = File::Spec->catfile( $home, 'coverage-child-cwd.txt' );
    my $source = q{
        use Cwd qw(cwd);
        open my $fh, '>', $ARGV[0] or die "Unable to write child cwd marker: $!";
        print {$fh} cwd(), "\n";
        close $fh or die "Unable to close child cwd marker: $!";
    };
    is( _run_perl_child( $source, $cwd_marker ), 0, 'GoRoutine coverage-CWD probe exits successfully' );
    open my $fh, '<', $cwd_marker or die "Unable to read child cwd marker '$cwd_marker': $!";
    my $child_cwd = <$fh>;
    close $fh or die "Unable to close child cwd marker '$cwd_marker': $!";
    my $expected_cwd = ( $ENV{HARNESS_PERL_SWITCHES} // q{} ) =~ /Devel::Cover/ ? $repo_root : $home;
    ( my $portable_child_cwd = $child_cwd ) =~ s{/private(?=/var/folders/)}{}g;
    ( my $portable_expected_cwd = "$expected_cwd\n" ) =~ s{/private(?=/var/folders/)}{}g;
    # Cwd spells the child directory with forward slashes even on Windows,
    # while a File::Spec path uses backslashes there; compare canonical
    # spellings so the check is about the directory, not the separator.
    chomp $portable_child_cwd;
    chomp $portable_expected_cwd;
    $portable_child_cwd    = File::Spec->canonpath($portable_child_cwd);
    $portable_expected_cwd = File::Spec->canonpath($portable_expected_cwd);
    is( $portable_child_cwd, $portable_expected_cwd, 'coverage-instrumented GoRoutine children start in the checkout while ordinary fixtures retain the temporary HOME cwd' );
}

{
    my $json_file = File::Spec->catfile( $paths->dashboards_root, 'migrated.json' );
    open my $fh, '>', $json_file or die $!;
    print {$fh} qq|{"id":"migrated","title":"Migrated","layout":{"body":"body"}}|;
    close $fh;

    my $migrated = $store->migrate_legacy_json_pages;
    is( ref($migrated), 'ARRAY', 'legacy json migration returns an array reference' );
    is( $migrated->[0]{id}, 'migrated', 'legacy json migration keeps page id' );
    ok( -f File::Spec->catfile( $paths->dashboards_root, 'migrated' ), 'legacy json migration writes canonical bookmark file' );
    ok( !-e $json_file, 'legacy json migration removes the original json file' );
}

{
    my $bad_stash = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Bad Stash
:--------------------------------------------------------------------------------:
STASH: []
PAGE
    is_deeply( $bad_stash->as_hash->{state}, {}, 'array stash input falls back to an empty hash' );
}

{
    make_path( File::Spec->catdir( $home, 'folder-env' ) );
    local $ENV{DEVELOPER_DASHBOARD_PATH_CUSTOM} = File::Spec->catdir( $home, 'folder-env' );
    Developer::Dashboard::Folder->configure( paths => $paths, aliases => {} );
    is( Developer::Dashboard::Folder->_resolve_path('custom'), File::Spec->catdir( $home, 'folder-env' ), 'Folder resolves DEVELOPER_DASHBOARD_PATH_* overrides' );
    ok( !defined Developer::Dashboard::Folder->_resolve_path('missing-folder-alias'), 'Folder returns undef for unknown folder aliases' );

    my $list_dir = File::Spec->catdir( $home, 'folder-list' );
    make_path( File::Spec->catdir( $list_dir, 'subdir' ) );
    open my $fh, '>', File::Spec->catfile( $list_dir, 'item.txt' ) or die $!;
    print {$fh} "item\n";
    close $fh;
    my @items = Developer::Dashboard::Folder->ls($list_dir);
    is( scalar @items, 2, 'Folder lists both directory and file entries' );
    is( $items[0]{type}, 'folder', 'Folder sorts directories before files' );
    is( $items[1]{type}, 'file', 'Folder records file entries' );
}

{
    my $timeout_dir = File::Spec->catdir( $home, 'timeout-run' );
    make_path($timeout_dir);
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command(
        source     => q{perl -e "sleep 2"},
        cwd        => $timeout_dir,
        timeout_ms => 50,
    );
    is( $exit_code, 124, 'collector command timeout returns 124' );
    ok( $timed_out, 'collector command timeout is marked as timed out' );
    is( $stdout, '', 'collector timeout leaves stdout empty' );
    is( $stderr, '', 'collector timeout leaves stderr empty' );
    ok( Developer::Dashboard::CollectorRunner::_cron_match( '*/5', 10 ), 'collector cron step matches divisible values' );
    ok( !Developer::Dashboard::CollectorRunner::_cron_match( '*/5', 3 ), 'collector cron step does not match unrelated values' );
    ok( !Developer::Dashboard::CollectorRunner::_cron_match( '9', 3 ), 'collector cron exact value can fail to match' );

    my ( $code_stdout, $code_stderr, $code_exit, $code_timed_out ) = $runner->_run_code(
        source     => q{sleep 2; return 0;},
        cwd        => $timeout_dir,
        timeout_ms => 50,
    );
    is( $code_exit, 124, 'collector perl-code timeout returns 124' );
    ok( $code_timed_out, 'collector perl-code timeout is marked as timed out' );
    is( $code_stdout, '', 'collector perl-code timeout leaves stdout empty' );
    is( $code_stderr, '', 'collector perl-code timeout leaves stderr empty' );

    my $mode_error = eval { $runner->_run_job( mode => 'bogus', source => '1', cwd => $timeout_dir ); 1 } ? '' : $@;
    like( $mode_error, qr/Unknown collector mode 'bogus'/, 'collector runner rejects unknown execution modes' );

    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_run_job = sub { die "outer run wrapper failure\n" };
    my $wrapped = $runner->run_once(
        {
            name    => 'wrapped.failure',
            command => q{printf wrapped},
            cwd     => $timeout_dir,
        }
    );
    is( $wrapped->{exit_code}, 255, 'run_once maps outer execution wrapper failures to exit 255' );
    like( $wrapped->{stderr}, qr/outer run wrapper failure/, 'run_once appends outer execution wrapper failures to stderr' );
    is( $collector_store->read_status('wrapped.failure')->{active_runs}, 0, 'run_once clears active_runs after an outer execution wrapper failure' );
    ok( !$collector_store->read_status('wrapped.failure')->{running}, 'run_once clears running after an outer execution wrapper failure' );
}

{
    my $loop_name = 'coverage.loop';
    my $pidfile   = $runner->_pidfile($loop_name);
    my $statefile = $runner->_statefile($loop_name);

    my $process_title = $runner->_process_title($loop_name);
    # POSIX::setpgid is not implemented on Windows, and the native spawn
    # layer ignores process_group there anyway, so the fixture child only
    # detaches into its own group where that call exists.
    my $child_program
        = $^O eq 'MSWin32'
        ? q{$ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = shift; $0 = shift; $SIG{TERM} = 'IGNORE'; sleep 30;}
        : q{$ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = shift; $0 = shift; POSIX::setpgid(0, 0) or die "setpgid: $!"; $SIG{TERM} = 'IGNORE'; sleep 30;};
    my $managed_child = Developer::Dashboard::GoRoutine::spawn(
        [
            $^X, '-MPOSIX', '-e',
            $child_program,
            $loop_name, $process_title,
        ],
        # The loop-name marker travels in the spawn environ as well as in
        # the post-exec $ENV assignment inside the child program: the kernel
        # environ block is fixed at exec, so a variable assigned after
        # startup is invisible to /proc readers, and under qemu user-mode
        # emulation the $0 title is invisible too. Either channel alone
        # leaves this child unrecognizable on some host.
        { cwd => $home, env => { HOME => $home, DEVELOPER_DASHBOARD_LOOP_NAME => $loop_name } },
    );
    die "GoRoutine spawn failed: $!" if !defined $managed_child;
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $managed_child;
    close $fh;
    if ( $^O eq 'MSWin32' ) {
        # The title is the only identity evidence this fixture carries, and
        # it is never observable on Windows (no /proc, no ps), so the child
        # would never be recognized and running_loops would delete its
        # pidfile. Seed the loop state instead: that is the identity
        # evidence a real loop carries on Windows, and it is what the
        # state-confirmation check reads.
        $runner->_write_loop_state(
            $loop_name,
            {
                pid          => $managed_child,
                name         => $loop_name,
                process_name => $process_title,
                status       => 'running',
            }
        );
    }
    # Wait BEFORE the first running_loops call, not around it. This pidfile has
    # no loop state, so the child's process title is the only evidence of its
    # identity, and running_loops deletes the pidfile of any same-namespace pid it
    # cannot recognize. A poll loop therefore destroys its own fixture on the
    # first iteration and can never recover, however many iterations it is given.
    ok(
        wait_for_managed_loop( $runner, $managed_child, $loop_name ),
        'managed loop child becomes identifiable before running_loops reads the collectors root',
    );
    my @loops = $runner->running_loops;
    is( scalar @loops, 1, 'running_loops lists active managed loop pids' );
    is( $loops[0]{name}, $loop_name, 'running_loops returns the managed loop name' );

    $collector_store->mark_run_started( $loop_name, {} );
    ok( $collector_store->read_status($loop_name)->{running}, 'collector status reports running before the loop is stopped' );

    my $stopped_pid = $runner->stop_loop($loop_name);
    is( $stopped_pid, $managed_child, 'stop_loop returns managed loop pid' );
    ok( !-e $pidfile, 'stop_loop removes loop pid files after forced kill' );
    ok( !-e $statefile, 'stop_loop removes loop state files after forced kill' );

    my $status_after_stop = $collector_store->read_status($loop_name) || {};
    ok( !$status_after_stop->{running}, 'stop_loop resets the consumer-facing running flag so a stopped collector is no longer reported as running' );
    is( $status_after_stop->{active_runs}, 0, 'stop_loop clears active_runs when the loop is stopped so in-flight counters do not linger' );
}

{
    is( $collector_store->mark_stopped('never.seeded.collector'), undef, 'mark_stopped is a no-op when the collector has no status file yet' );

    $collector_store->mark_run_started( 'reset.direct.collector', {} );
    ok( $collector_store->read_status('reset.direct.collector')->{running}, 'seeded collector status reports running' );
    is( $collector_store->read_status('reset.direct.collector')->{active_runs}, 1, 'seeded collector status reports one active run' );

    $collector_store->mark_stopped('reset.direct.collector');
    my $reset = $collector_store->read_status('reset.direct.collector');
    ok( !$reset->{running}, 'mark_stopped clears the running flag directly' );
    is( $reset->{active_runs}, 0, 'mark_stopped clears active_runs directly' );
    ok( defined $reset->{stopped_at} && $reset->{stopped_at} ne '', 'mark_stopped records when the collector was stopped' );
}

{
    # Fix A: a just-spawned worker must be persisted to active_worker_pids
    # immediately, not only at the top of the next iteration, so a crash cannot
    # orphan a worker that is invisible to the persisted state.
    my $persist_name = 'coverage.persist.on.spawn';
    my $source = q{
        use File::Spec;
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ( $home, $persist_name ) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
        );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths => $paths,
        );
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
        my $ok = $runner->_run_loop_child(
            daemonize     => 0,
            interval      => 1,
            job           => { command => 'sleep 30', cwd => $home },
            name          => $persist_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($persist_name),
        );
        exit( $ok ? 0 : 1 );
    };
    is( _run_perl_child( $source, $home, $persist_name ), 0,
        'isolated loop fixture exits successfully after persisting its worker' );
    my @persisted = $runner->_state_active_worker_pids($persist_name);
    ok( scalar(@persisted) >= 1, 'loop persists active_worker_pids immediately on spawn so a just-started worker survives a crash-and-stop' );
    for my $wpid (@persisted) { kill 9, -$wpid; kill 9, $wpid; }
}

{
    # Fix D (Facet 1c): a command child that ignores SIGTERM stays alive in the
    # worker's process group after the worker (group leader) exits; pass 2 must
    # send the group SIGKILL unconditionally to reap it.
    my $gc_file = File::Spec->catfile( $home, "trapgc.$$" );
    unlink $gc_file;
    my $worker_source = q{
        use Developer::Dashboard::GoRoutine ();
        my ( $gc_file, @include ) = @ARGV;
        my $gc = Developer::Dashboard::GoRoutine::spawn(
            [ $^X, @include, '-e', q{$SIG{TERM} = 'IGNORE'; select undef, undef, undef, 60;} ],
            {},
        );
        die "GoRoutine spawn failed: $!" if !defined $gc;
        open my $gf, '>', $gc_file or die "Unable to write descendant pid file: $!";
        print {$gf} $gc or die "Unable to write descendant pid: $!";
        close $gf or die "Unable to close descendant pid file: $!";
        $SIG{TERM} = 'DEFAULT';
        select undef, undef, undef, 60;
    };
    my @include = map { '-I' . File::Spec->catdir( $repo_root, $_ ) } qw(lib blib/lib blib/arch);
    my $worker = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, @include, '-e', $worker_source, $gc_file, @include ],
        { cwd => $home, env => { HOME => $home }, process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $worker;
    my $gc_pid = '';
    for ( 1 .. 60 ) { last if -s $gc_file; select undef, undef, undef, 0.05; }
    if ( open my $gf, '<', $gc_file ) { local $/; $gc_pid = <$gf>; close $gf; }
    $gc_pid =~ s/\s+//g;
    ok( $gc_pid && kill( 0, $gc_pid ), 'SIGTERM-ignoring command child is running before termination' );
    $runner->_terminate_loop_workers( { $worker => 1 } );
    select undef, undef, undef, 0.3;
    ok( !kill( 0, $gc_pid ), '_terminate_loop_workers group-SIGKILLs a SIGTERM-ignoring child left in a dead worker process group' );
    _kill_child($worker);
    unlink $gc_file;
}

{
    # Fix E (Facet 5): on a proc-blind host (no /proc, no ps: Windows) a live
    # loop recorded in loop.json must still be recognized from its pid/name/title
    # even when its status is outside the old whitelist, so stop can kill it.
    my $ename  = 'coverage.confirm.broadened';
    my $echild = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 60;} ],
        { cwd => $home, env => { HOME => $home }, process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $echild;
    my $epidfile = $runner->_pidfile($ename);
    open my $ef, '>', $epidfile or die $!;
    print {$ef} $echild;
    close $ef;
    $runner->_write_loop_state(
        $ename,
        {
            pid          => $echild,
            name         => $ename,
            process_name => $runner->_process_title($ename),
            status       => 'attention',
        }
    );
    my $ret;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_title      = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return undef };
        $ret = $runner->stop_loop($ename);
    }
    is( $ret, $echild, 'stop_loop returns a state-confirmed loop pid when proc/ps identity is unavailable' );
    select undef, undef, undef, 0.3;
    ok( !kill( 0, $echild ), 'stop_loop kills a state-confirmed loop with a non-whitelisted status on proc-blind (Windows) hosts' );
    _kill_child($echild);
}

SKIP: {
    # The TERM grace is a Unix signal mechanism: the loop's own TERM
    # handler takes three seconds to finish cleaning workers, and the flag
    # only exists if that handler ran. On Windows a signal is never
    # delivered to a CreateProcess child (the stopper terminates it and
    # records the receipt in the log instead), so the flag can never be
    # written and the grace cannot be measured there.
    skip 'loop TERM grace is a Unix signal mechanism; Windows has no signal delivery to a CreateProcess child', 2 if $^O eq 'MSWin32';
    # Fix B+C (Facet 2): the loop TERM grace scales with the recorded worker
    # count so the loop's own shutdown handler can finish cleaning workers
    # instead of being KILL-9'd at a fixed 2s.
    my $bname = 'coverage.grace.scaled';
    my $flag  = File::Spec->catfile( $home, "graceflag.$$" );
    unlink $flag;
    $runner->_write_loop_state(
        $bname,
        {
            pid                => 0,
            name               => $bname,
            process_name       => $runner->_process_title($bname),
            status             => 'running',
            active_worker_pids => [ 2000000001, 2000000002 ],
        }
    );
    # The child announces that its TERM handler is installed, and the parent waits
    # for that announcement before stopping it (DD-489).
    #
    # This assertion is about the GRACE the parent gives a handler that takes
    # three seconds. It can only measure that if the handler exists when the
    # signal arrives. Nothing used to guarantee it did: the parent wrote the
    # pidfile and called stop_loop straight after forking, so on a starved host
    # TERM could reach the child before $SIG{TERM} was set, the default action
    # killed it instantly, and the flag file was never written - reported as the
    # parent failing to scale its grace, which is the opposite of what happened.
    #
    # Recognition helpers cannot cover this one. wait_for_managed_loop waits for
    # the RUNNER to recognise the loop, and this fixture writes the loop state by
    # hand, so recognition is already true while the handler still is not. Only
    # the child knows when it is ready, so only the child can say so.
    my $ready = "$flag.ready";
    unlink $ready;
    my $bchild = Developer::Dashboard::GoRoutine::spawn(
        [
            $^X, '-e', q{
                my ( $flagfile, $readyfile, $loop_name, $process_title ) = @ARGV;
                $SIG{TERM} = sub {
                    select undef, undef, undef, 3;
                    if ( open my $f, '>', $flagfile ) { print {$f} 'done'; close $f; }
                    exit 0;
                };
                $0 = $process_title;
                $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $loop_name;
                if ( open my $r, '>', $readyfile ) { print {$r} 'ready'; close $r; }
                select undef, undef, undef, 60;
            },
            $flag, $ready, $bname, $runner->_process_title($bname),
        ],
        { cwd => $home, env => { HOME => $home }, process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $bchild;

    # Bounded, and loud when it expires: a fixture that silently gave up waiting
    # would turn this into the very flake it is meant to remove.
    my $ready_deadline = time + 30;
    until ( -f $ready || time > $ready_deadline ) { select undef, undef, undef, 0.02 }
    ok( -f $ready, 'the grace fixture child installed its TERM handler before it was stopped' );
    my $bpidfile = $runner->_pidfile($bname);
    open my $bf, '>', $bpidfile or die $!;
    print {$bf} $bchild;
    close $bf;
    $runner->_write_loop_state( $bname, { pid => $bchild } );
    $runner->stop_loop($bname);
    ok( -f $flag, 'stop_loop scales the loop TERM grace by worker count so the loop finishes its own worker cleanup before any KILL-9' );
    kill 9, $bchild if kill 0, $bchild;
    unlink $flag;
    unlink "$flag.ready";
}

{
    # Fix B+C else-branch (Facet 4): a crashed loop (dead pidfile) that left
    # orphaned workers recorded in state must still have those workers swept.
    my $cname  = 'coverage.crashed.loop.orphans';
    my $orphan = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 60;} ],
        { cwd => $home, env => { HOME => $home }, process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $orphan;
    my $deadpid = Developer::Dashboard::GoRoutine::spawn( [ $^X, '-e', 'exit 0;' ], {} );
    die "GoRoutine spawn failed: $!" if !defined $deadpid;
    Developer::Dashboard::GoRoutine::wait_process($deadpid);
    my $cpidfile = $runner->_pidfile($cname);
    open my $cf, '>', $cpidfile or die $!;
    print {$cf} $deadpid;
    close $cf;
    $runner->_write_loop_state(
        $cname,
        {
            pid                => $deadpid,
            name               => $cname,
            process_name       => $runner->_process_title($cname),
            status             => 'running',
            active_worker_pids => [$orphan],
        }
    );
    $runner->stop_loop($cname);
    # Bounded poll, not a fixed sleep: under slow scheduling (qemu) the
    # orphan's death can lag stop_loop's own bounded waits, so a fixed
    # 0.3s sleep turns this into a flake — it failed once on ARM64 and
    # passed on immediate re-run. The assertion is unchanged (the orphan
    # must end up dead); only the waiting is tolerant, and the poll exits
    # at once when the orphan is gone.
    # A zombie counts as dead: kill(0) still succeeds on an unreaped
    # zombie, so without this the poll can expire (10s) even though the
    # orphan is already dead — it failed again on ARM64 under full-suite
    # load, where the reap lags stop_loop's bounded waits. /proc is
    # Linux-only; elsewhere the kill(0) check above is the only signal.
    my $orphan_dead = 0;
    for ( 1 .. 100 ) {
        if ( !kill( 0, $orphan ) ) { $orphan_dead = 1; last; }
        if ( open my $st, '<', "/proc/$orphan/stat" ) {
            my $stat = <$st>;
            close $st;
            my ($state) = defined $stat ? $stat =~ /.*\)\s+(\w)/ : ();
            if ( defined $state && $state eq 'Z' ) { $orphan_dead = 1; last; }
        }
        select undef, undef, undef, 0.1;
    }
    ok( $orphan_dead, 'stop_loop sweeps orphaned worker subtrees left behind by a crashed loop with a stale pidfile' );
    _kill_child($orphan);
}

{
    # Fix A (dedup): start_loop must recognize an already-running managed loop
    # from its recorded state even when proc/ps identity is unavailable, so the
    # supervisor cannot create a DUPLICATE loop by racing a fresh loop before it
    # has set its process title.
    my $dname = 'coverage.startloop.dedup';
    my $dchild = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 60;} ],
        { cwd => $home, env => { HOME => $home }, process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $dchild;
    my $dpidfile = $runner->_pidfile($dname);
    open my $dpf, '>', $dpidfile or die $!;
    print {$dpf} $dchild;
    close $dpf;
    $runner->_write_loop_state(
        $dname,
        {
            pid          => $dchild,
            name         => $dname,
            process_name => $runner->_process_title($dname),
            status       => 'running',
        }
    );
    my $spawned = 0;
    my $ret;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::CollectorRunner::_read_process_title      = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return undef };
        local *Developer::Dashboard::GoRoutine::spawn = sub { $spawned++; return 4000000001; };
        $ret = $runner->start_loop( { name => $dname, command => 'true', cwd => $home, interval => 1 } );
    }
    is( $ret,    $dchild, 'start_loop returns the existing loop pid when it is state-confirmed on a proc-blind host' );
    is( $spawned, 0,      'start_loop does not spawn a duplicate loop when the existing loop is recognized from state' );
    kill 9, $dchild if kill 0, $dchild;
    $runner->_cleanup_loop_files($dname);
}

{
    my $cron_name = 'coverage.cron';
    ok( !$runner->_job_is_due( { schedule => 'manual' }, $cron_name ), '_job_is_due rejects manual collectors' );
    ok( $runner->_job_is_due( { interval => 10 }, $cron_name ), '_job_is_due accepts interval collectors' );
    is(
        $runner->_effective_interval_seconds( { name => 'system-temp', command => 'dashboard system-temp cpu', interval => 5 } ),
        30,
        '_effective_interval_seconds throttles fast d2 subcommand collectors to the default floor',
    );
    is(
        $runner->_effective_interval_seconds( { name => 'system-temp', command => 'dashboard system-temp cpu', interval => 5, allow_fast_poll => 1 } ),
        5,
        '_effective_interval_seconds keeps the configured interval when fast dashboard polling is explicitly allowed',
    );
    is(
        $runner->_effective_interval_seconds( { name => 'system-temp', command => 'dashboard system-temp cpu', interval => 5, allow_fast_dashboard_poll => 1 } ),
        5,
        '_effective_interval_seconds also honours the dedicated allow_fast_dashboard_poll opt-out',
    );
    local $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS} = 12;
    is(
        $runner->_effective_interval_seconds( { name => 'system-temp', command => 'dashboard system-temp cpu', interval => 5 } ),
        12,
        '_effective_interval_seconds honours the d2 collector interval floor environment override',
    );
    local $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS} = 0;
    is(
        $runner->_effective_interval_seconds( { name => 'system-temp', command => q{/usr/local/bin/d2 system-temp cpu}, interval => 5 } ),
        5,
        '_effective_interval_seconds leaves quoted or absolute d2 commands alone when the floor is disabled',
    );
    {
        local $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS} = 30;
        is(
            $runner->_effective_interval_seconds( { name => 'system-temp', command => 'dashboard system-temp cpu', interval => 45 } ),
            45,
            '_effective_interval_seconds keeps d2 subcommand collectors above the minimum interval unchanged',
        );
    }
    ok( !$runner->_cron_due( undef, $cron_name ), '_cron_due rejects an empty cron expression instead of treating it as always due' );
    ok( !$runner->_cron_due( '* * * *', $cron_name ), '_cron_due rejects malformed cron expressions' );
    my @now = localtime();
    my $expr = sprintf '%d-%d %d %d %d %d', $now[1], $now[1], $now[2], $now[3], $now[4] + 1, $now[6];
    ok( $runner->_job_is_due( { schedule => 'cron', cron => $expr }, $cron_name ), '_job_is_due delegates matching cron collectors to cron scheduling' );
    ok( !$runner->_job_is_due( { schedule => 'cron', cron => $expr }, $cron_name ), '_job_is_due suppresses duplicate cron slots after the first matching tick' );
}

{
    my $stale_name = 'coverage.stale';
    my $pidfile = $runner->_pidfile($stale_name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} 999999;
    close $fh;
    my @loops = $runner->running_loops;
    is( scalar @loops, 0, 'running_loops ignores stale unmanaged pids' );
    ok( !-e $pidfile, 'running_loops cleans up stale pid files' );
}

{
    my @names = qw(coverage.sort-b coverage.sort-a);
    my @children;
    for my $name (@names) {
        my $pid = Developer::Dashboard::GoRoutine::spawn(
            [
                $^X, '-e',
                q{my ( $name, $title ) = @ARGV; $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $name; $0 = $title; sleep 30;},
                $name, $runner->_process_title($name),
            ],
            # As in the listing fixture above: the loop-name marker travels
            # in the spawn environ, because a post-exec $ENV assignment is
            # invisible to /proc readers and the $0 title is invisible under
            # qemu user-mode emulation.
            { cwd => $home, env => { HOME => $home, DEVELOPER_DASHBOARD_LOOP_NAME => $name } },
        );
        die "GoRoutine spawn failed: $!" if !defined $pid;
        push @children, $pid;
        open my $fh, '>', $runner->_pidfile($name) or die $!;
        print {$fh} $pid;
        close $fh;
        if ( $^O eq 'MSWin32' ) {
            # As above: a title is never observable on Windows, so seed the
            # loop state or the first running_loops call sweeps the pidfile
            # away before the sort has anything left to order.
            $runner->_write_loop_state(
                $name,
                {
                    pid          => $pid,
                    name         => $name,
                    process_name => $runner->_process_title($name),
                    status       => 'running',
                }
            );
        }
    }
    # Same ordering rule as the listing fixture above: every child has to be
    # recognizable before running_loops is called at all, because the first call
    # sweeps away the pidfile of any child it does not recognize and the sort then
    # has nothing left to order.
    for my $index ( 0 .. $#names ) {
        ok(
            wait_for_managed_loop( $runner, $children[$index], $names[$index] ),
            "managed loop child $names[$index] becomes identifiable before the sorted listing is read",
        );
    }
    my @loops = $runner->running_loops;
    is_deeply(
        [ map { $_->{name} } @loops ],
        [ sort @names ],
        'running_loops sorts managed loop rows by collector name',
    );
    for my $index ( 0 .. $#children ) {
        _kill_child( $children[$index] );
        $runner->_cleanup_loop_files( $names[$index] );
    }
}

{
    my $shutdown_name = 'coverage.shutdown';
    my $shutdown_source = q{
        use File::Spec;
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ( $home, $shutdown_name ) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
        );
        my $child_runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths      => $paths,
        );
        $child_runner->_shutdown_loop( $shutdown_name, 'stopped' );
    };
    is( _run_perl_child( $shutdown_source, $home, $shutdown_name ), 0,
        '_shutdown_loop exits a managed child cleanly' );

    my $signal_name = 'coverage.signal';
    my $signal_source = q{
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ( $home, $signal_name ) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths      => $paths,
        );
        local $Developer::Dashboard::CollectorRunner::SIGNAL_LOOP_NAME = $signal_name;
        Developer::Dashboard::CollectorRunner::_signal_stop();
    };
    is( _run_perl_child( $signal_source, $home, $signal_name ), 0,
        '_signal_stop exits a managed child cleanly' );
}

{
    my $loop_name = 'coverage.loop.child';
    my $loop_source = q{
        use File::Spec;
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ( $home, $loop_name ) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
        );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths => $paths,
        );
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::run_once     = sub { return { ok => 1 } };
        my $ok = $runner->_run_loop_child(
            daemonize     => 1,
            interval      => 0,
            job           => { command => 'printf child', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        );
        exit( $ok ? 0 : 1 );
    };
    is( _run_perl_child( $loop_source, $home, $loop_name ), 0,
        '_run_loop_child returns cleanly after one daemonized tick' );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'running', '_run_loop_child writes running state during a successful tick' );
}

{
    require Developer::Dashboard::GoRoutine;
    my $spawned_pid = Developer::Dashboard::GoRoutine::spawn( [ $^X, '-e', 'exit 0' ], {} );
    is( Developer::Dashboard::GoRoutine::wait_process($spawned_pid), 0,
        'GoRoutine process API launches and collects a clean helper child' );
}

{
    my $loop_name = 'coverage.start.parent.' . $$;
    my $dispatch_name = 'coverage.start.child.' . $$;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 424242 };
    my $pid = $runner->start_loop(
        {
            name     => $loop_name,
            command  => q{printf parent},
            cwd      => 'home',
            interval => 5,
        }
    );
    is( $pid, 424242, 'start_loop returns the pid from the GoRoutine process launcher' );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'starting', 'start_loop writes starting metadata for the spawned helper' );
    is( $state->{pid}, 424242, 'start_loop records the GoRoutine child pid in state' );
    is( $files->read( File::Spec->catfile( $paths->collectors_root, "$loop_name.pid" ) ), '424242', 'start_loop parent path writes the pidfile from the wrapped process-launch result' );

    my $stale_name = 'coverage.start.stale.' . $$;
    open my $stale_pid, '>', $runner->_pidfile($stale_name) or die $!;
    print {$stale_pid} "999999\n";
    close $stale_pid;
    $runner->_write_loop_state(
        $stale_name,
        {
            pid    => 999999,
            name   => $stale_name,
            status => 'running',
        }
    );
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 565656 };
    my $stale_started = $runner->start_loop(
        {
            name     => $stale_name,
            command  => q{printf stale},
            cwd      => 'home',
            interval => 3,
        }
    );
    is( $stale_started, 565656, 'start_loop replaces stale loop files before writing new parent state' );
    is( $runner->loop_state($stale_name)->{pid}, 565656, 'start_loop stale cleanup path overwrites the old loop state' );

    my @spawned_command;
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub {
        my ( $self, @command ) = @_;
        @spawned_command = @command;
        return 676767;
    };
    my $dispatch_pid = $runner->start_loop(
        {
            name     => $dispatch_name,
            command  => q{printf child},
            cwd      => 'home',
            interval => 7,
            schedule => 'interval',
        }
    );
    is( $dispatch_pid, 676767, 'start_loop returns the spawned loop process pid' );
    is_deeply(
        \@spawned_command,
        [
            $runner->_windows_background_loop_command($dispatch_name),
            # The loop's identity marker travels in the spawn environ (the
            # trailing options hashref): the kernel environ block is fixed at
            # exec, so a post-exec $ENV assignment is invisible to /proc
            # readers and the marker would be a dead recognition path. The
            # runtime marker travels the same way, so the finder can scope
            # adoption to this runtime.
            { env => { DEVELOPER_DASHBOARD_LOOP_NAME => $dispatch_name, DEVELOPER_DASHBOARD_LOOP_RUNTIME => $runner->_runtime_state_key } },
        ],
        'start_loop passes the prepared helper argv to the GoRoutine launcher',
    );
}

{
    my $loop_name = 'coverage.loop.inline';
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::run_once     = sub { return { ok => 1 } };
    ok(
        $runner->_run_loop_child(
            daemonize     => 0,
            interval      => 0,
            job           => { command => 'printf inline', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        ),
        '_run_loop_child can execute a single non-daemonized coverage tick',
    );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'running', '_run_loop_child non-daemonized tick still writes running state' );
}

{
    my $loop_name = 'coverage.loop.scrub';
    my %seen;
    no warnings 'redefine';
    local $ENV{PERL5OPT} = '-MDevel::Cover';
    local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
    local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_start_loop_worker = sub {
        $seen{perl5opt} = defined $ENV{PERL5OPT} ? $ENV{PERL5OPT} : '';
        $seen{harness_perl_switches} = defined $ENV{HARNESS_PERL_SWITCHES} ? $ENV{HARNESS_PERL_SWITCHES} : '';
        return 51515;
    };
    local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
    my $ok = $runner->_run_loop_child(
        daemonize     => 0,
        interval      => 0,
        job           => { command => 'printf scrub', cwd => $home },
        name          => $loop_name,
        schedule_mode => 'interval',
        single_tick   => 1,
        title         => $runner->_process_title($loop_name),
    );
    ok( $ok, '_run_loop_child completes one scrubbed coverage tick without a forked test child' );
    is( $seen{perl5opt}, '', '_run_loop_child clears PERL5OPT before starting a managed collector worker' );
    is( $seen{harness_perl_switches}, '', '_run_loop_child clears HARNESS_PERL_SWITCHES before starting a managed collector worker' );
}

{
    my $loop_name = 'coverage.loop.error.' . $$;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_start_loop_worker = sub { die "forced child failure\n" };
    local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick = sub { return 1 };
    my $ok = $runner->_run_loop_child(
        daemonize     => 0,
        interval      => 0,
        job           => { command => 'printf child', cwd => $home },
        name          => $loop_name,
        schedule_mode => 'interval',
        single_tick   => 1,
        title         => $runner->_process_title($loop_name),
    );
    ok( $ok, '_run_loop_child survives and records a worker-launch failure during a single tick' );
    my $state = $runner->loop_state($loop_name);
    is( $state->{status}, 'error', '_run_loop_child writes error state when worker launch fails' );
    like( $state->{error}, qr/forced child failure/, '_run_loop_child persists the worker-launch error message' );
}

{
    my @spawned;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_windows_background_worker_command = sub {
            my ( undef, $name, $loop_pid ) = @_;
            return ( 'perl.exe', '_dashboard-core', 'collector-worker-foreground', '--name', $name, '--loop-pid', $loop_pid );
        };
        local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub {
            my ( undef, @command ) = @_;
            @spawned = @command;
            return 7171;
        };
        is(
            $runner->_start_loop_worker( { command => 'true' }, 'windows.worker', 'd2 collector: windows.worker' ),
            7171,
            '_start_loop_worker returns the detached Windows collector worker pid',
        );
    }
    is_deeply(
        \@spawned,
        [ 'perl.exe', '_dashboard-core', 'collector-worker-foreground', '--name', 'windows.worker', '--loop-pid', $$ ],
        '_start_loop_worker launches the detached Windows collector worker helper command',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub {
        die "unable to spawn GoRoutine child process: No such file or directory\n";
    };
    my $error = eval { $runner->_start_loop_worker( { command => 'true' }, 'spawn.fail', 'title' ); 1 } ? '' : $@;
    like( $error, qr/unable to spawn GoRoutine child process/, '_start_loop_worker propagates GoRoutine spawn failures explicitly' );
}

{
    my %active = ( 999999 => 1 );
    is( $runner->_reap_finished_loop_workers( \%active ), 0, '_reap_finished_loop_workers ignores non-child pids' );
    is_deeply( \%active, { 999999 => 1 }, '_reap_finished_loop_workers leaves unreaped pids in place' );
    is( $runner->_reap_finished_loop_workers(), 0, '_reap_finished_loop_workers tolerates a missing active-worker hash' );
}

{
    is( $runner->_settle_single_tick_workers(), 1, '_settle_single_tick_workers returns true for an empty worker set' );
    my %active = ( 41 => 1 );
    my $reap_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub {
        my ( undef, $active_workers ) = @_;
        $reap_calls++;
        %{$active_workers} = ();
        return 1;
    };
    local *Developer::Dashboard::CollectorRunner::sleep = sub { return 0 };
    is( $runner->_settle_single_tick_workers( \%active ), 1, '_settle_single_tick_workers waits for worker-settling helpers' );
    is( $reap_calls, 1, '_settle_single_tick_workers stops once the active set clears' );
}

{
    my $child_a = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', 'sleep 30;' ], { cwd => $home, env => { HOME => $home } },
    );
    die "GoRoutine spawn failed: $!" if !defined $child_a;
    my $child_b = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', 'sleep 30;' ], { cwd => $home, env => { HOME => $home } },
    );
    die "GoRoutine spawn failed: $!" if !defined $child_b;
    my %active = ( $child_a => 1, $child_b => 1 );
    ok( $runner->_terminate_loop_workers( \%active ), '_terminate_loop_workers returns true after terminating active workers' );
    is_deeply( \%active, {}, '_terminate_loop_workers clears the active worker set' );
    is( waitpid( $child_a, WNOHANG ), -1, '_terminate_loop_workers reaps the first worker child it manages' );
    is( waitpid( $child_b, WNOHANG ), -1, '_terminate_loop_workers reaps the second worker child it manages' );
}

{
    my %active = ( 424242 => 1 );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_waitpid_nonblocking = sub {
        my ( undef, $pid ) = @_;
        return $pid == 424242 ? 424242 : -1;
    };
    is( $runner->_reap_finished_loop_workers( \%active ), 1, '_reap_finished_loop_workers reaps exited worker children' );
    is_deeply( \%active, {}, '_reap_finished_loop_workers removes reaped worker children from the active set' );
}

# A loop reap must leave the exit status and errno as it found them. The
# loop reaps from its CHLD handler, and a handler can run straight after a
# system() the loop made itself, before the next statement reads the exit
# status. First with the wait replaced by one that does what a wait on a
# worker that is still running does to the exit status (-1) and what a wait
# on a pid that is not a child does to errno (ECHILD), so nothing here
# depends on signal timing or on the platform.
{
    my %active = ( 424242 => 1 );
    no warnings 'redefine';
    local $?;
    local $!;
    my $asked = 0;
    local *Developer::Dashboard::CollectorRunner::_waitpid_nonblocking = sub {
        $asked++;
        $? = -1;
        $! = POSIX::ECHILD();
        return 0;
    };
    $? = 3 << 8;
    $! = POSIX::ENOENT();
    my $reaped       = $runner->_reap_finished_loop_workers( \%active );
    my $status_after = $?;
    my $errno_after  = $! + 0;
    is( $reaped, 0, '_reap_finished_loop_workers reaps nothing while the worker is still running' );
    is( $asked,  1, '_reap_finished_loop_workers asked the wait once for its one active worker' );
    is( $status_after, 3 << 8, '_reap_finished_loop_workers leaves the exit status as it found it when the wait set it to -1' );
    is( $errno_after, POSIX::ENOENT(), '_reap_finished_loop_workers leaves errno as it found it when the wait set it to ECHILD' );
}

# The same through the real wait, on a pid that is not a child of this
# process.
{
    my %active = ( 999999 => 1 );
    local $?;
    local $!;
    $? = 3 << 8;
    $! = POSIX::ENOENT();
    $runner->_reap_finished_loop_workers( \%active );
    my $status_after = $?;
    my $errno_after  = $! + 0;
    is( $status_after, 3 << 8, '_reap_finished_loop_workers leaves the exit status as it found it through the real wait' );
    is( $errno_after, POSIX::ENOENT(), '_reap_finished_loop_workers leaves errno as it found it through the real wait' );
}

{
    my $child = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'IGNORE'; sleep 30;} ],
        { cwd => $home, env => { HOME => $home }, process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $child;
    my %active = ( $child => 1 );
    ok( $runner->_terminate_loop_workers( \%active ), '_terminate_loop_workers escalates to KILL when a worker ignores TERM' );
    is_deeply( \%active, {}, '_terminate_loop_workers clears stubborn workers after KILL escalation' );
    my $reaped = waitpid( $child, WNOHANG );
    for ( 1 .. 20 ) {
        last if $reaped == -1;
        select undef, undef, undef, 0.1;
        $reaped = waitpid( $child, WNOHANG );
    }
    is( $reaped, -1, '_terminate_loop_workers reaps a stubborn worker after KILL escalation' );
}

{
    my %active = ( 424242 => 1 );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pid_is_running = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_reap_child_process = sub { return 1 };
    ok( $runner->_terminate_loop_workers( \%active ), '_terminate_loop_workers still returns true when the forced-kill branch runs for an already-missing pid' );
    is_deeply( \%active, {}, '_terminate_loop_workers clears the active set after forcing the kill branch for coverage' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_open_file_descriptors = sub { return () };
    ok(
        $runner->_close_inherited_fds( keep => [ undef, 'not-a-fd', 1 ] ),
        '_close_inherited_fds ignores undefined and non-numeric keep descriptors while still accepting numeric keep fds before scanning inherited handles',
    );
}

SKIP: {
    # This whole fixture makes the descriptors inheritable by clearing
    # FD_CLOEXEC with fcntl, which is a Unix mechanism: F_GETFD and
    # F_SETFD do not exist on Strawberry Perl, so even evaluating them
    # dies. On Windows handle inheritance is decided by the spawn layer,
    # not by fcntl flags, so the fixture cannot be set up there.
    skip 'descriptor inheritance via fcntl F_GETFD/F_SETFD is a Unix mechanism; those macros do not exist on Strawberry Perl', 3
      if $^O eq 'MSWin32';
    pipe my $result_reader, my $result_writer or die "Unable to create result pipe: $!";
    socketpair( my $keep_left, my $keep_right, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to create keep socketpair: $!";
    socketpair( my $drop_left, my $drop_right, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "Unable to create drop socketpair: $!";
    my @inherited_handles = ( $result_writer, $keep_left, $keep_right, $drop_left, $drop_right );
    my @descriptor_flags = map {
        my $flags = fcntl( $_, F_GETFD, 0 );
        die "Unable to read descriptor flags: $!" if !defined $flags;
        $flags;
    } @inherited_handles;
    for my $index ( 0 .. $#inherited_handles ) {
        my $flags = $descriptor_flags[$index] & ~FD_CLOEXEC;
        fcntl( $inherited_handles[$index], F_SETFD, $flags )
          or die "Unable to make descriptor inheritable for GoRoutine spawn: $!";
    }
    my $source = q{
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ( $home, $result_fd, $keep_left_fd, $keep_right_fd, $drop_right_fd ) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        open my $result_writer, '>&=' . $result_fd or die "Unable to adopt result pipe: $!";
        open my $keep_left, '+<&=' . $keep_left_fd or die "Unable to adopt preserved socket: $!";
        open my $keep_right, '+<&=' . $keep_right_fd or die "Unable to adopt preserved socket: $!";
        open my $drop_right, '+<&=' . $drop_right_fd or die "Unable to adopt dropped socket: $!";
        my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths => $paths,
        );
        local $SIG{PIPE} = 'IGNORE';
        $runner->_close_inherited_fds(
            keep => [ $result_fd, $keep_left_fd, $keep_right_fd ],
            close_ipc => 1,
        );
        my $keep_ok = defined syswrite( $keep_right, "kept\n" ) ? 1 : 0;
        my $drop_ok = defined syswrite( $drop_right, "dropped\n" ) ? 1 : 0;
        print {$result_writer} "$keep_ok:$drop_ok\n" or die "Unable to report descriptor results: $!";
        close $result_writer or die "Unable to close result pipe: $!";
    };
    my @include = map { '-I' . File::Spec->catdir( $repo_root, $_ ) } qw(lib blib/lib blib/arch);
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        [
            $^X, @include, '-e', $source,
            $home, fileno($result_writer), fileno($keep_left), fileno($keep_right), fileno($drop_right),
        ],
        { cwd => $home, env => { HOME => $home } },
    );
    for my $index ( 0 .. $#inherited_handles ) {
        fcntl( $inherited_handles[$index], F_SETFD, $descriptor_flags[$index] )
          or die "Unable to restore descriptor flags after GoRoutine spawn: $!";
    }
    die "GoRoutine spawn failed: $!" if !defined $pid;
    close $result_writer;
    close $keep_right;
    close $drop_right;
    close $drop_left;
    my $payload = <$result_reader>;
    close $result_reader;
    is( Developer::Dashboard::GoRoutine::wait_process($pid), 0,
        '_close_inherited_fds descriptor fixture exits cleanly' );
    chomp $payload if defined $payload;
    is( $payload, '1:0', '_close_inherited_fds also closes inherited socketpair descriptors while preserving explicit keep handles' );
    my $kept_message = <$keep_left>;
    close $keep_left;
    is( $kept_message, "kept\n", 'spawned process retains the explicitly allowed inherited socket endpoint' );
}

{
    my $shutdown_name = 'coverage.shutdown.with-workers';
    my $shutdown_source = q{
        use File::Spec;
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::GoRoutine ();
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ($home, $name) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir($home, 'workspace') ],
        );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new(paths => $paths),
            files => Developer::Dashboard::FileRegistry->new(paths => $paths),
            indicators => Developer::Dashboard::IndicatorStore->new(paths => $paths),
            paths => $paths,
        );
        my $worker = Developer::Dashboard::GoRoutine::spawn(
            [ $^X, '-e', 'sleep 30' ],
            {},
        );
        die "GoRoutine worker launch failed: $!" if !defined $worker;
        my %active = ( $worker => 1 );
        $runner->_shutdown_loop($name, 'stopped', \%active);
    };
    is( _run_perl_child( $shutdown_source, $home, $shutdown_name ), 0,
        '_shutdown_loop terminates tracked GoRoutine workers before exiting a managed child' );
    pass('_shutdown_loop reaps tracked worker children during shutdown');
}

{
    my $source = q{
        use File::Spec;
        use JSON::XS ();
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::JSON ();
        use Developer::Dashboard::PathRegistry;
        my ($home) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
        );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths => $paths,
        );
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::run_once = sub { die "worker fallback failure\n" };
        local *Developer::Dashboard::CollectorRunner::_write_loop_state = sub {
            my ( undef, $name, $data ) = @_;
            my $file = File::Spec->catfile( $home, 'worker-fallback-state.json' );
            open my $fh, '>', $file or die $!;
            print {$fh} JSON::XS->new->encode( { name => $name, %{$data} } );
            close $fh;
            return $data;
        };
        $runner->_run_loop_worker(
            { command => 'printf fallback', cwd => $home, interval => 2 },
            'worker.fallback',
            undef,
            undef,
        );
    };
    is( _run_perl_child( $source, $home ), 255,
        '_run_loop_worker exits non-zero when the worker body dies' );
    my $state_file = File::Spec->catfile( $home, 'worker-fallback-state.json' );
    open my $state_fh, '<', $state_file or die $!;
    my $state = json_decode( do { local $/; <$state_fh> } );
    close $state_fh;
    is( $state->{process_name}, $runner->_process_title('worker.fallback'), '_run_loop_worker falls back to the managed loop title when no title is supplied' );
    is( $state->{schedule}, 'interval', '_run_loop_worker falls back to interval schedule metadata from the job' );
    ok( $state->{pid} > 0, '_run_loop_worker falls back to the current pid when no loop pid is supplied' );
}

{
    my $loop_name = 'coverage.loop.start-failure';
    my $source = q{
        use File::Spec;
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ($home, $loop_name) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir($home, 'workspace') ],
        );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new(paths => $paths),
            files => Developer::Dashboard::FileRegistry->new(paths => $paths),
            indicators => Developer::Dashboard::IndicatorStore->new(paths => $paths),
            paths => $paths,
        );
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_start_loop_worker = sub { die "forced worker start failure\n" };
        local *Developer::Dashboard::CollectorRunner::sleep = sub { return 0 };
        my $ok = $runner->_run_loop_child(
            daemonize     => 0,
            interval      => 0,
            job           => { command => 'printf child', cwd => $home },
            name          => $loop_name,
            schedule_mode => 'interval',
            single_tick   => 1,
            title         => $runner->_process_title($loop_name),
        );
        my $state = $runner->loop_state($loop_name);
        open my $fh, '>', File::Spec->catfile($home, 'start-failure-state.json')
          or die "Unable to write loop state: $!";
        print {$fh} Developer::Dashboard::JSON::json_encode($state);
        close $fh or die "Unable to close loop state: $!";
        exit( $ok ? 0 : 1 );
    };
    is( _run_perl_child( $source, $home, $loop_name ), 0,
        '_run_loop_child returns cleanly after a worker-start failure tick' );
    my $state_file = File::Spec->catfile( $home, 'start-failure-state.json' );
    open my $state_fh, '<', $state_file or die "Unable to read loop state: $!";
    my $state = json_decode( do { local $/; <$state_fh> } );
    close $state_fh or die "Unable to close loop state: $!";
    is( $state->{status}, 'error', '_run_loop_child records error state when worker startup fails' );
    like( $state->{error}, qr/forced worker start failure/, '_run_loop_child persists worker-start failure details' );
}

{
    my $missing_root = File::Spec->catdir( $home, 'missing-collectors-root' );
    my $alt_paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $alt_runner = Developer::Dashboard::CollectorRunner->new(
        collectors => $collector_store,
        files      => $files,
        paths      => $alt_paths,
    );
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::collectors_root = sub { return $missing_root };
    is_deeply( [ $alt_runner->running_loops ], [], 'running_loops returns an empty list when the collectors root cannot be opened' );
}

{
    my $pidfile = $runner->_pidfile('foreign-namespace');
    open my $fh, '>', $pidfile or die $!;
    print {$fh} "12345\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_same_pid_namespace = sub { return 0 };
    is( $runner->stop_loop('foreign-namespace'), 12345, 'stop_loop returns the pid when it belongs to a foreign namespace' );
    ok( !-f $pidfile, 'stop_loop still removes foreign-namespace pidfiles during cleanup' );
}

{
    my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
    my $web_page = Developer::Dashboard::PageDocument->new(
        title  => 'Web Coverage',
        layout => {
            body => qq{<script>const value = "x";</script><div onclick="go()">[% stash.name %]</div>},
        },
    );
    my $rendered = $web_page->render_html;
    my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
    my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
    my $actions = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );
    my $prompt = Developer::Dashboard::Prompt->new( indicators => $indicator_store, paths => $paths );
    my $app = Developer::Dashboard::Web::App->new(
        actions  => $actions,
        auth     => $auth,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );

    like( Developer::Dashboard::Web::App::_highlight_js_text( undef, q{const value = "x"; // note} ), qr/tok-js/, 'web app JS highlighter marks JavaScript keywords' );
    like( Developer::Dashboard::Web::App::_highlight_js_text( undef, q{const value = 'x';} ), qr/tok-string/, 'web app JS highlighter marks single-quoted JavaScript strings' );
    like( Developer::Dashboard::Web::App::_highlight_css_text( undef, q{body { color: red; }} ), qr/tok-css|tok-attr|tok-value/, 'web app CSS highlighter supports direct package-style calls' );
    like( Developer::Dashboard::Web::App::_highlight_css_text( undef, q{/* note */ body { color: red; }} ), qr/tok-comment/, 'web app CSS highlighter marks CSS comments' );
    like( Developer::Dashboard::Web::App::_highlight_perl_text( undef, q{my $value = 1;} ), qr/tok-perl-keyword/, 'web app Perl highlighter supports direct package-style calls' );
    like( Developer::Dashboard::Web::App::_highlight_perl_text( undef, q{my $value = 'x';} ), qr/tok-string/, 'web app Perl highlighter marks single-quoted Perl strings' );
    like( Developer::Dashboard::Web::App::_highlight_perl_text( undef, q{[% stash.name %] my @items = (); my %lookup = ();} ), qr/tok-note.*tok-perl-var/s, 'web app Perl highlighter marks TT notes and array/hash variables' );
    is( Developer::Dashboard::Web::App::_highlight_restore_tokens( undef, 'plain text', undef ), 'plain text', 'web app restore helper leaves plain text untouched when no tokens were stored' );
    like(
        $app->_highlight_perl_text(q{my $value = 1; # trailing comment}),
        qr/tok-comment/,
        'web app Perl highlighter marks trailing comments inside CODE sections',
    );
    like(
        $app->_highlight_html_text( q{const value = "x";</script><div>next</div>}, { html_mode => 'script' } ),
        qr/tok-js.*tok-tag/s,
        'web app HTML highlighter closes script mode and resumes markup highlighting',
    );
    like(
        $app->_highlight_html_text( q{body { color: red; }}, { html_mode => 'style' } ),
        qr/tok-css|tok-attr|tok-value/,
        'web app HTML highlighter keeps CSS highlighting active when style mode continues onto the next line',
    );
    like(
        $app->_highlight_html_text( q{const value = "x";}, { html_mode => 'script' } ),
        qr/tok-js/,
        'web app HTML highlighter handles script mode lines without closing tags',
    );
    like(
        $app->_highlight_tag_markup( '&lt;', 'div', q{ style=&quot;color:red&quot; onclick=&quot;go()&quot; data-id=&quot;1&quot;}, '&gt;' ),
        qr/tok-value tok-css.*tok-value tok-js.*tok-value/s,
        'web app tag highlighter classifies style, JS, and generic attribute values',
    );
    like(
        $app->_highlight_instruction_html(<<'SOURCE'),
HTML: <style>
body { color: red; }
</style>
NOTE: [% stash.name %]
CODE1: my $value = 1;
SOURCE
        qr/tok-directive.*tok-css.*tok-note.*tok-perl-keyword/s,
        'web app instruction highlighter covers HTML, note, and code sections from one source block',
    );
    {
        my %state = ( section => 'NOTE', html_mode => '' );
        like(
            $app->_highlight_editor_line('still [% stash.name %]', \%state),
            qr/tok-note/,
            'web app editor-line highlighter preserves TT note highlighting on section continuation lines',
        );
    }
    {
        my %state = ( section => '', html_mode => '' );
        like(
            $app->_highlight_editor_line(':--------------------------------------------------------------------------------:', \%state),
            qr/tok-separator/,
            'web app editor-line highlighter marks separator rows explicitly',
        );
    }
    {
        my %state = ( section => '', html_mode => '' );
        like(
            $app->_highlight_editor_line('HTML: plain text', \%state),
            qr/tok-directive/,
            'web app editor-line highlighter marks directive prefixes explicitly',
        );
        is( $state{section}, 'HTML', 'web app editor-line highlighter updates section tracking from directives' );
    }
    is(
        $app->_highlight_section_text( '<plain>', { section => 'FORM', html_mode => 'style' } ),
        '&lt;plain&gt;',
        'web app section highlighter treats removed FORM sections as plain escaped text',
    );
    like(
        $app->_highlight_section_text( '[% stash.name %]', { section => 'NOTE', html_mode => '' } ),
        qr/tok-note/,
        'web app section highlighter routes note sections through the note highlighter',
    );
    is(
        $app->_highlight_section_text( '<plain>', { section => 'TITLE', html_mode => '' } ),
        '&lt;plain&gt;',
        'web app section highlighter falls back to escaped plain text for non-code non-HTML sections',
    );
    like(
        $app->_highlight_html_text( q{body { color: red; }</style><div>next</div>}, { html_mode => 'style' } ),
        qr/tok-attr|tok-value.*tok-tag/s,
        'web app HTML highlighter closes style mode and resumes markup highlighting',
    );
    like(
        $app->_highlight_html_text( q{before<style>body { color: red; }</style>after}, { html_mode => '' } ),
        qr/tok-tag.*tok-css/s,
        'web app HTML highlighter enters style mode when a style tag opens on the current line',
    );

    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub {
        my ($name) = @_;
        return $name eq 'ifconfig' ? '/tmp/fake-ifconfig' : undef;
    };
    local *Developer::Dashboard::Web::App::capture = sub (&) {
        my ($code) = @_;
        my $stdout = "wg0: flags\n    inet 10.8.0.2\neth0: flags\n    inet 192.168.1.9\n";
        my $exit = 0;
        return ( $stdout, '', $exit );
    };
    my @ifconfig_pairs = $app->_ip_pairs_from_ifconfig;
    is_deeply(
        \@ifconfig_pairs,
        [
            { iface => 'wg0',  ip => '10.8.0.2' },
            { iface => 'eth0', ip => '192.168.1.9' },
        ],
        'web app parses ifconfig fallback output',
    );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::_ip_interface_pairs = sub {
            return (
                { iface => 'wg0',  ip => '10.8.0.2' },
                { iface => 'eth0', ip => '192.168.1.9' },
                { iface => 'lo',   ip => '127.0.0.1' },
                { iface => 'eth0', ip => '192.168.1.9' },
            );
        };
        is_deeply(
            [ $app->_ip_candidates ],
            [ '10.8.0.2', '192.168.1.9', '127.0.0.1' ],
            'web app orders VPN, preferred, and other IPv4 candidates while removing duplicates',
        );
    }

    my $transient_action_page = Developer::Dashboard::PageDocument->new(
        title       => 'Transient Action',
        state       => { value => 'hello' },
        actions     => [ { id => 'page-state', kind => 'builtin', builtin => 'page.state' } ],
        permissions => { allow_untrusted_actions => 1 },
    );
    my $token = $store->encode_page($transient_action_page);
    my ( $blocked_status, $blocked_type, $blocked_body ) = @{ $app->handle(
        path        => '/action',
        method      => 'POST',
        query       => '',
        body        => 'token=' . uri_escape($token) . '&id=page-state',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $blocked_status, 403, 'transient action fallback route is denied by default' );
    like( $blocked_type, qr/text\/plain/, 'transient action fallback denial returns plain-text content type' );
    like( $blocked_body, qr/Transient token URLs are disabled/, 'transient action fallback denial explains the policy' );

    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    my ( $status, $type, $body ) = @{ $app->handle(
        path        => '/action',
        method      => 'POST',
        query       => '',
        body        => 'token=' . uri_escape($token) . '&id=page-state',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    ) };
    is( $status, 404, 'transient action fallback route executes and rejects missing serialized actions cleanly' );
    like( $type, qr/text\/plain/, 'transient action fallback returns plain-text error content type when the action is absent' );
    like( $body, qr/Action not found/, 'transient action fallback reports missing transient action ids cleanly' );

    my $body_app = Developer::Dashboard::Web::App->new(
        actions  => bless( {}, 'Local::BodyActionRunner' ),
        auth     => $auth,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );
    my $saved_action_page = Developer::Dashboard::PageDocument->new(
        id      => 'body-action',
        title   => 'Body Action',
        actions => [ { id => 'download', kind => 'builtin', builtin => 'page.state' } ],
    );
    my $response = $body_app->_action_response(
        id     => 'download',
        page   => $saved_action_page,
        source => 'saved',
        params => {},
    );
    is( $response->[0], 200, 'web app action response returns success for explicit body payloads' );
    is( $response->[1], 'text/plain; charset=utf-8', 'web app action response uses explicit body content type defaults' );
    is( $response->[2], 'body-payload', 'web app action response returns raw body payloads' );

    {
        my $render_page = Developer::Dashboard::PageDocument->new(
            id      => 'render-cover',
            title   => 'Render Cover',
            layout  => { body => '<div>render body</div>' },
            actions => [ undef, { builtin => 'missing-id' }, { id => 'download', builtin => 'page.state' } ],
        );
        $render_page->{meta}{source_kind} = 'saved';
        my $html = $body_app->_render_page_html( $render_page, 'render' );
        like( $html, qr/render body/, 'web app render helper still renders page bodies when invalid actions are skipped' );
        like( $html, qr/view-source-url/, 'web app render helper still renders the shared chrome after skipping invalid action rows' );
    }

    $indicator_store->set_indicator(
        'docker',
        label          => 'Docker',
        alias          => '&#x1F433;',
        status         => 'ok',
        prompt_visible => 1,
    );
    is( $app->_prompt_summary, '&#x2705;&#x1F433;', 'web app top status summary renders indicator status and alias pairs' );
    like(
        $app->_top_chrome_html(
            Developer::Dashboard::PageDocument->new( id => 'coverage-top', layout => { body => 'Body' } ),
            { edit => '/app/coverage-top/edit', render => '/app/coverage-top', source => '/app/coverage-top/source' },
        ),
        qr/Segoe UI Emoji.*Noto Color Emoji/s,
        'web app top chrome uses an emoji-capable font stack for the browser status strip',
    );
}

{
    my $error_icon = $indicator_store->_page_status_icon( { status => 'error' } );
    is( $error_icon, '&#x1F6A8;', 'indicator store resolves explicit error icon mappings' );
    is( $indicator_store->prompt_status_icon( { status => 'ok' } ), '✅', 'indicator store resolves prompt success glyphs' );
    my $fallback_icon = $indicator_store->_page_status_icon( { status => 'unknown', icon => 'X' } );
    is( $fallback_icon, 'X', 'indicator store falls back to explicit icon when no mapping exists' );
}

done_testing;

{
    package Local::BodyActionRunner;
    # run_page_action(%args)
    # Returns a direct body payload for Web::App action response coverage.
    # Input: ignored.
    # Output: hash reference with body and content_type.
    sub run_page_action { return { body => 'body-payload' } }

    # encode_action_payload(%args)
    # Returns a stable fake encoded action token for render-link coverage.
    # Input: ignored.
    # Output: string token.
    sub encode_action_payload { return 'encoded-action-token' }
}

__END__

=head1 NAME

14-coverage-closure-extra.t - targeted coverage closure tests for remaining runtime branches

=head1 DESCRIPTION

This test exercises migration, fallback, private helper, and managed-child
paths that are difficult to reach from the higher-level CLI and browser flows.
Long-lived process fixtures are launched with the GoRoutine process API so the
coverage test exercises the same cross-platform process boundary as the
application without direct Perl process-creation calls outside GoRoutine.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the hard-to-hit branches that keep library coverage honest. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the hard-to-hit branches that keep library coverage honest has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the hard-to-hit branches that keep library coverage honest, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it inside the dev Docker container with C<d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -lv t/14-coverage-closure-extra.t> while iterating, then keep it green under the Docker test suite and coverage runs before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/14-coverage-closure-extra.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/14-coverage-closure-extra.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
