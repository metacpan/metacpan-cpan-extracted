package TestsFor::HPC::Runner::Command::Test001;

use Moose;
use Test::Class::Moose;
use HPC::Runner::Command;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use File::Slurp;
use File::Spec;

extends 'TestMethods::Base';

## This tests the construction of new, submit_jobs, and execute_job

sub test_000 : Tags(require) {
    my $self = shift;

    diag("In Test001");

    require_ok('HPC::Runner::Command');
    require_ok('HPC::Runner::Command::Utils::Base');
    require_ok('HPC::Runner::Command::Utils::Log');
    require_ok('HPC::Runner::Command::Utils::Git');
    require_ok('HPC::Runner::Command::Utils::Plugin');
    require_ok('HPC::Runner::Command::Utils::Traits');
    require_ok('HPC::Runner::Command::Logger::JSON');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Log');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch');
    require_ok(
        'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Directives');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler::Files');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler::Job');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobStats');
    require_ok(
        'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ParseInput');
    require_ok(
        'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler::Submit');
    require_ok(
        'HPC::Runner::Command::submit_jobs::Utils::Scheduler::UseArrays');
    require_ok(
        'HPC::Runner::Command::submit_jobs::Utils::Scheduler::UseBatches');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::Slurm');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::Dummy');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::PBS');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::SGE');
    require_ok('HPC::Runner::Command::submit_jobs::Logger::JSON');
    require_ok('HPC::Runner::Command::execute_job::Utils::Log');
    require_ok('HPC::Runner::Command::execute_job::Utils::MemProfile');
    require_ok('HPC::Runner::Command::execute_job');
    require_ok('HPC::Runner::Command::execute_job::Logger::JSON');
    require_ok('HPC::Runner::Command::execute_array');
    require_ok('HPC::Runner::Command::single_node');
    require_ok('HPC::Runner::Command::stats');
    require_ok('HPC::Runner::Command::stats::Logger::JSON::Summary');
    require_ok('HPC::Runner::Command::stats::Logger::JSON::Long');
    require_ok('HPC::Runner::Command::archive');
    ok(1);
}

sub write_test_file {
    my $test_dir = shift;

    my $text = <<EOF;
echo "hello world from job 1" && sleep 5

echo "hello again from job 2" && sleep 5

echo "goodbye from job 3"

#TASK tags=hello,world
echo "hello again from job 3" && sleep 5

EOF

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    write_file( $file, $text );
}

sub test_002 : Tags(construction) {
    my $cwd = getcwd();

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );

    MooseX::App::ParsedArgv->new( argv =>
          [ "submit_jobs", "--infile", $file, "--outdir", File::Spec->catdir($test_dir, 'logs') ] );

    my $test = HPC::Runner::Command->new_with_command();

    is( $test->outdir, File::Spec->catdir($test_dir, 'logs'), "Outdir is logs" );
    is( $test->infile, $file,             "Infile is ok" );
    isa_ok( $test, 'HPC::Runner::Command' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_003 : Tags(construction) {
    my $cwd          = getcwd();
    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    MooseX::App::ParsedArgv->new(
        argv => [
            "execute_job", "--infile",
            $file,            "--batch_index_start",
            1,             "--outdir",
            "$test_dir/logs",
        ]
    );
    my $test = HPC::Runner::Command->new_with_command();

    is( $test->outdir, File::Spec->catdir($test_dir, 'logs'), "Outdir is logs" );
    is( $test->infile, $file,             "Infile is ok" );
    isa_ok( $test, 'HPC::Runner::Command' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_004 : Tags(construction) {
    my $cwd          = getcwd();
    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    MooseX::App::ParsedArgv->new(
        argv => [ "new", "--project", "my_new_project" ] );
    my $test = HPC::Runner::Command->new_with_command();
    $test->execute;

    is( ( -d 'conf' ),       1, 'Conf dir exists' );
    is( ( -d 'script' ),     1, 'Script dir exists' );
    is( ( -d 'data' ),       1, 'Data dir exists' );
    is( ( -d 'hpc-runner' ), 1, 'Hpc-runner dir exists' );
    is( ( -d '.git' ),       1, 'Hpc-runner dir exists' );
    ok(1);

    chdir($cwd);
    remove_tree($test_dir);
}

1;
