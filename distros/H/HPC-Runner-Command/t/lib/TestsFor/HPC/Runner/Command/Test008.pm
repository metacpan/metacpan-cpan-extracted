package TestsFor::HPC::Runner::Command::Test008;

use strict;
use warnings;

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

sub write_test_file {
    my $test_dir = shift;

    my $t = "$test_dir/script/test002.1.sh";
    open( my $fh, ">$t" );
    print $fh <<EOF;

#HPC jobname=bowtie2

#TASK tags==Sample1
bowtie2 Sample_1

#TASK tags==Sample_5
bowtie2 Sample_5

#HPC jobname=samtools_view
#HPC deps=bowtie2

#TASK tags==Sample1
samtools view Sample1

#TASK tags==Sample_5
samtools view Sample_5

#HPC jobname=samtools_sort
#HPC deps=samtools_view

#TASK tags=Sample_1
samtools sort Sample_1

#TASK tags=Sample_5
samtools sort Sample_5

#HPC jobname=samtools_mpileup
#HPC deps=samtools_sort

#TASK tags=Sample_1
samtools mpileup Sample_1

#TASK tags=Sample_5
samtools mpileup Sample_5

#HPC jobname=tabix_index
#HPC deps=samtools_mpileup

#TASK tags=Sample_1
tabix Sample_1

#TASK tags=Sample_5
tabix Sample_5

#HPC jobname=bcftools_stats
#HPC deps=tabix_index

#TASK tags=Sample_1
bcftools stats Sample_1

#TASK tags=Sample_5
bcftools stats Sample_5

#HPC jobname=bcftools_filter
#HPC deps=tabix_index

#TASK tags=Sample_1
bcftools filter Sample_1

#TASK tags=Sample_5
bcftools filter Sample_5

#HPC jobname=picard_cleansam
#HPC deps=samtools_view

#TASK tags=Sample_1
picard -Xmx2g CleanSam Sample_1

#TASK tags=Sample_5
picard -Xmx2g CleanSam Sample_5


#HPC jobname=picard_sortsam
#HPC deps=picard_cleansam

#TASK tags=Sample_1
picard -Xmx2g  SortSam Sample_1

#TASK tags=Sample_5
picard -Xmx2g  SortSam Sample_5

#HPC jobname=picard_markdups
#HPC deps=picard_sortsam

#TASK tags=Sample_1
picard -Xmx2g MarkDuplicates Sample_1

#TASK tags=Sample_5
picard -Xmx2g MarkDuplicates Sample_5

#HPC jobname=picard_collect_multiple_metrics
#HPC deps=picard_markdups

#TASK tags=Sample_1
picard -Xmx2g CollectMultipleMetrics Sample_1

#TASK tags=Sample_5
picard -Xmx2g CollectMultipleMetrics Sample_5

#HPC jobname=picard_add_or_replace_groups
#HPC deps=picard_markdups

#TASK tags=Sample_1
picard -Xmx2g AddOrReplaceReadGroups Sample_1

#TASK tags=Sample_5
picard -Xmx2g AddOrReplaceReadGroups Sample_5

#HPC jobname=picard_bamindex
#HPC deps=picard_add_or_replace_groups

#TASK tags=Sample_1
picard -Xmx2g BuildBamIndex Sample_1

#TASK tags=Sample_5
picard -Xmx2g BuildBamIndex Sample_5


#HPC jobname=remove_tmp
#HPC deps=picard_bamindex

#TASK tags=Sample_1
rm -rf /scratch/gencore/nov_dalma_training/resequencing/data/analysis/Sample_1/bowtie2/tmp


#TASK tags=Sample_5
rm -rf /scratch/gencore/nov_dalma_training/resequencing/data/analysis/Sample_5/bowtie2/tmp


#HPC jobname=gatk_realigner_target_creator
#HPC deps=picard_bamindex

#TASK tags=Sample_1
gatk -T RealignerTargetCreator Sample_1


#TASK tags=Sample_5
gatk -T RealignerTargetCreator Sample_5

#HPC jobname=gatk_indel_realigner
#HPC deps=gatk_realigner_target_creator

#TASK tags=Sample_1
gatk -T IndelRealigner Sample_1

#TASK tags=Sample_5
gatk -T IndelRealigner Sample_5

#HPC jobname=gatk_haplotypecaller
#HPC deps=gatk_indel_realigner

#TASK tags=Sample_1
gatk -T HaplotypeCaller Sample_1


#TASK tags=Sample_5
gatk -T HaplotypeCaller Sample_5

#HPC jobname=gatk_variantfiltration
#HPC deps=gatk_haplotypecaller

#TASK tags=Sample_1
gatk -T VariantFiltration Sample_1

#TASK tags=Sample_5
gatk -T VariantFiltration Sample_5

#HPC jobname=gatk_haplotypecaller
#HPC deps=gatk_indel_realigner

#TASK tags=Sample_1
gatk -T HaplotypeCaller Sample_1

#TASK tags=Sample_5
gatk -T HaplotypeCaller Sample_5

EOF

    close($fh);
}

sub construct {
    my $self = shift;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $t = "$test_dir/script/test002.1.sh";
    MooseX::App::ParsedArgv->new(
        argv => [
            "submit_jobs",    "--infile",
            $t,               "--outdir",
            "$test_dir/logs", "--hpc_plugins",
            "Dummy",
        ]
    );

    my $test = HPC::Runner::Command->new_with_command();
    $test->logname('slurm_logs');
    $test->log( $test->init_log );
    return $test;
}


##TODO Add in tests for executing jobs

sub test_001 : Tags(execute_array) {

    my $cwd      = getcwd();
    my $test     = construct();
    my $test_dir = getcwd();

    my ( $source, $dep );

    $test->parse_file_slurm();
    $test->iterate_schedule();

    #diag(Dumper($test->graph_job_deps));
    #diag(Dumper($test->schedule));

    #diag(Dumper($test->jobs->{'gatk_indel_realigner'}->batches->[0]));

    #TODO
    #Create a table
    #JobType Batch# SubmitID DepJobType DepBatch

    ok(1);

    chdir($cwd);
    remove_tree($test_dir);
}

1;
