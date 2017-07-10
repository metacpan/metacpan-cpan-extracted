package HPC::Runner::Command::submit_jobs::Plugin::Dummy;

use File::Temp qw/ tempfile /;
use Data::Dumper;
use IPC::Cmd qw[can_run];
use Log::Log4perl;
use File::Slurp;
use File::Spec;

use Moose::Role;

=head1 HPC::Runner::Command::submit_jobs::Plugin::Dummy;

This is just a dummy to use for testing

The first job is submitted as 1234, the next 1235, etc

=cut

=head3 template_file

actual template file

One is generated here for you, but you can always supply your own with --template_file /path/to/template

#TODO add back PBS support and add SGE support

=cut

has 'template_file' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;

        my ( $fh, $filename ) = tempfile();

        my $tt = <<EOF;
#!/bin/bash
#
#SBATCH --share
#SBATCH --job-name=[% JOBNAME %]
#SBATCH --output=[% OUT %]
[% IF job.has_account %]
#SBATCH --account=[% job.account %]
[% END %]
[% IF job.has_partition %]
#SBATCH --partition=[% job.partition %]
[% END %]
[% IF job.has_nodes_count %]
#SBATCH --nodes=[% job.nodes_count %]
[% END %]
[% IF job.has_ntasks %]
#SBATCH --ntasks=[% job.ntasks %]
[% END %]
[% IF job.has_cpus_per_task %]
#SBATCH --cpus-per-task=[% job.cpus_per_task %]
[% END %]
[% IF job.has_ntasks_per_node %]
#SBATCH --ntasks-per-node=[% job.ntasks_per_node %]
[% END %]
[% IF job.has_mem %]
#SBATCH --mem=[% job.mem %]
[% END %]
[% IF job.has_walltime %]
#SBATCH --time=[% job.walltime %]
[% END %]
[% IF ARRAY_STR %]
#SBATCH --array=[% ARRAY_STR %]
[% END %]
[% IF AFTEROK %]
#SBATCH --dependency=afterok:[% AFTEROK %]
[% END %]

[% IF MODULES %]
module load [% MODULES %]
[% END %]

[% IF job.has_conda_env %]
source activate [% job.conda_env %]
[% END %]


[% COMMAND %]

EOF

        print $fh $tt;
        return $filename;
    },
    predicate => 'has_template_file',
    clearer   => 'clear_template_file',
    documentation =>
      q{Path to Slurm template file if you do not wish to use the default}
);

=head2 attributes

=cut

has 'sched_counter' => (
    traits   => ['Counter'],
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => 1234,
    handles  => {
        inc_sched_counter   => 'inc',
        dec_sched_counter   => 'dec',
        reset_sched_counter => 'reset',
    },
);

=head2 Subroutines

=cut

=head3 submit_jobs

This is a dummy for testing - just return a value as a placeholder in job_stats

=cut

sub submit_jobs {
    my $self = shift;

    my $jobid = $self->sched_counter;
    $ENV{DUMMY_JOB_ID} = $jobid;

# my ( $exitcode, $stdout, $stderr ) = $self->submit_to_scheduler("echo \"sbatch ". $self->slurmfile . "\"");
    $self->app_log->warn( "SUBMITTING DUMMY JOB "
          . $self->slurmfile
          . "\n\tWith dummy jobid $jobid" );

    $self->inc_sched_counter;

    return $jobid;
}

=head3 update_job_deps

Update the job dependencies if using job_array (not batches)

=cut

sub update_job_deps {
    my $self = shift;

    return unless $self->has_array_deps;

    my $array_deps_file = File::Spec->catdir( $self->logdir, 'array_deps.txt' );

    foreach my $current_task ( sort keys %{ $self->array_deps } ) {
        my $v = $self->array_deps->{$current_task};

        my $dep_tasks = join( ':', @$v );
        my $cmd =
          "scontrol update job=$current_task Dependency=afterok:$dep_tasks";

# my ( $exitcode, $stdout, $stderr ) = $self->submit_to_scheduler('echo '.$cmd);
        write_file(
            $array_deps_file,
            { append => 1 },
            $current_task . "\t" . $dep_tasks . "\n"
        );

    }
}

1;
