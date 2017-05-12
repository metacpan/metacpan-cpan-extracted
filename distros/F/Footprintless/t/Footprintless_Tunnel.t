use strict;
use warnings;

use Carp;
use Config::Entities;
use Footprintless::Command qw(
    command
);
use Footprintless::Localhost;
use Footprintless::Util qw(
    default_command_runner
    dumper
    factory
);
use Test::More tests => 2;

BEGIN { use_ok('Footprintless::Tunnel') }

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

SKIP: {
    $logger->info('checking ssh localhost');
    my $factory = factory(
        {   tunnel => {
                destination_hostname => 'localhost',
                destination_port     => 22,
                tunnel_hostname      => 'localhost'
            }
        },
        localhost => Footprintless::Localhost->new( none => 1 )
    );

    my $command_runner = $factory->command_runner();
    eval {
        $command_runner->run_or_die(
            command(
                'echo hello',
                $factory->command_options(
                    ssh      => 'ssh -q -o "StrictHostKeyChecking=yes"',
                    hostname => 'localhost',
                )
            ),
            { timeout => 2 }
        );
    };
    if ($@) {
        skip( "cannot ssh to localhost: $@", 1 );
    }

    my $tunnel = Footprintless::Tunnel->new( $factory, 'tunnel' );

    eval {
        my $expected = 'hello';
        $tunnel->open();
        my $tunnel_port = $tunnel->get_local_port();
        $logger->debugf( 'tunnel port: %d', $tunnel_port );
        my $actual = $command_runner->run_or_die(
            command(
                "printf '$expected'",
                $factory->command_options(
                    hostname => 'localhost',
                    ssh =>
                        "ssh -q -p $tunnel_port -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
                )
            ),
            { timeout => 2 }
        );
        is( $actual, $expected, "printf through tunnel" );
    };
    if ($@) {
        fail("printf through tunnel");
    }
    $tunnel->close();
}
