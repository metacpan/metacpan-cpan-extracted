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
use File::Spec;

extends 'TestMethods::Base';

sub write_test_file {
    my $test_dir = shift;

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    my $text = <<EOF;
#HPC jobname=bowtie2

#TASK tags==Sample_1
# 1
bowtie2 Sample_1

#TASK tags==Sample_5
# 2
bowtie2 Sample_5

#HPC jobname=samtools_view
#HPC deps=bowtie2

#TASK tags==Sample_1
# 3
samtools view Sample1

#TASK tags==Sample_5
# 4
samtools view Sample_5

#HPC jobname=samtools_sort
#HPC deps=samtools_view

#TASK tags=Sample_1
# 5
samtools sort Sample_1

#TASK tags=Sample_5
# 6
samtools sort Sample_5

#HPC jobname=samtools_mpileup
#HPC deps=samtools_sort

#TASK tags=Sample_1
# 7
samtools mpileup Sample_1

#TASK tags=Sample_5
# 8
samtools mpileup Sample_5

#HPC jobname=tabix_index
#HPC deps=samtools_mpileup

#TASK tags=Sample_1
# 9
tabix Sample_1

#TASK tags=Sample_5
# 10
tabix Sample_5

#HPC jobname=bcftools_stats
#HPC deps=tabix_index

#TASK tags=Sample_1
# 11
bcftools stats Sample_1

#TASK tags=Sample_5
# 12
bcftools stats Sample_5

#HPC jobname=bcftools_filter
#HPC deps=tabix_index

#TASK tags=Sample_1
# 13
bcftools filter Sample_1

#TASK tags=Sample_5
bcftools filter Sample_5

#HPC jobname=picard_cleansam
#HPC deps=samtools_view

#TASK tags=Sample_1
# 15
picard -Xmx2g CleanSam Sample_1

#TASK tags=Sample_5
picard -Xmx2g CleanSam Sample_5


#HPC jobname=picard_sortsam
#HPC deps=picard_cleansam

#TASK tags=Sample_1
# 17
picard -Xmx2g  SortSam Sample_1

#TASK tags=Sample_5
picard -Xmx2g  SortSam Sample_5

#HPC jobname=picard_markdups
#HPC deps=picard_sortsam

#TASK tags=Sample_1
# 19
picard -Xmx2g MarkDuplicates Sample_1

#TASK tags=Sample_5
picard -Xmx2g MarkDuplicates Sample_5

#HPC jobname=picard_collect_multiple_metrics
#HPC deps=picard_markdups

#TASK tags=Sample_1
# 21
picard -Xmx2g CollectMultipleMetrics Sample_1

#TASK tags=Sample_5
picard -Xmx2g CollectMultipleMetrics Sample_5

#HPC jobname=picard_add_or_replace_groups
#HPC deps=picard_markdups

#TASK tags=Sample_1
# 23
picard -Xmx2g AddOrReplaceReadGroups Sample_1

#TASK tags=Sample_5
picard -Xmx2g AddOrReplaceReadGroups Sample_5

#HPC jobname=picard_bamindex
#HPC deps=picard_add_or_replace_groups

#TASK tags=Sample_1
# 25
picard -Xmx2g BuildBamIndex Sample_1

#TASK tags=Sample_5
picard -Xmx2g BuildBamIndex Sample_5


#HPC jobname=remove_tmp
#HPC deps=picard_bamindex

#TASK tags=Sample_1
# 27
rm -rf /scratch/gencore/nov_dalma_training/resequencing/data/analysis/Sample_1/bowtie2/tmp

#TASK tags=Sample_5
rm -rf /scratch/gencore/nov_dalma_training/resequencing/data/analysis/Sample_5/bowtie2/tmp


#HPC jobname=gatk_realigner_target_creator
#HPC deps=picard_bamindex

#TASK tags=Sample_1
# 29
gatk -T RealignerTargetCreator Sample_1


#TASK tags=Sample_5
gatk -T RealignerTargetCreator Sample_5

#HPC jobname=gatk_indel_realigner
#HPC deps=gatk_realigner_target_creator

#TASK tags=Sample_1
# 31
gatk -T IndelRealigner Sample_1

#TASK tags=Sample_5
# 32
gatk -T IndelRealigner Sample_5

#HPC jobname=gatk_haplotypecaller
#HPC deps=gatk_indel_realigner

#TASK tags=Sample_1
# 33
gatk -T HaplotypeCaller Sample_1

#TASK tags=Sample_5
# 34
gatk -T HaplotypeCaller Sample_5

#HPC jobname=gatk_variantfiltration
#HPC deps=gatk_haplotypecaller

#TASK tags=Sample_1
# 35
gatk -T VariantFiltration Sample_1

#TASK tags=Sample_5
# 36
gatk -T VariantFiltration Sample_5

EOF

    write_file( $file, $text );
}

