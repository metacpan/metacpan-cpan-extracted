package HPC::Runner::Command::submit_jobs::Utils::Scheduler::UseBatches;

use Moose::Role;

has 'subcommand' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'execute_job',
);

has 'desc' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'batches',
);

sub build_task_deps {
    my $self               = shift;
    my $batch_scheduler_id = shift;
    my $dep_scheduler_id   = shift;
    # my $batch_task_index   = shift;
    # my $dep_task_index     = shift;

    my $array_dep = [ $batch_scheduler_id, $dep_scheduler_id, ];

    return $array_dep;
}

# sub prepare_batch_indexes {
#     my $self = shift;
#
#     return [
#         {
#             batch_index_start =>
#               $self->jobs->{ $self->current_job }->{batch_index_start},
#             batch_index_end =>
#               $self->jobs->{ $self->current_job }->{batch_index_end},
#         }
#     ];
# }

sub prepare_batch_indexes {
    my $self = shift;

    return $self->jobs->{ $self->current_job }->batch_indexes;
}

##TODO FIX THIS
sub gen_batch_index_str {
    my $self = shift;

    #TODO Check this
    my $counter = $self->batch_counter - 1;

    ## Cmds are 0 indexed
    ## The first command in a job file is 0
    # $DB::single = 2;
    my $start =
      $self->jobs->{ $self->current_job }->{batches}->[$counter]->{cmd_start};
    return "$start";
}

sub gen_counter_str {
    my $self = shift;

    my ( $batch_counter, $job_counter ) = $self->prepare_counter;
    return $batch_counter;
}

1;
