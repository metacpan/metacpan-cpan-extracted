use strict;
use warnings;

eval {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR);
};

use Test::Most tests => 6;

BEGIN { use_ok('IPC::Open3::Callback::CommandRunner') }

use IPC::Open3::Callback::CommandRunner;

my $echo              = 'Hello World';
my $echo_result_regex = qr/^$echo[\r\n]?[\r\n]?$/;
my $command_runner    = IPC::Open3::Callback::CommandRunner->new();
my $exit_code         = $command_runner->run( "echo $echo", { out_buffer => 1 } );
is( $exit_code, 0, 'echo exit code means success' );
like( $command_runner->get_out_buffer(), $echo_result_regex, 'echo out match' );

lives_ok { $command_runner->run_or_die( "echo $echo", { out_buffer => 1 } ) } 'expected to live';
like( $command_runner->run_or_die( "echo $echo", { out_buffer => 1 } ),
    $echo_result_regex, 'run or die returns output' );

dies_ok { $command_runner->run_or_die("THIS_IS_NOT_A_COMMAND") } 'expected to die';
