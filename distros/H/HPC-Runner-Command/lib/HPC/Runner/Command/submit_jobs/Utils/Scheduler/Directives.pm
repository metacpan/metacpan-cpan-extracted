package HPC::Runner::Command::submit_jobs::Utils::Scheduler::Directives;

use MooseX::App::Role;
use namespace::autoclean;

use BioSAILs::Utils::Traits qw(ArrayRefOfStrs);

use File::Temp qw/ tempfile /;
use File::Slurp;
use File::Spec;

=head1 HPC::Runner::Command::submit_jobs::Utils::Scheduler::Directives

=cut

=head2 Command Line Options

#TODO Move this over to docs

=cut

=head3 module

modules to load with slurm
Should use the same names used in 'module load'

Example. R2 becomes 'module load R2'

=cut

option 'module' => (
    traits        => ['Array'],
    is            => 'rw',
    isa           => ArrayRefOfStrs,
    coerce        => 1,
    required      => 0,
    documentation => q{List of modules to load ex. R2, samtools, etc},
    default       => sub { [] },
    cmd_split     => qr/,/,
    handles       => {
        has_modules  => 'count',
        all_modules  => 'elements',
        join_modules => 'join',
    },
);

=head3 conda_env

Anaconda envs to load

Load anaconda envs with

  source activate /path/to/my/env

=cut

option 'conda_env' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => q{Conda env to activate.},
    predicate => 'has_conda_env',
);

=head3 cpus_per_task

slurm item --cpus_per_task defaults to 1

=cut

option 'cpus_per_task' => (
    is            => 'rw',
    isa           => 'Int',
    required      => 0,
    default       => 4,
    predicate     => 'has_cpus_per_task',
    clearer       => 'clear_cpus_per_task',
    documentation => '--cpus-per-task switch in slurm'
);

=head3 ntasks

slurm item --ntasks defaults to 1

=cut

option 'ntasks' => (
    is        => 'rw',
    isa       => 'Int',
    required  => 0,
    default   => 1,
    predicate => 'has_ntasks',
    clearer   => 'clear_ntasks',
    documentation =>
'--ntasks switch in slurm. This is equal to the number of concurrent tasks on each node * the number of nodes, not the total number of tasks'
);

=head3 account

slurm item --account defaults to 1

=cut

option 'account' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    predicate     => 'has_account',
    clearer       => 'clear_account',
    documentation => '--account switch in slurm. '
);

=head3 account-per-node

slurm item --ntasks-per-node defaults to 28

=cut

option 'ntasks_per_node' => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
    default  => 1,
    trigger  => sub {
        my $self   = shift;
        my $ntasks = $self->ntasks_per_node * $self->nodes_count;
        $self->ntasks($ntasks);
    },
    predicate => 'has_ntasks_per_node',
    clearer   => 'clear_ntasks_per_node',
    documentation =>
      '--ntasks-per-node switch in slurm. total concurrent tasks on a node.'
);

=head3 commands_per_node

commands to run per node

=cut

#TODO Update this for job arrays

option 'commands_per_node' => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
    default  => 1,
    documentation =>
q{Commands to run on each node. If you have a low number of jobs you can submit at a time you want this number much higher. },
    predicate => 'has_commands_per_node',
    clearer   => 'clear_commands_per_node'
);

=head3 nodes_count

Number of nodes to use on a job. This is only useful for mpi jobs.

PBS:
#PBS -l nodes=nodes_count:ppn=16 this

Slurm:
#SBATCH --nodes=nodes_count

=cut

option 'nodes_count' => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
    default  => 1,
    documentation =>
q{Number of nodes requested. You should only use this if submitting parallel jobs.},
    predicate => 'has_nodes_count',
    clearer   => 'clear_nodes_count'
);

=head3 partition

Specify the partition.

In PBS this is called 'queue'

=cut

option 'partition' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => q{Slurm partition to submit jobs to.},
    predicate     => 'has_partition',
    clearer       => 'clear_partition'
);

=head3 walltime

Define scheduler walltime

=cut

option 'walltime' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    default   => '00:20:00',
    predicate => 'has_walltime',
    clearer   => 'clear_walltime,'
);

=head2 mem

=cut

option 'mem' => (
    is            => 'rw',
    isa           => 'Str|Undef',
    predicate     => 'has_mem',
    clearer       => 'clear_mem',
    required      => 0,
    default       => '10GB',
    documentation => q{Supply a memory limit},
);

=head3 user

user running the script. Passed to slurm for mail information

=cut

option 'user' => (
    is       => 'rw',
    isa      => 'Str',
    default  => sub { return $ENV{USER} || $ENV{LOGNAME} || getpwuid($<); },
    required => 1,
    documentation =>
q{This defaults to your current user ID. This can only be changed if running as an admin user}
);

=head3 procs

Total number of concurrent running tasks.

Analagous to parallel --jobs i

=cut

option 'procs' => (
    is       => 'rw',
    isa      => 'Int',
    default  => 1,
    required => 0,
    documentation =>
      q{Total number of concurrently running jobs allowed at any time.},
    trigger => sub {
        my $self = shift;
        $self->ntasks_per_node( $self->procs );
    }
);

=head3 template_file

actual template file

One is generated here for you, but you can always supply your own with
--template_file /path/to/template

Default is for SLURM

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
      q{Path to Scheduler template file if you do not wish to use the default.}
);



1;
