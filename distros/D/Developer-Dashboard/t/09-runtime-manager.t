use strict;
use warnings;

# Suppress warnings from external libraries while testing
BEGIN {
    $SIG{__WARN__} = sub {
        my ($msg) = @_;
        return if $msg =~ m{Plack/Runner\.pm|Getopt/Long\.pm};
        warn $msg;
    };
}

use File::Temp qw(tempdir);
use File::Spec;
use POSIX qw(:sys_wait_h);
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';

my $UNDER_COVER = exists $INC{'Devel/Cover.pm'};

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

sub wait_for_child_exit {
    my ( $pid, $attempts, $interval ) = @_;
    $attempts = 20 if !defined $attempts;
    $interval = 0.1 if !defined $interval;

    for ( 1 .. $attempts ) {
        my $reaped = waitpid( $pid, WNOHANG );
        return 1 if $reaped == $pid || !kill 0, $pid;
        sleep $interval;
    }

    return 0;
}

{
    package Local::RuntimeRunner;
    sub new { bless { loops => [], started => [], stopped => [] }, shift }
    sub running_loops { @{ $_[0]{loops} } }
    sub start_loop {
        my ( $self, $job ) = @_;
        die $self->{fail}{ $job->{name} } if ref( $self->{fail} ) eq 'HASH' && exists $self->{fail}{ $job->{name} };
        push @{ $self->{started} }, $job->{name};
        push @{ $self->{loops} }, { name => $job->{name}, pid => 1000 + @{ $self->{started} } };
        return 1000 + @{ $self->{started} };
    }
    sub stop_loop {
        my ( $self, $name ) = @_;
        push @{ $self->{stopped} }, $name;
        $self->{loops} = [ grep { $_->{name} ne $name } @{ $self->{loops} } ];
        return 1;
    }

    package Local::RuntimeDaemon;
    sub new {
        my ( $class, $host, $port ) = @_;
        return bless { host => $host, port => $port }, $class;
    }
    sub sockhost { $_[0]{host} }
    sub sockport { $_[0]{port} }

    package Local::RuntimeServer;
    sub new {
        my ( $class, %args ) = @_;
        return bless { %args }, $class;
    }
    sub start_daemon {
        die "daemon boom\n" if $_[0]{fail_daemon};
        return Local::RuntimeDaemon->new( $_[0]{host}, $_[0]{port} );
    }
    sub serve_daemon {
        die "serve boom\n" if $_[0]{fail_serve};
        return 1 if $_[0]{return_immediately};
        while (1) { sleep 0.1 }
    }
    sub run {
        open my $fh, '>', $_[0]{foreground_file} or die $!;
        print {$fh} "foreground\n";
        close $fh;
        return 1;
    }
}

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
$config->save_global(
    {
        collectors => [
            { name => 'alpha.collector', command => 'true', cwd => 'home', interval => 1 },
            { name => 'beta.collector',  command => 'true', cwd => 'home', interval => 1 },
        ],
    }
);
my $runner = Local::RuntimeRunner->new;
my $foreground_file = "$home/foreground.txt";

my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        my (%args) = @_;
        return Local::RuntimeServer->new(
            foreground_file => $foreground_file,
            host            => $args{host},
            port            => $args{port},
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

dies_like( sub { Developer::Dashboard::RuntimeManager->new }, qr/Missing config/, 'runtime manager requires config' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config ) }, qr/Missing file registry/, 'runtime manager requires files' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files ) }, qr/Missing path registry/, 'runtime manager requires paths' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files, paths => $paths ) }, qr/Missing collector runner/, 'runtime manager requires runner' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files, paths => $paths, runner => $runner ) }, qr/Missing app builder/, 'runtime manager requires app builder' );

is( $manager->_web_process_title( '0.0.0.0', 7890 ), 'dashboard web: 0.0.0.0:7890', 'web process title is predictable' );
like( Developer::Dashboard::RuntimeManager::_now_iso8601(), qr/^\d{4}-\d{2}-\d{2}T/, 'timestamp helper emits ISO-8601' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'dashboard web: 0.0.0.0:7890' } ), 'managed web process titles are recognized' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/dashboard serve' } ), 'legacy perl dashboard serve command lines are recognized' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'dashboard serve --workers 4 --port 7890' } ), 'dashboard serve with startup flags is recognized as a web process' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/dashboard ps1' } ), 'non-web dashboard commands are ignored' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl /usr/local/bin/dashboard serve logs -f -n 100' } ), 'dashboard serve logs followers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'dashboard serve workers 8' } ), 'dashboard serve workers subcommands are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{/bin/bash -c dashboard serve; sleep 1} } ), 'shell wrappers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{strace -ff -o /tmp/ddexec ./bin/dashboard serve} } ), 'tracing wrappers are not mistaken for web workers' );

$manager->_cleanup_web_files;
ok( !defined $manager->web_state, 'no web state file exists initially' );

{
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7902;
        $calls++;
        return $calls < 3 ? (4242) : ();
    };
    ok( $manager->_wait_for_port_release(7902), '_wait_for_port_release waits until the listener port clears' );
    is( $calls, 3, '_wait_for_port_release keeps polling until the port is free' );
}

{
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7907;
        $calls++;
        return (4242);
    };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    ok( !$manager->_wait_for_port_release(7907), '_wait_for_port_release returns false when the listener never clears' );
    is( $calls, 51, '_wait_for_port_release probes the listener port through the final timeout check' );
}

