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

extends 'TestMethods::Base';

## This tests the construction of new, submit_jobs, and execute_job

sub test_000 : Tags(require) {
    my $self = shift;

    diag("In Test001");

    require_ok('HPC::Runner::Command');
    require_ok('HPC::Runner::Command::Utils::Base');
    require_ok('HPC::Runner::Command::Utils::Log');
    require_ok('HPC::Runner::Command::Utils::Git');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Scheduler');
    require_ok('HPC::Runner::Command::submit_jobs::Utils::Log');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::Slurm');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::Dummy');
    require_ok('HPC::Runner::Command::execute_job::Utils::Log');
    require_ok('HPC::Runner::Command::execute_job');
    ok(1);
}

sub write_test_file {
    my $test_dir = shift;

    open( my $fh, ">$test_dir/script/test001.1.sh" );

    print $fh <<EOF;
echo "hello world from job 1" && sleep 5

echo "hello again from job 2" && sleep 5

echo "goodbye from job 3"

#TASK tags=hello,world
echo "hello again from job 3" && sleep 5

EOF

    close($fh);
}

sub test_001 : Tags(new) {

    MooseX::App::ParsedArgv->new( argv => [qw(new ProjectName)] );
    my $test = HPC::Runner::Command->new_with_command();
    isa_ok( $test, 'HPC::Runner::Command' );

}

sub test_002 : Tags(construction) {
    my $cwd      = getcwd();

    my $test_methods = TestMethods::Base->new();
    my $test_dir = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t = "$test_dir/script/test001.1.sh";

    MooseX::App::ParsedArgv->new( argv =>
            [ "submit_jobs", "--infile", $t, "--outdir", "$test_dir/logs", ]
    );

    my $test = HPC::Runner::Command->new_with_command();

    is( $test->outdir, "$test_dir/logs", "Outdir is logs" );
    is( $test->infile, "$t",             "Infile is ok" );
    isa_ok( $test, 'HPC::Runner::Command' );

    chdir($cwd);
    remove_tree($test_dir);
}

sub test_003 : Tags(construction) {
    my $cwd      = getcwd();
    my $test_methods = TestMethods::Base->new();
    my $test_dir = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t = "$test_dir/script/test001.1.sh";
    MooseX::App::ParsedArgv->new( argv =>
            [ "execute_job", "--infile", $t, "--batch_index_start", 1,  "--outdir", "$test_dir/logs", ]
    );
    my $test = HPC::Runner::Command->new_with_command();

    is( $test->outdir, "$test_dir/logs", "Outdir is logs" );
    is( $test->infile, "$t",             "Infile is ok" );
    isa_ok( $test, 'HPC::Runner::Command' );

    chdir($cwd);
    remove_tree($test_dir);
}

1;
