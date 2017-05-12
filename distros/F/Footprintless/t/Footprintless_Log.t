use strict;
use warnings;

use lib 't/lib';

use Config::Entities;
use File::Basename;
use File::Spec;
use File::Temp;
use Footprintless::CommandRunner::Mock;
use Footprintless::Localhost;
use Footprintless::Util qw(
    default_command_runner
    dumper
    factory
    slurp
    spurt
);
use IO::Handle;
use Test::More tests => 14;
use Time::HiRes qw(usleep);

BEGIN { use_ok('Footprintless::Log') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger   = Log::Any->get_logger();
my $test_dir = dirname( File::Spec->rel2abs($0) );

my $command_runner = Footprintless::CommandRunner::Mock->new( sub { return 0; } );
my $file = '/foo/bar/baz.log';
{
    my $log = Footprintless::Log->new(
        factory( { logs => { foo => $file } }, command_runner => $command_runner ), 'logs.foo' );
    $log->cat();
    is( $command_runner->get_command(), "cat $file", 'cat' );
    $log->cat( args => ['-n 5'] );
    is( $command_runner->get_command(), "cat -n 5 $file", 'cat "-n 5"' );
    $log->cat( args => [ '-n', '5' ] );
    is( $command_runner->get_command(), "cat -n 5 $file", 'cat "-n" "5"' );
    $log->grep( args => ["foo"] );
    is( $command_runner->get_command(), "grep foo $file", 'grep' );
    $log->tail();
    is( $command_runner->get_command(), "tail $file", 'tail' );
    $log->head();
    is( $command_runner->get_command(), "head $file", 'head' );
}

{
    my $log = Footprintless::Log->new(
        factory(
            {   hostname      => 'foo.example.com',
                logs          => { foo => $file },
                ssh           => 'ssh -t -t -q',
                sudo_username => 'foouser'
            },
            command_runner => $command_runner
        ),
        'logs.foo',
        command_runner => $command_runner
    );
    $log->cat();
    is( $command_runner->get_command(),
        "ssh -t -t -q foo.example.com \"sudo -u foouser cat $file\"",
        'cat ssh'
    );
    $log->cat( args => ['-n 5'] );
    is( $command_runner->get_command(),
        "ssh -t -t -q foo.example.com \"sudo -u foouser cat -n 5 $file\"",
        'cat ssh "-n 5"'
    );
    $log->cat( args => [ '-n', '5' ] );
    is( $command_runner->get_command(),
        "ssh -t -t -q foo.example.com \"sudo -u foouser cat -n 5 $file\"",
        'cat ssh "-n" "5"'
    );
    $log->grep( args => ["foo"] );
    is( $command_runner->get_command(),
        "ssh -t -t -q foo.example.com \"sudo -u foouser grep foo $file\"",
        'grep ssh'
    );
    $log->tail();
    is( $command_runner->get_command(),
        "ssh -t -t -q foo.example.com \"sudo -u foouser tail $file\"",
        'tail ssh'
    );
    $log->head();
    is( $command_runner->get_command(),
        "ssh -t -t -q foo.example.com \"sudo -u foouser head $file\"",
        'head ssh'
    );
}

{
    my $file     = File::Temp->new();
    my @expected = ( 'foo', 'foo', 'foo', 'bar' );
    my $pid      = fork();
    if ( $pid == 0 ) {
        $logger->debug("started child");
        open( my $handle, '>>', $file );
        foreach my $line ( @expected, 'foo' ) {
            print( $handle "$line\n" );
            usleep(250000);
        }
        close($handle);
        $logger->debug("finished child, now exit");
        exit();
    }

    $logger->debug("started parent");
    my (@out);
    Footprintless::Log->new( factory( { logs => { foo => $file->filename() } } ), 'logs.foo' )
        ->follow(
        until          => qr/^bar$/,
        runner_options => {
            out_callback => sub { push( @out, @_ ) }
        }
        );

    wait();

    is_deeply( \@out, \@expected, 'until' );
}
