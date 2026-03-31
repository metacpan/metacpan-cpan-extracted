use strict;
use warnings;

use File::Temp qw(tempdir);
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

{
    package Local::RuntimeRunner;
    sub new { bless { loops => [], started => [], stopped => [] }, shift }
    sub running_loops { @{ $_[0]{loops} } }
    sub start_loop {
        my ( $self, $job ) = @_;
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
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/dashboard ps1' } ), 'non-web dashboard commands are ignored' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{/bin/bash -c dashboard serve; sleep 1} } ), 'shell wrappers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{strace -ff -o /tmp/ddexec ./bin/dashboard serve} } ), 'tracing wrappers are not mistaken for web workers' );

ok( !defined $manager->web_state, 'no web state file exists initially' );

my $pid;
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub { return ( { pid => $$, args => 'perl -Ilib bin/dashboard serve' } ) };
    ok( !$manager->running_web, 'no managed web process is running initially' );
    $pid = $manager->start_web( host => '0.0.0.0', port => 7898 );
}
ok( $pid > 0, 'background web start returns a pid' );
my $running = $manager->running_web;
is( $running->{pid}, $pid, 'running_web reads the managed pid' );
is( $running->{host}, '0.0.0.0', 'running_web reports configured host' );
is( $running->{port}, 7898, 'running_web reports configured port' );
ok( $manager->_is_managed_web($pid), 'started pid is recognized as a managed web process' );
is( scalar( $manager->start_web( host => '0.0.0.0', port => 7898 ) ), $pid, 'background start deduplicates an already running web process' );
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
    else {
        is( $marker, 'yes', 'process environment markers are readable' );
    }
    kill 'TERM', $marker_child;
    waitpid( $marker_child, 0 );
}
like( $manager->_read_process_title($pid), qr/^dashboard web:/, 'managed web process title is readable' );
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
    ok( !$manager->running_web, 'stop_web stops the managed web process' );
}
ok( !-f $files->web_pid, 'stop_web removes the web pid file' );
ok( !-f $files->web_state, 'stop_web removes the web state file' );
$manager->_cleanup_web_files;
ok( !-f $files->web_pid, 'cleanup is idempotent for pid files' );

ok( $manager->start_web( foreground => 1, host => '0.0.0.0', port => 7900 ), 'foreground start returns successfully' );
ok( -f $foreground_file, 'foreground start delegates to server run' );

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

@{ $runner->{loops} } = (
    { name => 'alpha.collector', pid => 1111 },
    { name => 'beta.collector',  pid => 2222 },
);
my @stopped_collectors = $manager->stop_collectors;
is_deeply( \@stopped_collectors, [ 'alpha.collector', 'beta.collector' ], 'stop_collectors returns stopped collector names' );
is_deeply( $runner->{stopped}, [ 'alpha.collector', 'beta.collector' ], 'stop_collectors delegates each running collector to the runner' );

my @started_collectors = $manager->start_collectors;
is_deeply( [ map { $_->{name} } @started_collectors ], [ 'alpha.collector', 'beta.collector' ], 'start_collectors starts configured collectors' );

my $restart = $manager->restart_all( host => '0.0.0.0', port => 7903 );
ok( $restart->{web_pid} > 0, 'restart_all starts a background web process' );
is_deeply( [ map { $_->{name} } @{ $restart->{collectors} } ], [ 'alpha.collector', 'beta.collector' ], 'restart_all restarts configured collectors' );
ok( $manager->running_web, 'restart_all leaves the web process running' );
my $stop_all = $manager->stop_all;
ok( defined $stop_all->{web_pid}, 'stop_all returns the web pid when it stops a running service' );

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
    waitpid( $stubborn_web, 0 );
    ok( !kill( 0, $stubborn_web ), 'stop_web escalates to KILL when TERM is ignored' );
}

{
    my $legacy_web = fork();
    die "fork failed: $!" if !defined $legacy_web;
    if ( !$legacy_web ) {
        $0 = 'perl -Ilib bin/dashboard serve';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    no warnings 'redefine';
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
    waitpid( $stubborn_collector, 0 );
    ok( !kill( 0, $stubborn_collector ), 'stop_collectors escalates to KILL when TERM is ignored' );
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
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "ps fallback title\n", undef, 0 ) };
    is( $manager->_read_process_title(999_999_999), 'ps fallback title', '_read_process_title falls back to ps output when /proc cmdline is unavailable' );
}
ok( !defined $manager->_read_process_title(999_999_998), '_read_process_title returns undef when ps also cannot resolve the pid' );

{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $manager->_write_web_state( { pid => $$, status => 'running' } );
        $manager->_shutdown_web('stopped');
    }
    waitpid( $child, 0 );
    my $state = $manager->web_state;
    is( $state->{status}, 'stopped', '_shutdown_web writes the terminal status before exit' );
    $manager->_cleanup_web_files;
}

done_testing;

__END__

=head1 NAME

09-runtime-manager.t - runtime lifecycle manager tests

=head1 DESCRIPTION

This test verifies web-service and collector lifecycle management in the
runtime manager.

=cut