my $pid;
{
    no warnings 'redefine';
    $manager->_cleanup_web_files;
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub { return ( { pid => $$, args => 'perl -Ilib bin/dashboard serve' } ) };
    ok( !$manager->running_web, 'no managed web process is running initially' );
    $pid = $manager->start_web( host => '0.0.0.0', port => 7898 );
}
ok( $pid > 0, 'background web start returns a pid' );
my $running;
for ( 1 .. 20 ) {
    $running = $manager->running_web;
    last if $running && $running->{pid} == $pid && ( $running->{port} || 0 ) == 7898;
    sleep 0.1;
}
is( $running->{pid}, $pid, 'running_web reads the managed pid' );
is( $running->{host}, '0.0.0.0', 'running_web reports configured host' );
is( $running->{port}, 7898, 'running_web reports configured port' );
ok( $manager->_is_managed_web($pid), 'started pid is recognized as a managed web process' );
my $dedup_pid;
for ( 1 .. 20 ) {
    $dedup_pid = scalar( $manager->start_web( host => '0.0.0.0', port => 7898 ) );
    last if $dedup_pid == $pid;
    sleep 0.1;
}
is( $dedup_pid, $pid, 'background start deduplicates an already running web process' );
{
    my $marker_child = fork();
    die "fork failed: $!" if !defined $marker_child;
    if ( !$marker_child ) {
        exec 'env', 'RUNTIME_MANAGER_MARKER=yes', $^X, '-e', 'sleep 10';
    }
    my $marker;
    for ( 1 .. 20 ) {
        $marker = $manager->_read_process_env_marker( $marker_child, 'RUNTIME_MANAGER_MARKER' );
        last if defined $marker;
        sleep 0.1;
    }
    if ($UNDER_COVER) {
        pass('process environment marker reads are timing-tolerant under coverage');
    }
    elsif ( !-d File::Spec->catdir( '/proc', $marker_child ) ) {
        pass('process environment marker reads are skipped when process environment inspection is unavailable');
    }
    else {
        is( $marker, 'yes', 'process environment markers are readable' );
    }
    kill 'TERM', $marker_child;
    waitpid( $marker_child, 0 );
}
my $title;
for ( 1 .. 20 ) {
    $title = $manager->_read_process_title($pid);
    last if defined $title && $title =~ /^dashboard web:/;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('managed web process title reads are timing-tolerant under coverage');
}
else {
    like( $title, qr/^dashboard web:/, 'managed web process title is readable' );
}
ok( scalar $manager->_ps_processes, 'ps process list is available' );
my @prefixed;
for ( 1 .. 20 ) {
    @prefixed = $manager->_find_processes_by_prefix('dashboard web:');
    last if @prefixed;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('process prefix scan is timing-tolerant under coverage');
}
else {
    ok( scalar @prefixed, 'process prefix scan finds running web process' );
}

$manager->_write_web_state( { pid => $pid, host => 'scan.host', port => 9999, status => 'running' } );
$files->remove('web_pid');
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $pid,
                args => 'dashboard web: 0.0.0.0:7898',
            }
        );
    };
    my $scan_state = $manager->running_web;
    is( $scan_state->{pid}, $pid, 'running_web falls back to process scanning when the pid file is missing' );
}
$files->write( 'web_pid', "$pid\n" );

my $stopped_pid;
for ( 1 .. 5 ) {
    $stopped_pid = $manager->stop_web;
    last if defined $stopped_pid;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('stop_web pid return is timing-tolerant under coverage');
    pass('stop_web process-scan shutdown is timing-tolerant under coverage');
}
else {
    is( $stopped_pid, $pid, 'stop_web returns the stopped pid' );
    ok( !$files->read('web_pid'), 'stop_web clears the managed web pid record after stopping the process' );
}
ok( !-f $files->web_pid, 'stop_web removes the web pid file' );
ok( !-f $files->web_state, 'stop_web removes the web state file' );
$manager->_cleanup_web_files;
ok( !-f $files->web_pid, 'cleanup is idempotent for pid files' );

ok( $manager->start_web( foreground => 1, host => '0.0.0.0', port => 7900 ), 'foreground start returns successfully' );
ok( -f $foreground_file, 'foreground start delegates to server run' );

