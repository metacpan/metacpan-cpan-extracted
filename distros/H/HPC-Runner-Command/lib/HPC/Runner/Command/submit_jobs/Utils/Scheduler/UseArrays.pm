package HPC::Runner::Command::submit_jobs::Utils::Scheduler::UseArrays;

use Moose::Role;

has 'subcommand' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'execute_array',
);

has 'desc' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'tasks',
);

sub build_task_deps {
    my $self               = shift;
    my $batch_scheduler_id = shift;
    my $dep_scheduler_id   = shift;
    my $batch_task_index   = shift;
    my $dep_task_index     = shift;

    my $array_dep = [
        $batch_scheduler_id . '_' . $batch_task_index,
        $dep_scheduler_id . '_' . $dep_task_index,
    ];

    return $array_dep;
}

sub prepare_batch_indexes {
    my $self = shift;

    return $self->jobs->{ $self->current_job }->batch_indexes;
}

sub gen_batch_index_str {
    my $self = shift;

    my $counter = $self->jobs->{ $self->current_job }->{cmd_start} + 1;
    return "$counter";
}

sub gen_array_str {
    my $self          = shift;
    my $batch_indexes = shift;

    my $batch_index_start = $batch_indexes->{batch_index_start} - 1;
    my $batch_index_end   = $batch_indexes->{batch_index_end} - 1;

    my $start_array =
      $self->jobs->{ $self->current_job }->{batches}->[$batch_index_start]
      ->{cmd_start} + $self->jobs->{ $self->current_job }->{cmd_start};

    my $end_array =
      $self->jobs->{$self->current_job}->batches->[$batch_index_end]->{cmd_start} +
      $self->jobs->{$self->current_job}->{cmd_start} - 1 +
      $self->jobs->{$self->current_job}->commands_per_node;

    my $array_str =
        $start_array . "-"
      . $end_array . ':'
      . $self->jobs->{ $self->current_job }->commands_per_node;

    return $array_str;
}

sub gen_counter_str {
    my $self = shift;

    my ( $batch_counter, $job_counter ) = $self->prepare_counter;
    return $job_counter;
}

1;
