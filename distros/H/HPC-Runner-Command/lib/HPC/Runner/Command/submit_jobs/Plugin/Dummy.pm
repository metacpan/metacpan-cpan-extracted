package HPC::Runner::Command::submit_jobs::Plugin::Dummy;

use Moose::Role;

=head1 HPC::Runner::Command::submit_jobs::Plugin::Dummy;

This is just a dummy to use for testing

=cut

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

    return if $self->use_batches;

    return unless $self->current_batch->has_array_deps;

    foreach my $array_id ( $self->current_batch->all_array_deps ) {
        next unless $array_id;

        my $current_job = $array_id->[0];
        my $dep_job     = $array_id->[1];

        my $cmd =
          "scontrol update job=$current_job Dependency=afterok:$dep_job";
        $self->app_log->warn($cmd);
    }
}

1;