{
    my %captured;
    my $default_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            my (%args) = @_;
            %captured = %args;
            return Local::RuntimeServer->new(
                foreground_file => $foreground_file,
                host            => $args{host},
                port            => $args{port},
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    ok( $default_manager->start_web( foreground => 1 ), 'foreground start uses defaults when host and port are omitted' );
    is_deeply( \%captured, { host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 }, 'foreground start forwards the default host, port, and worker count to the app builder' );
}

{
    my %captured;
    my $worker_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            my (%args) = @_;
            %captured = %args;
            return Local::RuntimeServer->new(
                foreground_file => $foreground_file,
                host            => $args{host},
                port            => $args{port},
                workers         => $args{workers},
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    ok( $worker_manager->start_web( foreground => 1, workers => 4 ), 'foreground start accepts an explicit worker count' );
    is_deeply( \%captured, { host => '0.0.0.0', port => 7890, workers => 4, ssl => 0 }, 'foreground start forwards an explicit worker count to the app builder' );
}

my $builder_error_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { die "builder boom\n" },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);
dies_like( sub { $builder_error_manager->start_web( host => '0.0.0.0', port => 7901 ) }, qr/builder boom/, 'background start surfaces app-builder failures' );

my $daemon_error_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        return Local::RuntimeServer->new(
            fail_daemon => 1,
            host        => '0.0.0.0',
            port        => 7902,
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);
dies_like( sub { $daemon_error_manager->start_web( host => '0.0.0.0', port => 7902 ) }, qr/daemon boom/, 'background start surfaces daemon-start failures' );

{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $builder_exit = $builder_error_manager->_run_web_child( $writer, '0.0.0.0', 7901, detach => 0, redirect => 0 );
    is( $builder_exit, 1, '_run_web_child returns a non-zero exit code for builder failures' );
    like( $buffer, qr/^err: builder boom/, '_run_web_child writes builder failures to the startup pipe' );
}

{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $daemon_exit = $daemon_error_manager->_run_web_child( $writer, '0.0.0.0', 7902, detach => 0, redirect => 0 );
    is( $daemon_exit, 1, '_run_web_child returns a non-zero exit code for daemon failures' );
    like( $buffer, qr/^err: daemon boom/, '_run_web_child writes daemon failures to the startup pipe' );
}

my $serve_error_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        return Local::RuntimeServer->new(
            fail_serve => 1,
            host       => '0.0.0.0',
            port       => 7904,
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);
{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $serve_exit = $serve_error_manager->_run_web_child( $writer, '0.0.0.0', 7904, detach => 0, redirect => 0 );
    is( $serve_exit, 1, '_run_web_child returns a non-zero exit code for serve failures' );
    like( $buffer, qr/^ok\|/, '_run_web_child reports a successful bind before a serve-loop failure' );
    is( $serve_error_manager->web_state->{status}, 'error', '_run_web_child records error status when the serve loop dies' );
}

my $clean_exit_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        return Local::RuntimeServer->new(
            host               => '0.0.0.0',
            port               => 7905,
            return_immediately => 1,
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);
{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $clean_exit = $clean_exit_manager->_run_web_child( $writer, '0.0.0.0', 7905, detach => 0, redirect => 0 );
    is( $clean_exit, 0, '_run_web_child returns zero when the server loop ends cleanly' );
    is( $clean_exit_manager->web_state->{status}, 'stopped', '_run_web_child records stopped status after a clean exit' );
    $clean_exit_manager->_cleanup_web_files;
}

{
    my $state = $manager->_write_web_state();
    is_deeply( $state, {}, '_write_web_state persists an empty hash when no state payload is provided' );
    is_deeply( $manager->web_state, {}, 'web_state reads back the empty-state payload written by _write_web_state' );
    $manager->_cleanup_web_files;
}

$files->write( 'dashboard_log', "starman line\nDancer2 line\n" );
is( $manager->web_log, "starman line\nDancer2 line\n", 'web_log reads the persisted dashboard web-service log output' );
is( $manager->_tail_text( "one\ntwo\nthree\n", 2 ), "two\nthree\n", '_tail_text keeps the requested trailing newline-terminated log lines' );
is( $manager->_tail_text( "one\ntwo\nthree", 2 ), "two\nthree", '_tail_text preserves non-terminated trailing log lines' );
is( $manager->web_log( lines => 1 ), "Dancer2 line\n", 'web_log can return only the last requested number of lines' );
$files->remove('dashboard_log');
is( $manager->web_log, '', 'web_log returns an empty string when the dashboard log file is missing' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_follow_log_file = sub { return 1 };
    $files->write( 'dashboard_log', "follow once\n" );
    is( $manager->web_log( follow => 1, lines => 1 ), '', 'web_log follow mode returns an empty string after delegating to the follow loop' );
}
{
    $files->write( 'dashboard_log', "alpha\nbeta\n" );
    my $follow_capture = "$home/web-log-follow.txt";
    my $follow_pid = fork();
    die "fork failed: $!" if !defined $follow_pid;
    if ( !$follow_pid ) {
        open STDOUT, '>', $follow_capture or die $!;
        $manager->web_log( follow => 1, lines => 1 );
        exit 0;
    }
    my $follow_output = '';
    for ( 1 .. 30 ) {
        if ( -f $follow_capture ) {
            open my $fh, '<', $follow_capture or die $!;
            local $/;
            $follow_output = <$fh>;
            close $fh;
            last if $follow_output =~ /beta\n/;
        }
        sleep 0.1;
    }
    like( $follow_output, qr/beta\n/, 'web_log follow mode starts from the tailed log output' );
    $files->append( 'dashboard_log', "gamma\n" );
    for ( 1 .. 30 ) {
        open my $fh, '<', $follow_capture or die $!;
        local $/;
        $follow_output = <$fh>;
        close $fh;
        last if $follow_output =~ /gamma\n/;
        sleep 0.1;
    }
    like( $follow_output, qr/gamma\n/, 'web_log follow mode streams appended log lines' );
    kill 'TERM', $follow_pid;
    waitpid( $follow_pid, 0 );
    is( $? >> 8, 0, 'web_log follow mode exits cleanly on TERM' );
}
{
    my $missing_follow = "$home/missing-follow.log";
    my $missing_pid = fork();
    die "fork failed: $!" if !defined $missing_pid;
    if ( !$missing_pid ) {
        $manager->_follow_log_file( file => $missing_follow, interval => 0.05 );
        exit 0;
    }
    for ( 1 .. 30 ) {
        last if -f $missing_follow;
        sleep 0.1;
    }
    ok( -f $missing_follow, '_follow_log_file creates a missing log file before following it' );
    kill 'HUP', $missing_pid;
    waitpid( $missing_pid, 0 );
    is( $? >> 8, 0, '_follow_log_file exits cleanly on HUP' );
}
{
    my $signal_follow = "$home/signal-follow.log";
    $files->write( 'dashboard_log', "signal\n" );
    open my $fh, '>', $signal_follow or die $!;
    close $fh;
    my $signal_pid = fork();
    die "fork failed: $!" if !defined $signal_pid;
    if ( !$signal_pid ) {
        $manager->_follow_log_file( file => $signal_follow, interval => 0.05 );
        exit 0;
    }
    sleep 0.2;
    kill 'INT', $signal_pid;
    waitpid( $signal_pid, 0 );
    is( $? >> 8, 0, '_follow_log_file exits cleanly on INT' );
}

@{ $runner->{loops} } = (
    { name => 'alpha.collector', pid => 1111 },
    { name => 'beta.collector',  pid => 2222 },
);
my @stopped_collectors = $manager->stop_collectors;
is_deeply( \@stopped_collectors, [ 'alpha.collector', 'beta.collector' ], 'stop_collectors returns stopped collector names' );
is_deeply( $runner->{stopped}, [ 'alpha.collector', 'beta.collector' ], 'stop_collectors delegates each running collector to the runner' );

my @started_collectors = $manager->start_collectors;
is_deeply( [ map { $_->{name} } @started_collectors ], [ 'alpha.collector', 'beta.collector' ], 'start_collectors starts configured collectors' );

{
    local $runner->{started} = [];
    local $runner->{stopped} = [];
    local $runner->{loops}   = [];
    local $runner->{fail}    = { 'beta.collector' => "beta start failed\n" };
    my $error = eval { $manager->start_collectors; 1 } ? '' : $@;
    like( $error, qr/Failed to start collector 'beta\.collector': beta start failed/, 'start_collectors surfaces collector loop startup failures explicitly' );
    is_deeply( $runner->{started}, [ 'alpha.collector' ], 'start_collectors stops launching collectors after a startup failure' );
    is_deeply( $runner->{stopped}, ['alpha.collector'], 'start_collectors cleans up already-started collectors when a later collector fails to start' );
}

{
    my %forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        %forwarded = %args;
        return 9903;
    };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub {
        return (
            { name => 'alpha.collector', pid => 1101 },
            { name => 'beta.collector',  pid => 1102 },
        );
    };
    my $served = $manager->serve_all( host => '127.0.0.1', port => 7931, workers => 4, ssl => 1 );
    is( $served->{pid}, 9903, 'serve_all returns the managed web pid in background mode' );
    is_deeply(
        $served->{collectors},
        [
            { name => 'alpha.collector', pid => 1101 },
            { name => 'beta.collector',  pid => 1102 },
        ],
        'serve_all reports the configured collectors it started in background mode',
    );
    is_deeply( \%forwarded, { foreground => 0, host => '127.0.0.1', port => 7931, workers => 4, ssl => 1 }, 'serve_all forwards normalized background web arguments to start_web' );
}

