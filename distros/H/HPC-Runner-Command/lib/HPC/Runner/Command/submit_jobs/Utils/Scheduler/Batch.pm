package HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch;

use Moose;
use Moose::Util::TypeConstraints;

has batch_tags => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_batch_tags   => 'elements',
        add_batch_tags   => 'push',
        join_batch_tags  => 'join',
        has_batch_tags   => 'count',
        clear_batch_tags => 'clear',
    },
);

has 'cmd_count' => (
    is       => 'rw',
    required => 1,
);

has 'cmd_start' => (
    is => 'rw',
    required => 1,
);

has 'job' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'scheduler_id' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'scheduler_index' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { return {} },
    documentation =>
q(Get the job dependency, and the index of the job scheduler id that corresponds to that batch),
);

1;
