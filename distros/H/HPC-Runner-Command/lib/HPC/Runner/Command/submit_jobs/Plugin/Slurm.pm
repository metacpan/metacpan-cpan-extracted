package HPC::Runner::Command::submit_jobs::Plugin::Slurm;

use Data::Dumper;
use Log::Log4perl;
use File::Temp qw/ tempfile /;
use File::Slurp;
use File::Spec;

use Moose::Role;

=head1 HPC::Runner::Command::Plugin::Scheduler::Slurm;

Use the SLURM scheduler

=cut

has 'submit_command' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'sbatch',
);

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
#!/usr/bin/env bash
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

##Application log
##There is a bug in here somewhere - this be named anything ...
has 'log' => (
    is      => 'rw',
    default => sub {
        my $self = shift;

        my $log_conf = q(
log4perl.rootLogger = DEBUG, Screen
log4perl.appender.Screen = \
  Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
  Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
  [%d] %m %n
      );
        Log::Log4perl::init( \$log_conf );
        return Log::Log4perl->get_logger();
    }
);

=head2 Subroutines

=cut

=head3 submit_jobs

Submit jobs to slurm queue using sbatch.

Format is

Submitted batch job <job_id>

Where <job_id> is just only numeric
=cut

sub submit_jobs {
    my $self = shift;

    my ( $exitcode, $stdout, $stderr ) =
      $self->submit_to_scheduler(
        $self->submit_command . " " . $self->slurmfile );

    sleep(3);

    if ( $exitcode != 0 ) {
        $self->log->fatal("Job was not submitted successfully");
        $self->log->warn( "STDERR: " . $stderr ) if $stderr;
        $self->log->warn( "STDOUT: " . $stdout ) if $stdout;
    }

    my ($jobid) = $stdout =~ m/(\d.*)$/ if $stdout;

    if ( !$jobid ) {
        $self->job_failure;
    }
    else {
        $self->log->debug( "Submited job "
              . $self->slurmfile
              . "\n\tWith Slurm jobid $jobid" );
    }

    return $jobid;
}

=head3 update_job_deps

Update the job dependencies if using job_array (not batches)

=cut

sub update_job_deps {
    my $self = shift;

    return unless $self->has_array_deps;

    my $array_deps_file = File::Spec->catdir( $self->logdir, 'array_deps.tsv' );
    my $array_log_file  = File::Spec->catdir( $self->logdir, 'array_deps.log' );

    while ( my ( $current_task, $v ) = each %{ $self->array_deps } ) {
        my $dep_tasks = join( ':', @{$v} );
        my $cmd =
          "scontrol update job=$current_task depend=afterok:$dep_tasks";

        my ( $exitcode, $stdout, $stderr ) = $self->submit_to_scheduler($cmd);
        write_file(
            $array_deps_file,
            { append => 1 },
            $current_task . "\t" . $dep_tasks . "\n"
        );

        my $info =
            "Task Deps:\t"
          . $current_task . "\t"
          . $dep_tasks . "\n"
          . "ExitCode: $exitcode\n";
        $info .= "Stderr: $stderr\n" if $stderr;
        $info .= "Stdout: $stdout\n" if $stdout;

        write_file( $array_log_file, {append => 1}, $info );
    }
}

1;