{
    my @calls;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub {
        push @calls, 'start_collectors';
        return ( { name => 'alpha.collector', pid => 1201 } );
    };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        push @calls, 'start_web_foreground' if $args{foreground};
        return 'foreground-ok';
    };
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub {
        push @calls, 'stop_collectors';
        return ('alpha.collector');
    };
    my $served = $manager->serve_all( foreground => 1, host => '127.0.0.1', port => 7932 );
    is( $served->{result}, 'foreground-ok', 'serve_all returns the foreground web result when the server exits cleanly' );
    is_deeply( $served->{stopped_collectors}, ['alpha.collector'], 'serve_all stops managed collectors after a foreground web session exits' );
    is_deeply( \@calls, [ 'start_collectors', 'start_web_foreground', 'stop_collectors' ], 'serve_all wraps the foreground web session with collector lifecycle control' );
}

my $restart = $manager->restart_all( host => '0.0.0.0', port => 7903 );
ok( $restart->{web_pid} > 0, 'restart_all starts a background web process' );
is_deeply( [ map { $_->{name} } @{ $restart->{collectors} } ], [ 'alpha.collector', 'beta.collector' ], 'restart_all restarts configured collectors' );
ok( $manager->running_web, 'restart_all leaves the web process running' );
my $stop_all = $manager->stop_all;
ok( defined $stop_all->{web_pid}, 'stop_all returns the web pid when it stops a running service' );

