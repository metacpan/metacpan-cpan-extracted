package HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps::AssignTaskDeps;

use Moose::Role;

use Memoize;
use List::MoreUtils 0.428 qw(first_index indexes uniq);
use List::Util qw(first);

=head3 update_job_scheduler_ids_by_task

#TODO do this after the all batches for a single job have been passed

#DEPRACATED job_scheduler_ids_by_array

for job at jobs
  for batch at batches
    for task at tasks

=cut

sub update_job_scheduler_deps_by_task {
    my $self = shift;

    $self->app_log->info(
        'Updating task dependencies. This may take some time...');

    foreach my $job ( $self->all_schedules ) {
        next if $self->jobs->{$job}->submission_failure;
        $self->current_job($job);
        $self->batch_scheduler_ids_by_task;
    }

    ##TODO consider changing this to each schedule
    $self->update_job_deps;
}

sub batch_scheduler_ids_by_task {
    my $self = shift;

    return unless $self->jobs->{ $self->current_job }->has_deps;

    $self->batch_counter(
        $self->jobs->{ $self->current_job }->{batch_index_start} );

    my $scheduler_index = $self->process_all_batch_deps;

    while ( my ( $dep_job, $v ) = each %{$scheduler_index} ) {
        my @dep_jobs    = @{$v};
        my $dep_indices = $scheduler_index->{$dep_job};
        $self->dep_scheduler_ids_by_task( $dep_job, $dep_indices );
    }

}

has 'dep_scheduler_ids_by_task_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    clearer => 'clear_dep_scheduler_ids_by_task_cache',
);

sub dep_scheduler_ids_by_task {
    my $self        = shift;
    my $dep_job     = shift;
    my $dep_indices = shift;

    for ( my $y = 0 ; $y < scalar @{$dep_indices} ; $y++ ) {
        ##This is the current_batch_index

        my $batch_ref =
          $self->check_find_dep_indexes_cache( $self->current_job, $y );

        for ( my $z = 0 ; $z < scalar @{ $dep_indices->[$y] } ; $z++ ) {
           #This is the dependency_batch_index

            my $dep_index = $dep_indices->[$y]->[$z];
            my $dep_ref =
              $self->check_find_dep_indexes_cache( $dep_job, $dep_index );

            my $array_dep = $self->build_task_deps(
                $batch_ref->[0], $dep_ref->[0],
                $batch_ref->[1], $dep_ref->[1],
            );

            $self->push_array_deps($array_dep);
        }
    }

    $self->clean_array_deps;
}

=head3 assign_scheduler_deps

Jobs should only depend upon all jobs they need - not all jobs from the previous dep

=cut

sub assign_scheduler_deps {
    my $self               = shift;
    my $batch_scheduler_id = shift;
    my $dep_scheduler_id   = shift;
    # my $batch_task_index   = shift;
    # my $dep_task_index     = shift;

    my $array_dep = [ $batch_scheduler_id, $dep_scheduler_id, ];

    return $array_dep;
}

sub check_find_dep_indexes_cache {
    my $self  = shift;
    my $job   = shift;
    my $index = shift;

    if ( exists $self->dep_scheduler_ids_by_task_cache->{$job}->{$index} ) {
        return $self->dep_scheduler_ids_by_task_cache->{$job}->{$index};
    }
    else {
        my $scheduler_id =
          $self->jobs->{$job}->{batches}->[$index]->{scheduler_id};

        my $task_index =
          $self->jobs->{$job}->batches->[$index]->cmd_start +
          $self->jobs->{$job}->{cmd_start};

        $self->dep_scheduler_ids_by_task_cache->{$job}->{$index} =
          [ $scheduler_id, $task_index ];

        return $self->dep_scheduler_ids_by_task_cache->{$job}->{$index};
    }
}

sub push_array_deps {
    my $self      = shift;
    my $array_dep = shift;

    if ( $self->exists_array_dep( $array_dep->[0] ) ) {
        push( @{ $self->array_deps->{ $array_dep->[0] } }, $array_dep->[1] );
    }
    else {
        $self->array_deps->{ $array_dep->[0] } = [ $array_dep->[1] ];
    }
}

sub clean_array_deps {
    my $self = shift;

    while ( my ( $k, $v ) = each %{ $self->array_deps } ) {
        my @uniq = uniq( @{$v} );
        @uniq = sort @uniq;
        $self->array_deps->{$k} = \@uniq;
    }
}

=head3 update_scheduler_ids_by_array

Update the scheduler ids by the task/batch

#TODO There must be a better way to do this

=cut

sub update_scheduler_ids_by_array {
    my $self = shift;

    my $current_batch_index = $self->batch_counter - 1;

    my $index_in_batch =
      $self->index_in_batch( $self->current_job, $current_batch_index );

    if ( !defined $index_in_batch ) {
        $self->app_log->warn( "Job "
              . $self->current_job
              . " does not have an appropriate index. If you think are reaching this in error please report the issue to github.\n"
        );
        return;
    }

    my $batch_scheduler_id =
      $self->jobs->{ $self->current_job }->scheduler_ids->[$index_in_batch];

    ##IF there is no batch id, that means something went wrong with submission
    $self->current_batch->scheduler_id($batch_scheduler_id)
      if $batch_scheduler_id;
}

=head3 index_in_batch

Using job arrays each job is divided into one or batches of size self->max_array_size

max_array_size = 10
001_job.sh --array=1-10
002_job.sh --array=10-11

    self->jobs->{a_job}->all_batch_indexes

    job001 => [
        {batch_index_start => 1, batch_index_end => 10 },
        {batch_index_start => 11, batch_index_end => 20}
    ]

The index argument is zero indexed, and our counters (job_counter, batch_counter) are 1 indexed

=cut

sub index_in_batch {
    my $self  = shift;
    my $job   = shift;
    my $index = shift;

    $index++;

    my $batches = $self->jobs->{$job}->batch_indexes;
    return check_batch_index( $batches, $index );
}

memoize('check_batch_index');

sub check_batch_index {
    my $batches      = shift;
    my $search_index = shift;

    my $x = first_index {
        search_index( $_, $search_index );
    }
    @{$batches};

    return $x if defined $x;
    return undef;
}

memoize('search_index');

sub search_index {
    my $batch_index  = shift;
    my $search_index = shift;
    my $batch_start  = $batch_index->{batch_index_start};
    my $batch_end    = $batch_index->{batch_index_end};

    if ( $search_index >= $batch_start && $search_index <= $batch_end ) {
        return 1;
    }
    return undef;
}

=head3 scheduler_ids_by_batch

##DEPRACATED

=cut

sub scheduler_ids_by_batch {
    my $self = shift;

    my $scheduler_index = $self->process_batch_deps( $self->current_batch );

    my @jobs = keys %{$scheduler_index};

    my @scheduler_ids = ();

    foreach my $job (@jobs) {
        my $batch_index       = $scheduler_index->{$job};
        my $dep_scheduler_ids = $self->jobs->{$job}->scheduler_ids;

        foreach my $index ( @{$batch_index} ) {
            push( @scheduler_ids, $dep_scheduler_ids->[$index] );
        }
    }

    $self->scheduler_ids( \@scheduler_ids ) if @scheduler_ids;
}

1;
