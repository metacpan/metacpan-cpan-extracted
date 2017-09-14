package HPC::Runner::Command::submit_jobs::Plugin::Slurm;

use Moose::Role;
use namespace::autoclean;

use File::Temp qw/ tempfile /;
use File::Slurp;
use File::Spec;

with 'HPC::Runner::Command::submit_jobs::Plugin::Role::Log';

=head1 HPC::Runner::Command::Plugin::Scheduler::Slurm;

Use the SLURM scheduler

=cut

has 'submit_command' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'sbatch',
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

    if ( ! defined $exitcode || $exitcode != 0 ) {
        $self->log->warn("Job was not submitted successfully");
        $self->log->warn( "STDERR: " . $stderr ) if $stderr;
        $self->log->warn( "STDOUT: " . $stdout ) if $stdout;
    }

    my ($jobid) = $stdout =~ m/(\d.*)$/ if $stdout;

    if ( !$jobid ) {
        $self->job_failure;
    }
    else {
        $self->app_log->info( "Submitted job "
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