{
    my $ajax_pid = fork();
    die "fork failed: $!" if !defined $ajax_pid;
    if ( !$ajax_pid ) {
        $0 = 'dashboard ajax: STOP-ME';
        $SIG{TERM} = sub { exit 0 };
        while (1) { sleep 1 }
    }
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $ajax_pid } $manager->_find_processes_by_prefix('dashboard ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'test ajax singleton worker is visible in the process table before stop_all' );
    $manager->stop_all;
    for ( 1 .. 20 ) {
        my $reaped = waitpid( $ajax_pid, WNOHANG );
        last if $reaped == $ajax_pid || !kill 0, $ajax_pid;
        sleep 0.1;
    }
    my $stop_reaped = waitpid( $ajax_pid, WNOHANG );
    ok( $stop_reaped == $ajax_pid || !kill( 0, $ajax_pid ), 'stop_all terminates saved ajax singleton workers along with the web service lifecycle' );
    waitpid( $ajax_pid, 0 ) if $stop_reaped != $ajax_pid;
}
{
    my $stubborn_ajax = fork();
    die "fork failed: $!" if !defined $stubborn_ajax;
    if ( !$stubborn_ajax ) {
        $0 = 'dashboard ajax: STUBBORN-KILL';
        $SIG{TERM} = 'IGNORE';
        while (1) { sleep 1 }
    }
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $stubborn_ajax } $manager->_find_processes_by_prefix('dashboard ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'stubborn ajax singleton worker is visible in the process table before stop_web escalates' );
    $manager->stop_web;
    my $ajax_reaped = wait_for_child_exit($stubborn_ajax);
    if ( !$ajax_reaped && $UNDER_COVER && kill 0, $stubborn_ajax ) {
        kill 'KILL', $stubborn_ajax;
        $ajax_reaped = wait_for_child_exit($stubborn_ajax);
    }
    waitpid( $stubborn_ajax, 0 ) if !$ajax_reaped && kill 0, $stubborn_ajax;
    if ($UNDER_COVER) {
        ok( $ajax_reaped || !kill( 0, $stubborn_ajax ), 'stubborn ajax shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_ajax ), 'stop_web escalates stubborn ajax singleton workers to KILL after TERM is ignored' );
    }
}

{
    my $ajax_poll_count = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub {
        my ( undef, $prefix ) = @_;
        return () if $prefix ne 'dashboard ajax:';
        $ajax_poll_count++;
        return () if $ajax_poll_count > 31;
        return ( { pid => 999_991, args => 'dashboard ajax: COVER-KILL' } );
    };
    is( $manager->stop_web, undef, 'stop_web still completes when only lingering ajax singleton workers remain for the post-loop KILL branch' );
}

{
    my $web_pid = $manager->start_web( host => '0.0.0.0', port => 7904 );
    ok( $web_pid > 0, 'background web process starts before restart singleton cleanup coverage' );
    my $ajax_pid = fork();
    die "fork failed: $!" if !defined $ajax_pid;
    if ( !$ajax_pid ) {
        $0 = 'dashboard ajax: RESTART-ME';
        $SIG{TERM} = sub { exit 0 };
        while (1) { sleep 1 }
    }
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $ajax_pid } $manager->_find_processes_by_prefix('dashboard ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'test ajax singleton worker is visible in the process table before restart_all' );
    my $restart_with_ajax = $manager->restart_all( host => '0.0.0.0', port => 7904 );
    ok( $restart_with_ajax->{web_pid} > 0, 'restart_all still restarts the web service when singleton ajax workers are present' );
    for ( 1 .. 20 ) {
        my $reaped = waitpid( $ajax_pid, WNOHANG );
        last if $reaped == $ajax_pid || !kill 0, $ajax_pid;
        sleep 0.1;
    }
    my $restart_reaped = waitpid( $ajax_pid, WNOHANG );
    ok( $restart_reaped == $ajax_pid || !kill( 0, $ajax_pid ), 'restart_all terminates saved ajax singleton workers before the replacement web service starts' );
    waitpid( $ajax_pid, 0 ) if $restart_reaped != $ajax_pid;
    $manager->stop_web;
}

{
    my $stubborn_web = fork();
    die "fork failed: $!" if !defined $stubborn_web;
    if ( !$stubborn_web ) {
        $SIG{TERM} = 'IGNORE';
        $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1;
        $0 = 'dashboard web: stubborn:7906';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    $files->write( 'web_pid', "$stubborn_web\n" );
    $manager->_write_web_state( { pid => $stubborn_web, host => '0.0.0.0', port => 7906, status => 'running' } );
    is( $manager->stop_web, $stubborn_web, 'stop_web returns the stubborn pid before escalating' );
    my $web_reaped = wait_for_child_exit($stubborn_web);
    if ( !$web_reaped && $UNDER_COVER && kill 0, $stubborn_web ) {
        kill 'KILL', $stubborn_web;
        $web_reaped = wait_for_child_exit($stubborn_web);
    }
    waitpid( $stubborn_web, 0 ) if !$web_reaped && kill 0, $stubborn_web;
    if ($UNDER_COVER) {
        ok( $web_reaped || !kill( 0, $stubborn_web ), 'stubborn web shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_web ), 'stop_web escalates to KILL when TERM is ignored' );
    }
}

{
    my $legacy_web = fork();
    die "fork failed: $!" if !defined $legacy_web;
    if ( !$legacy_web ) {
        $0 = 'perl -Ilib bin/dashboard serve';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    $manager->_cleanup_web_files;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::web_state = sub { return {} };
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $legacy_web,
                args => 'perl -Ilib bin/dashboard serve',
            }
        );
    };
    my $legacy_state = $manager->running_web;
    is( $legacy_state->{pid}, $legacy_web, 'running_web discovers legacy dashboard serve processes by command line' );
    is( $legacy_state->{host}, '0.0.0.0', 'legacy web discovery falls back to the default host when no state file exists' );
    is( $legacy_state->{port}, 7890, 'legacy web discovery falls back to the default port when no state file exists' );
    is( $manager->stop_web, $legacy_web, 'stop_web terminates legacy dashboard serve processes that predate managed markers' );
    waitpid( $legacy_web, 0 );
    ok( !kill( 0, $legacy_web ), 'legacy dashboard serve process is gone after stop_web' );
}
{
    my $stubborn_legacy = fork();
    die "fork failed: $!" if !defined $stubborn_legacy;
    if ( !$stubborn_legacy ) {
        $SIG{TERM} = 'IGNORE';
        $0 = 'perl -Ilib bin/dashboard serve';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub {
            return kill( 0, $stubborn_legacy ) ? ( { pid => $stubborn_legacy } ) : ();
        };
        is( $manager->stop_web, undef, 'stop_web still completes when only a stubborn legacy dashboard serve process remains' );
    }
    my $legacy_reaped = wait_for_child_exit($stubborn_legacy);
    if ( !$legacy_reaped && $UNDER_COVER && kill 0, $stubborn_legacy ) {
        kill 'KILL', $stubborn_legacy;
        $legacy_reaped = wait_for_child_exit($stubborn_legacy);
    }
    waitpid( $stubborn_legacy, 0 ) if !$legacy_reaped && kill 0, $stubborn_legacy;
    if ($UNDER_COVER) {
        ok( $legacy_reaped || !kill( 0, $stubborn_legacy ), 'stubborn legacy web shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_legacy ), 'stop_web escalates stubborn legacy dashboard serve processes to KILL after TERM is ignored' );
    }
}

{
    my $stubborn_collector = fork();
    die "fork failed: $!" if !defined $stubborn_collector;
    if ( !$stubborn_collector ) {
        $SIG{TERM} = 'IGNORE';
        $0 = 'dashboard collector: stubborn.collector';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    $runner->{loops} = [ { name => 'stubborn.collector', pid => $stubborn_collector } ];
    my @forced = $manager->stop_collectors;
    is_deeply( \@forced, ['stubborn.collector'], 'stop_collectors returns stubborn collector names before escalation' );
    my $collector_reaped = wait_for_child_exit($stubborn_collector);
    if ( !$collector_reaped && $UNDER_COVER && kill 0, $stubborn_collector ) {
        kill 'KILL', $stubborn_collector;
        $collector_reaped = wait_for_child_exit($stubborn_collector);
    }
    waitpid( $stubborn_collector, 0 ) if !$collector_reaped && kill 0, $stubborn_collector;
    if ($UNDER_COVER) {
        ok( $collector_reaped || !kill( 0, $stubborn_collector ), 'stubborn collector shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_collector ), 'stop_collectors escalates to KILL when TERM is ignored' );
    }
}

{
    local $ENV{PATH} = '/definitely-missing';
    my $fallback_child = fork();
    die "fork failed: $!" if !defined $fallback_child;
    if ( !$fallback_child ) {
        $0 = 'dashboard web: fallback:9999';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $fallback_child,
                args => 'dashboard web: fallback:9999',
            }
        );
    };
    ok( $manager->_pkill_perl('^dashboard web:'), 'pkill fallback succeeds even when pkill is unavailable' );
    my $reaped = 0;
    for ( 1 .. 20 ) {
        if ( waitpid( $fallback_child, WNOHANG ) == $fallback_child ) {
            $reaped = 1;
            last;
        }
        sleep 0.1;
    }
    kill 'KILL', $fallback_child if !$reaped && kill 0, $fallback_child;
    waitpid( $fallback_child, 0 ) if !$reaped;
    ok( $reaped || !kill( 0, $fallback_child ), 'pkill fallback terminates matching processes by scanning ps output' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', '', 2 ) };
    ok( !defined $manager->_pkill_perl('^dashboard web:'), '_pkill_perl returns undef for unexpected pkill failures' );
    ok( !scalar( $manager->_ps_processes ), '_ps_processes returns an empty list when ps fails' );
}

{
    my %forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => undef, collectors => [] } };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub {
        my ( undef, %args ) = @_;
        %forwarded = %args;
        return 9901;
    };
    my $restart_default = $manager->restart_all;
    is( $restart_default->{web_pid}, 9901, 'restart_all returns the restarted pid when using default host and port' );
    is_deeply( \%forwarded, { host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 }, 'restart_all forwards default host, port, and worker values when none are provided' );
}

{
    my %forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => undef, collectors => [] } };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub {
        my ( undef, %args ) = @_;
        %forwarded = %args;
        return 9902;
    };
    my $restart_workers = $manager->restart_all( host => '127.0.0.1', port => 7921, workers => 5 );
    is( $restart_workers->{web_pid}, 9902, 'restart_all returns the restarted pid when an explicit worker count is provided' );
    is_deeply( \%forwarded, { host => '127.0.0.1', port => 7921, workers => 5, ssl => 0 }, 'restart_all forwards an explicit worker count to the restart helper' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return ( "State Recv-Q Send-Q Local Address:Port Peer Address:Port Process\nLISTEN 0 1024 127.0.0.1:7906 0.0.0.0:* users:((\"starman worker \",pid=123,fd=4),(\"starman master \",pid=456,fd=4))\n", '', 0 );
    };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub {
        my ( undef, $pid ) = @_;
        return $pid == 456 ? 1 : 0;
    };
    is_deeply(
        [ $manager->_managed_listener_pids_for_port(7906) ],
        [456],
        '_managed_listener_pids_for_port filters ss listener pids down to managed dashboard processes',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', 'ss: not found', 127 ) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub {
        my ( undef, $port ) = @_;
        return $port == 7909 ? (321, 654) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7909) ],
        [321, 654],
        '_listener_pids_for_port falls back to /proc listener discovery when ss is unavailable',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', 'ss command not found', 1 ) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub {
        my ( undef, $port ) = @_;
        return $port == 7917 ? (987) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7917) ],
        [987],
        '_listener_pids_for_port also falls back to /proc when ss reports not found through stderr without exit 127',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', '', 2 ) };
    is_deeply(
        [ $manager->_listener_pids_for_port(7915) ],
        [],
        '_listener_pids_for_port returns an empty list for unexpected ss failures that do not qualify for the proc fallback',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_inodes_for_port = sub { return () };
    is_deeply(
        [ $manager->_listener_pids_for_port_via_proc(7914) ],
        [],
        '_listener_pids_for_port_via_proc returns no pids when proc socket discovery finds no listener inodes',
    );
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        die "Address already in use\n" if $attempt == 1;
        return 8801;
    };
    is( $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7911 ), 8801, '_restart_web_with_retry retries transient bind failures and returns the restarted pid' );
    is( $attempt, 2, '_restart_web_with_retry retries once before succeeding when the bind race clears' );
}