sub construct {
    my $self = shift;

    my $test_methods = TestMethods::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $file = File::Spec->catdir( $test_dir, 'script', 'test001.1.sh' );
    MooseX::App::ParsedArgv->new(
        argv => [ "submit_jobs", "--infile", $file, "--hpc_plugins", "Dummy", ]
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

    my $schedule = [
        'bowtie2',                         'samtools_view',
        'picard_cleansam',                 'picard_sortsam',
        'samtools_sort',                   'picard_markdups',
        'samtools_mpileup',                'tabix_index',
        'bcftools_filter',                 'bcftools_stats',
        'picard_add_or_replace_groups',    'picard_bamindex',
        'picard_collect_multiple_metrics', 'remove_tmp',
        'gatk_realigner_target_creator',   'gatk_indel_realigner',
        'gatk_haplotypecaller',            'gatk_variantfiltration'
    ];
    is_deeply( $schedule, $test->schedule, 'Schedule passes' );

    my $graph_deps = {
        'gatk_realigner_target_creator'   => ['picard_bamindex'],
        'picard_add_or_replace_groups'    => ['picard_markdups'],
        'picard_bamindex'                 => ['picard_add_or_replace_groups'],
        'picard_cleansam'                 => ['samtools_view'],
        'picard_sortsam'                  => ['picard_cleansam'],
        'gatk_haplotypecaller'            => ['gatk_indel_realigner'],
        'remove_tmp'                      => ['picard_bamindex'],
        'bcftools_stats'                  => ['tabix_index'],
        'samtools_sort'                   => ['samtools_view'],
        'bcftools_filter'                 => ['tabix_index'],
        'samtools_view'                   => ['bowtie2'],
        'samtools_mpileup'                => ['samtools_sort'],
        'bowtie2'                         => [],
        'tabix_index'                     => ['samtools_mpileup'],
        'gatk_indel_realigner'            => ['gatk_realigner_target_creator'],
        'gatk_variantfiltration'          => ['gatk_haplotypecaller'],
        'picard_collect_multiple_metrics' => ['picard_markdups'],
        'picard_markdups'                 => ['picard_sortsam'],
    };
    is_deeply( $graph_deps, $test->graph_job_deps, 'Dep graph passes' );

    my $array_deps = {
        '1246_25' => ['1239_11'],
        '1243_19' => ['1241_15'],
        '1247_27' => ['1245_23'],
        '1251_35' => ['1250_33'],
        '1244_21' => ['1239_11'],
        '1235_4'  => ['1234_2'],
        '1245_24' => ['1244_22'],
        '1239_12' => ['1237_8'],
        '1246_26' => ['1239_12'],
        '1251_36' => ['1250_34'],
        '1240_14' => ['1238_10'],
        '1250_34' => ['1249_32'],
        '1249_31' => ['1248_29'],
        '1242_18' => ['1241_16'],
        '1241_16' => ['1240_14'],
        '1248_29' => ['1245_23'],
        '1249_32' => ['1248_30'],
        '1243_20' => ['1241_16'],
        '1247_28' => ['1245_24'],
        '1245_23' => ['1244_21'],
        '1248_30' => ['1245_24'],
        '1237_7'  => ['1236_5'],
        '1242_17' => ['1241_15'],
        '1237_8'  => ['1236_6'],
        '1240_13' => ['1238_9'],
        '1244_22' => ['1239_12'],
        '1241_15' => ['1240_13'],
        '1239_11' => ['1237_7'],
        '1235_3'  => ['1234_1'],
        '1250_33' => ['1249_31']
    };

    is_deeply( $array_deps, $test->array_deps, 'Array Deps passes' );

    chdir($cwd);
    remove_tree($test_dir);
}

1;
