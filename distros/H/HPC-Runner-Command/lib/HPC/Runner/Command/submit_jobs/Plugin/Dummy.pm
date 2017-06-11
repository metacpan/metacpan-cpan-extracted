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

    # return if $self->use_batches;
    return unless $self->has_array_deps;

    while(my($current_task, $v) = each %{$self->array_deps}){
      my $dep_tasks = join(':', @$v);
        my $cmd =
          "scontrol update job=$current_task Dependency=afterok:$dep_tasks";
        # $self->app_log->warn($cmd);
    }
}

1;
