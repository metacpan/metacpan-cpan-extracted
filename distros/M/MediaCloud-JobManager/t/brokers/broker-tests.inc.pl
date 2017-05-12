use lib qw|lib/ t/lib/|;

use Test::More;

# skip import because we might want to skip this unit test if no job broker is running
use Test::NoWarnings ();

use Proc::Background;
use File::Temp;
use File::Slurp;

use MediaCloud::JobManager;
use MediaCloud::JobManager::Job;
use MediaCloud::JobManager::Admin;
use MediaCloud::JobManager::Configuration;
use MediaCloud::JobManager::Worker;

sub _worker_process($)
{
    my $function_name = shift;

    my $command = "perl ./script/mjm_worker.pl t/lib/${function_name}.pm";
    my $opts = { 'die_upon_destroy' => 1 };

    my $proc = Proc::Background->new( $opts, $command );
    sleep( 1 );

    unless ( $proc->alive )
    {
        $proc = undef;
        die "Process '$command' failed to start.";
    }

    return $proc;
}

sub test_run_locally($)
{
    my $broker_package = shift;

    {
        my $string = 'Hello World!';
        my $result = "${broker_package}::ReverseStringWorker"->run_locally( { 'string' => $string } );
        is( $result, reverse( $string ), 'run_locally() ReverseStringWorker' );
    }

    {
        eval { "${broker_package}::FailsAlwaysWorker"->run_locally( { 'foo' => 'bar' } ); };
        ok( $@, 'run_locally() FailsAlwaysWorker' );
    }

    {
        # 1
        eval { "${broker_package}::FailsOnceWorker"->run_locally( { 'foo' => 'bar' } ); };
        ok( $@, 'run_locally() FailsOnceWorker #1' );

        # 2
        my $result = "${broker_package}::FailsOnceWorker"->run_locally( { 'foo' => 'bar' } );
        is( $result, 42, 'run_locally() FailsOnceWorker #2' );
    }
}

sub test_run_remotely($)
{
    my $broker_package = shift;

    my $proc_1 = _worker_process( "$broker_package/ReverseStringWorker" );
    my $proc_2 = _worker_process( "$broker_package/FailsAlwaysWorker" );
    my $proc_3 = _worker_process( "$broker_package/FailsOnceWorker" );

    {
        my $string = 'Hello World!';
        my $result = "${broker_package}::ReverseStringWorker"->run_remotely( { 'string' => $string } );
        is( $result, reverse( $string ), 'run_remotely() ReverseStringWorker' );
    }

    {
        eval { "${broker_package}::FailsAlwaysWorker"->run_remotely( { 'foo' => 'bar' } ); };
        ok( $@, 'run_remotely() FailsAlwaysWorker' );
    }

    {
        # 1
        eval { "${broker_package}::FailsOnceWorker"->run_remotely( { 'foo' => 'bar' } ); };
        ok( $@, 'run_remotely() FailsOnceWorker #1' );

        # 2
        my $result = "${broker_package}::FailsOnceWorker"->run_remotely( { 'foo' => 'bar' } );
        is( $result, 42, 'run_remotely() FailsOnceWorker #2' );
    }
}

sub test_add_to_queue($)
{
    my $broker_package = shift;

    my $tempdir = File::Temp::tempdir();

    say STDERR "Tempdir: $tempdir";
    ok( -d $tempdir, 'Temporary directory exists' );

    my $proc_1 = _worker_process( "${broker_package}/ReverseStringWorker" );
    my $proc_2 = _worker_process( "${broker_package}/FailsOnceWillRetryWorker" );

    {
        my $write_results_to = $tempdir . '/ReverseStringWorker.txt';
        ok( !-f $write_results_to, 'test_add_to_queue() ReverseStringWorker result file does not exist' );

        my $string  = 'Hello World!';
        my $started = "${broker_package}::ReverseStringWorker"->add_to_queue(
            {
                'string'           => $string,
                'write_results_to' => $write_results_to
            }
        );
        ok( $started, 'add_to_queue() ReverseStringWorker job added to queue' );

        # Wait for the worker to complete the job
        sleep( 2 );

        ok( -f $write_results_to, 'add_to_queue() ReverseStringWorker result file exists' );
        is( read_file( $write_results_to ), reverse( $string ), 'add_to_queue() ReverseStringWorker result string matches' );
    }

    {
        my $write_results_to = $tempdir . '/FailsOnceWillRetryWorker.txt';
        ok( !-f $write_results_to, 'add_to_queue() FailsOnceWillRetryWorker result file does not exist' );

        my $started =
          "${broker_package}::FailsOnceWillRetryWorker"->add_to_queue( { 'write_results_to' => $write_results_to } );
        ok( $started, 'add_to_queue() FailsOnceWillRetryWorker job added to queue' );

        # Wait for worker to fail, restart and complete the job
        sleep( 2 );

        ok( -f $write_results_to, 'add_to_queue() FailsOnceWillRetryWorker result file exists' );
        is( read_file( $write_results_to ), 42, 'add_to_queue() FailsOnceWillRetryWorker result string matches' );
    }
}

sub run_tests($)
{
    my $broker_package = shift;

    test_run_locally( $broker_package );
    test_run_remotely( $broker_package );
    test_add_to_queue( $broker_package );
}

1;
