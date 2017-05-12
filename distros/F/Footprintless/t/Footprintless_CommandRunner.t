use strict;
use warnings;

use Test::More tests => 19;
use Footprintless::Command qw(batch_command);
use Footprintless::Util qw(dumper slurp spurt);

BEGIN { use_ok('Footprintless::CommandRunner::IPCRun3') }
BEGIN { use_ok('Footprintless::CommandRunner::IPCRun') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

sub message {
    my ( $runner, $text ) = @_;
    my ($runner_name) = ref($runner);
    $runner_name =~ /.*::([^:]*)$/;
    return "$1 $text";
}

my $logger = Log::Any->get_logger();

foreach my $command_runner ( Footprintless::CommandRunner::IPCRun3->new(),
    Footprintless::CommandRunner::IPCRun->new() )
{

    is( $command_runner->run_or_die('echo hello'),
        "hello$/", message( $command_runner, 'echo hello' ) );

    eval { $command_runner->run_or_die('perl -e "print STDERR \"foo\";exit 42"') };
    is( $@->get_exit_code(), 42, message( $command_runner, 'expected to die' ) );

    eval {
        my $out = $command_runner->run_or_die('perl -e "print \"bar\";exit 0"');
        is( $out, 'bar', message( $command_runner, 'run_or_die returns out' ) );
    };
    ok( !$@, message( $command_runner, 'expected not to fail' ) );
}

{
    my $command_runner = Footprintless::CommandRunner::IPCRun->new();
    my $temp           = File::Temp->new();
    open( my $fh, '>', $temp );
    $command_runner->run( 'perl -e "print \"foo\";exit 0"', { out_handle => $fh } );
    close($fh);
    is( slurp($temp), 'foo', 'out_handle' );

    $temp = File::Temp->new();
    open( $fh, '>', $temp );
    $command_runner->run( 'perl -e "print STDERR \"foo\";exit 0"', { err_handle => $fh } );
    close($fh);
    is( slurp($temp), 'foo', 'err_handle' );

    $temp = File::Temp->new();
    spurt( "foo", $temp );
    open( $fh, '<', $temp );
    $command_runner->run( 'cat', { in_handle => $fh } );
    close($fh);
    is( $command_runner->get_stdout(), 'foo', 'in_handle' );
}

{
    my $command_runner = Footprintless::CommandRunner::IPCRun->new();
    my @out            = ();
    $command_runner->run(
        batch_command(
            'perl -e "print \"foo\\nbar\\n\""',
            'perl -e "print STDERR \"foobarbaz\""',
            'perl -e "print \"baz\""',
            'exit 0'
        ),
        {   out_callback => sub {
                my ($data) = @_;
                push( @out, $data );
            }
        }
    );
    is_deeply( \@out, [ 'foo', 'bar', 'baz' ], 'out_callback' );
    is( $command_runner->get_stderr(), 'foobarbaz', 'out_callback stderr' );

    my @err = ();
    $command_runner->run(
        batch_command(
            'perl -e "print STDERR \"foo\\nbar\\n\""',
            'perl -e "print \"foobarbaz\""',
            'perl -e "print STDERR \"baz\""',
            'exit 0'
        ),
        {   err_callback => sub {
                my ($data) = @_;
                push( @err, $data );
            }
        }
    );
    is_deeply( \@err, [ 'foo', 'bar', 'baz' ], 'err_callback' );
    is( $command_runner->get_stdout(), 'foobarbaz', 'err_callback stdout' );

    @out = ();
    @err = ();
    $command_runner->run(
        batch_command(
            'perl -e "print \"foo\\nbar\\n\""',
            'perl -e "print STDERR \"foo\\nbar\\n\""',
            'perl -e "print \"baz\""',
            'perl -e "print STDERR \"baz\""',
            'exit 0'
        ),
        {   out_callback => sub {
                my ($data) = @_;
                push( @out, $data );
            },
            err_callback => sub {
                my ($data) = @_;
                push( @err, $data );
            }
        }
    );
    is_deeply( \@out, [ 'foo', 'bar', 'baz' ], 'out_callback both' );
    is_deeply( \@err, [ 'foo', 'bar', 'baz' ], 'err_callback both' );
}
