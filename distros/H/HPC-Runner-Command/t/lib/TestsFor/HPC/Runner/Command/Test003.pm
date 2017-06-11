package TestsFor::HPC::Runner::Command::Test003;

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

extends 'TestMethods::Base';

# Tests the template
# Tests for linear dependency tree
# With no jobnames specified

#TODO Add tests for global/local hpc/job directives

sub write_test_file {
    my $test_dir = shift;

    open( my $fh, ">$test_dir/script/test003.1.sh" );
    print $fh <<EOF;
#HPC partition=mypartition
echo "hello world from job 1" && sleep 5

wait

echo "hello again from job 2" && sleep 5

wait

echo "goodbye from job 3"

wait

echo "hello again from job 3" && sleep 5
EOF

    close($fh);

    close($fh);
}

sub construct {
    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t = "$test_dir/script/test003.1.sh";

    MooseX::App::ParsedArgv->new(
        argv => [ "submit_jobs", "--infile", $t, "--dry_run" ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    $test->log( $test->init_log );

    return $test;
}

sub test_003 : Tags(construct) {

    my $cwd      = getcwd();
    my $test = construct();
    my $test_dir = getcwd();

    $test->parse_file_slurm();
    $test->iterate_schedule();

    is_deeply( [ 'hpcjob_001', 'hpcjob_002', 'hpcjob_003', 'hpcjob_004' ],
        $test->schedule, 'Schedule passes' );

    chdir($cwd);
    remove_tree($test_dir);
}

# sub test_004 : Tags(submit_jobs) {
#     my $cwd      = getcwd();
#     my $test = construct();
#     my $test_dir = getcwd();
#
#     $test->parse_file_slurm();
#     $test->iterate_schedule();
#
#     ok(1);
#
#     chdir($cwd);
#     remove_tree($test_dir);
# }
#
# sub test_005 : Tags(submit_jobs) {
#     my $cwd      = getcwd();
#     my $test = construct();
#     my $test_dir = getcwd();
#
#     $test->execute();
#
#     ok(1);
#     chdir($cwd);
#     remove_tree($test_dir);
# }

1;