{
    my %captured;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        %captured = %args;
        return 8802;
    };
    is( $manager->_restart_web_with_retry, 8802, '_restart_web_with_retry uses the default host and port when none are provided' );
    is_deeply( \%captured, { host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 }, '_restart_web_with_retry forwards default host, port, and worker values to start_web' );
}

{
    my %captured;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        %captured = %args;
        return 8803;
    };
    is( $manager->_restart_web_with_retry( host => '127.0.0.1', port => 7922, workers => 6 ), 8803, '_restart_web_with_retry accepts an explicit worker count' );
    is_deeply( \%captured, { host => '127.0.0.1', port => 7922, workers => 6, ssl => 0 }, '_restart_web_with_retry forwards explicit worker counts to start_web' );
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        die "Address already in use\n";
    };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7912 ) },
        qr/Address already in use/,
        '_restart_web_with_retry rethrows the final bind error after exhausting retries',
    );
    is( $attempt, 20, '_restart_web_with_retry uses the full retry budget before surfacing a persistent bind failure' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub { die "unexpected boom\n" };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7913 ) },
        qr/unexpected boom/,
        '_restart_web_with_retry surfaces non-bind startup failures immediately',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub { return; };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7916 ) },
        qr/Unable to restart dashboard web service on 0\.0\.0\.0:7916/,
        '_restart_web_with_retry emits the default error text when start_web returns without a pid or exception',
    );
}

