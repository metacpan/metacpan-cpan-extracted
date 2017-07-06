package HPC::Runner::Command::submit_jobs::Utils::Scheduler::Job;

use Moose;
use Moose::Util::TypeConstraints;
use HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch;
use HPC::Runner::Command::Utils::Traits qw(ArrayRefOfStrs);

with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Directives';

=head1 HPC::Runner::Command::submit_jobs::Utils::Scheduler::Job;

=cut

=head2 Attributes

=cut

has 'deps' => (
    default => sub { [] },
    traits  => ['Array'],
    is      => 'rw',
    isa     => ArrayRefOfStrs,
    handles => {
        all_deps    => 'elements',
        add_deps    => 'push',
        map_deps    => 'map',
        get_deps    => 'get',
        join_deps   => 'join',
        has_deps    => 'count',
        clear_deps  => 'clear',
        has_no_deps => 'is_empty',
    },
);

has 'cmds' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_cmds    => 'elements',
        add_cmds    => 'push',
        join_cmds   => 'join',
        count_cmds  => 'count',
        clear_cmds  => 'clear',
    },
);

has 'cmd_counter' => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 0,
    handles  => {
        inc_cmd_counter   => 'inc',
        reset_cmd_counter => 'reset',
    },
);

has 'hpc_meta' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_hpc_meta    => 'elements',
        add_hpc_meta    => 'push',
        join_hpc_meta   => 'join',
        count_hpc_meta  => 'count',
        has_hpc_meta    => 'count',
        clear_hpc_meta  => 'clear',
        has_no_hpc_meta => 'is_empty',
    },
);

has 'scheduler_ids' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_scheduler_ids    => 'elements',
        add_scheduler_ids    => 'push',
        has_scheduler_ids    => 'count',
        count_scheduler_ids  => 'count',
        has_no_scheduler_ids => 'is_empty',
    },
);

has 'lognames' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_lognames    => 'elements',
        add_lognames    => 'push',
        has_lognames    => 'count',
        count_lognames  => 'count',
        has_no_lognames => 'is_empty',
    },
);

has 'submission_failure' => (
  is => 'rw',
  isa => 'Bool',
  traits => ['Bool'],
  default => 0,
  handles => {
      no_submission_failure => 'not',
  },
);

has 'batches' => (
    traits => ['Array'],
    is     => 'rw',
    isa =>
      'ArrayRef[HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch]',
    default => sub { [] },
    handles => {
        all_batches    => 'elements',
        add_batches    => 'push',
        has_batches    => 'count',
        count_batches  => 'count',
        has_no_batches => 'is_empty',
    },
);

##Batches are groups of commands
has batch_indexes => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_batch_indexes    => 'elements',
        add_batch_indexes    => 'push',
        has_batch_indexes    => 'count',
        count_batch_indexes  => 'count',
        # has_no_batch_indexes => 'is_empty',
    },
);

has batch_index_start => (
    isa => 'Int',
    is  => 'rw',
);

has batch_index_end => (
    isa => 'Int',
    is  => 'rw',
);

has submit_by_tags => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has submitted => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    handles => {
        submit           => 'set',
        no_submit        => 'unset',
        flip_switch      => 'toggle',
        is_not_submitted => 'not',
    },
);
1;
