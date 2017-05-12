package HPC::Runner::Command::execute_job::Base;

use Moose::Role;

with 'HPC::Runner::Command::execute_job::Utils::Log';
use Sys::Hostname;

=head3 job_scheduler_id

Job Scheduler ID running the script. Passed to slurm for mail information

=cut

has 'job_scheduler_id' => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => sub {
        my $self = shift;
        my $scheduler_id =  $ENV{SLURM_JOB_ID} || $ENV{SBATCH_JOB_ID} || $ENV{PBS_JOBID} || '';
        if($self->can('task_id') && $self->task_id){
          $scheduler_id = $scheduler_id . '_'.$self->task_id;
        }
        return $scheduler_id;
    },
    lazy => 1,
    documentation =>
q{This defaults to your current Job Scheduler ID. Ignore this if running on a single node},
    predicate => 'has_job_scheduler_id',
    clearer   => 'clear_job_scheduler_id',
);

has 'hostname' => (
  is => 'rw',
  isa => 'Str|Undef',
  default => sub {
    return hostname;
  },
);

has 'wait' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'counter' => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 1,
    handles  => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset',
    },
);

has 'jobref' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [ [] ] },
);

1;