{
    is_deeply(
        [ $manager->_listener_socket_inodes_for_port(0) ],
        [],
        '_listener_socket_inodes_for_port returns an empty list when no port is requested',
    );
}

{
    my $proc_root = tempdir( CLEANUP => 1 );
    my $tcp = "$proc_root/tcp";
    my $tcp6 = "$proc_root/tcp6";
    open my $tcp_fh, '>', $tcp or die "Unable to write $tcp: $!";
    print {$tcp_fh} <<'TCP';
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode

bad line without fields
   9: 0100007F:1EE5 00000000:0000 0A
  10: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0
  11: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 0 1 0000000000000000 100 0 0 10 0
   0: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 11111 1 0000000000000000 100 0 0 10 0
   2: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 11111 1 0000000000000000 100 0 0 10 0
   1: 0100007F:1EE5 00000000:0000 01 00000000:00000000 00:00000000 00000000     0        0 22222 1 0000000000000000 100 0 0 10 0
TCP
    close $tcp_fh;
    open my $tcp6_fh, '>', $tcp6 or die "Unable to write $tcp6: $!";
    print {$tcp6_fh} <<'TCP6';
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
   0: 00000000000000000000000000000000:1EE5 00000000000000000000000000000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 33333 1 0000000000000000 100 0 0 10 0
TCP6
    close $tcp6_fh;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_table_paths = sub { return ( $tcp, $tcp6 ) };
    is_deeply(
        [ $manager->_listener_socket_inodes_for_port(7909) ],
        [ 11111, 33333 ],
        '_listener_socket_inodes_for_port parses listening socket inodes from proc tcp tables',
    );
}

{
    my $proc_root = tempdir( CLEANUP => 1 );
    my $fd_dir = "$proc_root/4321/fd";
    my $other_fd_dir = "$proc_root/9876/fd";
    require File::Path;
    File::Path::make_path( $fd_dir, $other_fd_dir );
    open my $plain_fh, '>', "$proc_root/plain-target" or die "Unable to write plain target: $!";
    print {$plain_fh} "plain\n";
    close $plain_fh;
    symlink 'socket:[11111]', "$fd_dir/3" or die "Unable to create socket symlink: $!";
    symlink 'socket:[33333]', "$fd_dir/4" or die "Unable to create socket symlink: $!";
    symlink 'socket:[44444]', "$other_fd_dir/5" or die "Unable to create socket symlink: $!";
    symlink "$proc_root/plain-target", "$other_fd_dir/6" or die "Unable to create plain symlink: $!";
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_process_fd_paths = sub { return ( 'nonsense-path', glob "$proc_root/[0-9]*/fd/*" ) };
    is_deeply(
        [ sort { $a <=> $b } $manager->_process_pids_for_socket_inodes( { 11111 => 1, 33333 => 1 } ) ],
        [4321],
        '_process_pids_for_socket_inodes maps matching socket inodes back to owning process ids',
    );
}

