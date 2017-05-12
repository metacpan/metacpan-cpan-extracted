package TestsFor::HPC::Runner::Slurm::Test001;
use Test::Class::Moose;
use HPC::Runner::Slurm;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use Slurp;
use Text::Diff;

our $case = "test001";

sub test_001 :Tags(samples) {
    my $test = shift;

    my $obj = HPC::Runner::Slurm->new_with_options(infile => "$Bin/example/$case.in", submit_to_slurm => 0, outdir => "$Bin/example/$case/subs", slurm_decides => 1);
    isa_ok($obj, 'HPC::Runner::Slurm');
}

sub test_002 :Tags(output) {
    my $test = shift;
    my $cwd = cwd();

    my $obj = HPC::Runner::Slurm->new_with_options(infile => "$Bin/example/$case.in", submit_to_slurm => 0, outdir => "$Bin/example/$case/subs", slurm_decides => 1);
    isa_ok($obj, 'HPC::Runner::Slurm');
    $obj->run;

my $job1 =<<EOF;
perl t/example/$case/testioselect.pl 1

perl t/example/$case/testioselect.pl 2

perl t/example/$case/testioselect.pl 3

perl t/example/$case/testioselect.pl 4

perl t/example/$case/testioselect.pl 5

perl t/example/$case/testioselect.pl 6

perl t/example/$case/testioselect.pl 7

perl t/example/$case/testioselect.pl 8

EOF

my $job2 =<<EOF;
perl t/example/$case/testioselect.pl 9

perl t/example/$case/testioselect.pl 10

EOF

    my $href = {1 => $job1, 2 => $job2};

    for(my $batch=1; $batch < $obj->batch_counter; $batch++){

    my $counter = sprintf ("%03d", $batch);
my $expected =<<EOF;
#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env
#SBATCH --job-name=$counter\_job
#SBATCH --output=$counter\_job.log



#SBATCH --cpus-per-task=4







cd $cwd
mcerunner.pl --procs 4 --infile $Bin/example/$case/subs/$counter\_job.in --outdir $Bin/example/$case/subs --logname $counter\_job --metastr ''
EOF
        my $file = slurp("$Bin/example/$case/subs/$counter"."_job.sh");
        $file =~ s/#SBATCH --output=($Bin\/example\/$case\/subs\/\w.*)\/$counter\_job.log/#SBATCH --output=$counter\_job.log/g;

        my $diff = diff \$file, \$expected;
        #is($file, $expected, "Batch $batch matches");

        $file = slurp("$Bin/example/$case/subs/$counter\_job.in");
        $expected = $href->{$batch};
        is($file, $expected, "Job file $batch matches");
    }

    ok(1);
}

sub test_003 :Tags(after){
    my $test = shift;
    my $obj = HPC::Runner::Slurm->new_with_options(infile => "$Bin/example/$case.in", submit_to_slurm => 0, outdir => "$Bin/example/$case/subs", slurm_decides => 1);
    isa_ok($obj, 'HPC::Runner::Slurm');
    $obj->run;

    is($obj->batch_counter, 3, "Batch counter is right");
    is($obj->wait, 1, "Batch counter is right");
}

1;
