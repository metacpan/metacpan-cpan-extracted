use strict;
use warnings;

use lib 't/lib';

use Config::Entities;
use Footprintless::CommandRunner::Mock;
use Footprintless::Util qw(
    factory
);
use Test::More tests => 23;

BEGIN { use_ok('Footprintless::Service') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $last_command;
my $last_runner_options;
my $command_runner = Footprintless::CommandRunner::Mock->new(
    sub {
        ( $last_command, $last_runner_options ) = @_;
        return 0;
    }
);

{
    my $service = Footprintless::Service->new(
        factory(
            {   service => {
                    command  => '/opt/foo/bar.sh',
                    pid_file => '/var/run/bar/bar.pid'
                }
            },
            command_runner => $command_runner
        ),
        'service'
    );
    $service->start();
    is( $command_runner->get_command(), '/opt/foo/bar.sh start', 'start' );
    $service->status();
    is( $command_runner->get_command(), '/opt/foo/bar.sh status', 'status' );
    $service->stop();
    is( $command_runner->get_command(), '/opt/foo/bar.sh stop', 'stop' );
    $service->kill();
    is( $command_runner->get_command(), '/opt/foo/bar.sh kill', 'kill' );
    $service->execute('foo');
    is( $command_runner->get_command(), '/opt/foo/bar.sh foo', 'foo' );
}

{
    my $service = Footprintless::Service->new(
        factory(
            {   service => {
                    actions => {
                        kill   => { command_args => "stop -kill" },
                        start  => { command_args => "start -debug" },
                        status => { command_args => "status -down" },
                        stop   => { command_args => "stop -polite" },
                    },
                    command  => '/opt/foo/bar.sh',
                    pid_file => '/var/run/bar/bar.pid'
                }
            },
            command_runner => $command_runner
        ),
        'service'
    );
    $service->start();
    is( $command_runner->get_command(), '/opt/foo/bar.sh start -debug', 'start -debug' );
    $service->status();
    is( $command_runner->get_command(), '/opt/foo/bar.sh status -down', 'status -down' );
    $service->stop();
    is( $command_runner->get_command(), '/opt/foo/bar.sh stop -polite', 'stop -polite' );
    $service->kill();
    is( $command_runner->get_command(), '/opt/foo/bar.sh stop -kill', 'kill (stop -kill)' );
}

{
    my $service = Footprintless::Service->new(
        factory(
            {   service => {
                    command => '/opt/foo/bar.sh',
                    actions => {
                        kill   => { use_pid => 1 },
                        start  => { use_pid => 1 },
                        status => { use_pid => 1 },
                        stop   => { use_pid => 1 },
                    },
                    pid_file => '/var/run/bar/bar.pid'
                }
            },
            command_runner => $command_runner
        ),
        'service'
    );
    eval { $service->start() };
    is( $@->get_message(), 'use_pid not supported for [start]', 'use_pid start' );
    $service->status();
    is( $command_runner->get_command(),
        'kill -0 $(cat /var/run/bar/bar.pid) 2> /dev/null && echo \'/opt/foo/bar.sh is running\' || echo \'/opt/foo/bar.sh is stopped\'',
        'use_pid status'
    );
    eval { $service->stop() };
    is( $@->get_message(), 'use_pid not supported for [stop]', 'use_pid stop' );
    $service->kill();
    is( $command_runner->get_command(), 'kill -KILL $(cat /var/run/bar/bar.pid)',
        'use_pid kill' );
}

{
    my $service = Footprintless::Service->new(
        factory(
            {   service => {
                    command => '/opt/foo/bar.sh',
                    actions => {
                        kill   => { command => '/foo/kill' },
                        start  => { command => '/foo/start' },
                        status => { command => '/foo/status' },
                        stop   => { command => '/foo/stop' }
                    },
                    pid_file => '/var/run/bar/bar.pid'
                }
            },
            command_runner => $command_runner
        ),
        'service',
    );
    $service->start();
    is( $command_runner->get_command(), '/foo/start', '/foo/start' );
    $service->status();
    is( $command_runner->get_command(), '/foo/status', '/foo/status' );
    $service->stop();
    is( $command_runner->get_command(), '/foo/stop', '/foo/stop' );
    $service->kill();
    is( $command_runner->get_command(), '/foo/kill', '/foo/kill' );
}

{
    my $command_options_factory =
        Footprintless::CommandOptionsFactory->new( default_ssh => 'ssh' );
    my $service = Footprintless::Service->new(
        factory(
            {   hostname      => 'bar',
                sudo_username => 'foobar',
                service       => {
                    'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                    command                     => '/opt/foo/bar.sh',
                    pid_file                    => '/var/run/bar/bar.pid'
                }
            },
            command_runner          => $command_runner,
            command_options_factory => $command_options_factory
        ),
        'service'
    );
    $service->start();
    is( $command_runner->get_command(),
        'ssh bar "sudo -u foobar /opt/foo/bar.sh start"',
        'ssh sudo start'
    );
    $service->status();
    is( $command_runner->get_command(),
        'ssh bar "sudo -u foobar /opt/foo/bar.sh status"',
        'ssh sudo status'
    );
    $service->stop();
    is( $command_runner->get_command(),
        'ssh bar "sudo -u foobar /opt/foo/bar.sh stop"',
        'ssh sudo stop'
    );
    $service->kill();
    is( $command_runner->get_command(),
        'ssh bar "sudo -u foobar /opt/foo/bar.sh kill"',
        'ssh sudo kill'
    );
}

{
    my $service = Footprintless::Service->new(
        factory(
            {   service => {
                    command => '/opt/foo/bar.sh',
                    actions => {
                        kill   => { command => '/foo/kill' },
                        start  => { command => '/foo/start' },
                        status => { command => '/foo/status' },
                        stop   => { command => '/foo/stop' }
                    },
                    pid_file => '/var/run/bar/bar.pid'
                }
            },
            command_runner => $command_runner
        ),
        'service',
    );
    $service->start( runner_options => { foo => 'bar' } );
    is( $last_runner_options->{foo}, 'bar', 'runner_options foo' );
}