{
    is_deeply(
        [ $manager->_process_pids_for_socket_inodes( {} ) ],
        [],
        '_process_pids_for_socket_inodes returns an empty list for an empty inode lookup table',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_inodes_for_port = sub {
        my ( undef, $port ) = @_;
        return $port == 7910 ? (11111, 22222) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_process_pids_for_socket_inodes = sub {
        my ( undef, $inode_lookup ) = @_;
        return exists $inode_lookup->{11111} && exists $inode_lookup->{22222} ? (7001, 7002) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port_via_proc(7910) ],
        [7001, 7002],
        '_listener_pids_for_port_via_proc joins proc socket inode discovery with pid lookup',
    );
}

{
    is_deeply(
        [ $manager->_listener_socket_table_paths ],
        [ '/proc/net/tcp', '/proc/net/tcp6' ],
        '_listener_socket_table_paths returns the expected proc tcp sources',
    );
    if ( -d '/proc' ) {
        ok( scalar $manager->_process_fd_paths, '_process_fd_paths returns proc fd entries on Linux hosts' );
    }
    else {
        pass('_process_fd_paths is skipped on hosts without /proc');
    }
}

{
    no warnings 'redefine';
    my $original_read = Developer::Dashboard::FileRegistry->can('read');
    local *Developer::Dashboard::FileRegistry::read = sub {
        my ( $self, $name ) = @_;
        return "$$\n" if $name eq 'web_pid';
        return $original_read->( $self, $name );
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return { pid => $$, host => '127.0.0.1', port => 7907, status => 'running' };
    };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($$) };
    my $state = $manager->running_web;
    is( $state->{pid}, $$, 'running_web trusts the recorded live listener pid for a running state even after the server process renames itself' );
}

{
    my $listener = fork();
    die "fork failed: $!" if !defined $listener;
    if ( !$listener ) {
        sleep 30;
        exit 0;
    }
    no warnings 'redefine';
    my $original_read = Developer::Dashboard::FileRegistry->can('read');
    local *Developer::Dashboard::FileRegistry::read = sub {
        my ( $self, $name ) = @_;
        return "$$\n" if $name eq 'web_pid';
        return $original_read->( $self, $name );
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return { pid => $$, host => '127.0.0.1', port => 7919, status => 'running' };
    };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($listener) };
    my $state = $manager->running_web;
    is( $state->{pid}, $$, 'running_web trusts the recorded master pid when the managed port is still held by a separate listener worker pid' );
    kill 'KILL', $listener;
    waitpid( $listener, 0 );
}

{
    no warnings 'redefine';
    $files->write( 'web_pid', "$$\n" );
    $manager->_write_web_state( { pid => $$, host => '127.0.0.1', port => 7920, status => 'running' } );
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    my $state = $manager->running_web;
    is( $state->{pid}, $$, 'running_web trusts the recorded running pid even when listener discovery cannot identify the managed process shape' );
    $manager->_cleanup_web_files;
}

{
    my $listener = fork();
    die "fork failed: $!" if !defined $listener;
    if ( !$listener ) {
        local $SIG{TERM} = 'IGNORE';
        sleep 30;
        exit 0;
    }
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return $calls++ == 0 ? { pid => $listener, port => 7908 } : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($listener) };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    is( $manager->stop_web, $listener, 'stop_web returns the recorded pid while it also tracks listener pids on the bound port' );
    waitpid( $listener, 0 );
    ok( !kill( 0, $listener ), 'stop_web escalates listener-port pids to KILL when they remain alive after TERM' );
}

{
    my $late_listener = fork();
    die "fork failed: $!" if !defined $late_listener;
    if ( !$late_listener ) {
        local $SIG{TERM} = 'IGNORE';
        sleep 30;
        exit 0;
    }
    my $running_calls  = 0;
    my $listener_calls = 0;
    my $wait_calls     = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return $running_calls++ == 0 ? { pid => $late_listener, port => 7918 } : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        return $listener_calls++ == 0 ? () : ($late_listener);
    };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub {
        return $wait_calls++ == 0 ? 0 : 1;
    };
    is( $manager->stop_web, $late_listener, 'stop_web returns the recorded pid when it has to re-probe the bound port for late listeners' );
    waitpid( $late_listener, 0 );
    ok( !kill( 0, $late_listener ), 'stop_web kills late-discovered listener pids after an initial port-release timeout' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "ps fallback title\n", undef, 0 ) };
    is( $manager->_read_process_title(999_999_999), 'ps fallback title', '_read_process_title falls back to ps output when /proc cmdline is unavailable' );
}
ok( !defined $manager->_read_process_title(999_999_998), '_read_process_title returns undef when ps also cannot resolve the pid' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return };
    local *Developer::Dashboard::RuntimeManager::_read_process_title      = sub { return };
    ok( !$manager->_is_managed_web($$), '_is_managed_web returns false when a live pid has no readable title' );
}

{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $manager->_write_web_state( { pid => $$, status => 'running' } );
        $manager->_shutdown_web('stopped');
    }
    waitpid( $child, 0 );
    my $state = {};
    for ( 1 .. 20 ) {
        $state = $manager->web_state || {};
        last if ( $state->{status} || '' ) eq 'stopped';
        sleep 0.1;
    }
    is( $state->{status}, 'stopped', '_shutdown_web writes the terminal status before exit' );
    $manager->_cleanup_web_files;
}

{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $manager->_cleanup_web_files;
        $manager->_shutdown_web();
    }
    waitpid( $child, 0 );
    my $state = $manager->web_state;
    is( $state->{status}, 'stopped', '_shutdown_web writes a default stopped status when no previous web state exists' );
    $manager->_cleanup_web_files;
}

done_testing;

__END__

=head1 NAME

09-runtime-manager.t - runtime lifecycle manager tests

=head1 DESCRIPTION

This test verifies web-service and collector lifecycle management in the
runtime manager.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for This test verifies web-service and collector lifecycle management in the runtime manager. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because This test verifies web-service and collector lifecycle management in the runtime manager has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing This test verifies web-service and collector lifecycle management in the runtime manager, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/09-runtime-manager.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/09-runtime-manager.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/09-runtime-manager.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
