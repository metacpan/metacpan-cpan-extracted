package TestsFor::HPC::Runner::Command::Plugin::Test001;

use Test::Class::Moose;
use HPC::Runner::Command;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use Slurp;
use File::Slurp;

sub make_test_dir {

    my $test_dir;

    my @chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    my $string = join '', map { @chars[ rand @chars ] } 1 .. 8;

    if ( exists $ENV{'TMP'} ) {
        $test_dir = $ENV{TMP} . "/hpcrunner/$string";
    }
    else {
        $test_dir = "/tmp/hpcrunner/$string";
    }

    make_path($test_dir);
    make_path("$test_dir/script");

    chdir($test_dir);

    open( my $fh, ">$test_dir/script/test001.1.sh" );
    print $fh <<EOF;
echo "hello world from job 1" && sleep 5

echo "hello again from job 2" && sleep 5

echo "goodbye from job 3"

#TASK tags=hello,world
echo "hello again from job 3" && sleep 5

EOF

    close($fh);

    if ( can_run('git') && !-d $test_dir . "/.git" ) {
        system('git init');
        system('git add -A');
        system('git commit -m "test commit"');
    }

    return $test_dir;
}

sub test_shutdown {

    my $test_dir = make_test_dir;
    chdir("$Bin");
    remove_tree($test_dir);
}

sub construct_001 {

    my $test_dir = make_test_dir;

    my $t = "$test_dir/script/test001.1.sh";
    MooseX::App::ParsedArgv->new(
        argv => [
            "execute_job",    "--infile",
            $t,               "--job_plugins",
            "Logger::Sqlite", "--job_plugins_opts",
            "submission_id=1"
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    return $test;
}

sub construct_002 {

    my $test_dir = make_test_dir;

    chdir("$test_dir");
    my $t = "$test_dir/script/test001.1.sh";
    MooseX::App::ParsedArgv->new(
        argv => [
            "submit_jobs",          "--infile",
            $t,                     "--hpc_plugins",
            "Dummy,Logger::Sqlite", "--hpc_plugins_opts",
            "clean_db=1"
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    return $test;
}

sub test_require : Tags(requires){
    require_ok('HPC::Runner::Command::watch_db');
    require_ok('HPC::Runner::Command::stats');
}

sub test_002 : Tags(prep) {

    my $test_dir = make_test_dir;

    ok(1);
}

sub test_003 : Tags(submit_jobs) {

    my $test = construct_002();

    $test->gen_load_plugins();

    $test->execute();

    try_submission_ids($test);
    try_plugin_strings($test);
}

sub try_submission_ids {
    my $test = shift;

    my $results = $test->schema->resultset('Submission')->search();

    #while ( my $res = $results->next ) {
    #print "submitted " . $res->submission_pi . "\n";
    #print "total_processes " . $res->total_processes . "\n";
    #print "job_stats " . $res->submission_meta . "\n";
    #}

    is( $test->submission_id, 1, "Submit jobs submission id matches" );
}

sub try_plugin_strings {
    my $test = shift;

    my $plugin_str = $test->create_plugin_str;

    my $expect1 = "--job_plugins Logger::Sqlite";
    my $expect2 = "--job_plugins_opts submission_id=1";

    like( $plugin_str, qr/$expect1/, 'Plugin string matches' );
    like( $plugin_str, qr/$expect2/, 'Plugin opts matches' );
}

sub test_005 : Tags(execute_jobs) {

    $ENV{SBATCH_JOB_ID} = '1234';

    my $test = construct_001();

    $test->metastr(
'{"batch_index":"4/4","jobname":"hpcjob_001","total_jobs":1,"total_processes":4,"batch":"004","total_batches":4,"job_counter":"004","commands":1}'
    );
    $test->gen_load_plugins();

    $test->execute();
    ok(1);

    #populate_jobs($test);
    #populate_tasks($test);

    ##I don't do any actual tests here - just want to make sure it all works
    #query_related($test);
}

sub populate_jobs {
    my $test = shift;

    is( $test->submission_id, 1, 'Execute jobs submission id matches' );

    my $results = $test->schema->resultset('Job')->search();

    #while ( my $res = $results->next ) {
    #print "jobs_pi " . $res->job_pi . "\n";
    #print "start_time " . $res->start_time . "\n";
    #print "end_time " . $res->exit_time. "\n";
    #}

    is( $results->count, 1, "Correct number of jobs" );
    ok(1);
}

sub populate_tasks {
    my $test = shift;

    my $results = $test->schema->resultset('Task')->search();

    while ( my $res = $results->next ) {

        #print "tasks_pi " . $res->task_pi . "\n";
        ##print "job_fk " . $res->job_fk . "\n";
        #print "cmdpid " . $res->pid . "\n";
        #print "start_time " . $res->start_time . "\n";
        #print "exit_time " . $res->exit_time. "\n";
        #print "exit_code " . $res->exit_code. "\n";
    }

    is( $results->count, 4, "Correct number of tasks" );
    ok(1);
}

sub query_related {
    my $test = shift;

    #$ENV{DBIC_TRACE} = 1;

    $test->schema->storage->debug(1);

    my $results = $test->schema->resultset('Submission')
      ->search( {}, { 'prefetch' => { jobs => 'tasks' } } );

    $results->result_class('DBIx::Class::ResultClass::HashRefInflator');

    while ( my $res = $results->next ) {
        print "Here is a result!\n";
        print Dumper($res);
    }

    ok(1);
}

1;
