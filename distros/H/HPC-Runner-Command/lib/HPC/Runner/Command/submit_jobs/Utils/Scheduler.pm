package HPC::Runner::Command::submit_jobs::Utils::Scheduler;

use File::Path qw(make_path);
use File::Temp qw/ tempfile /;
use IO::Select;
use Cwd;
use IPC::Open3;
use Symbol;
use Template;

use DBM::Deep;
use Storable qw(dclone);

use Text::ASCIITable;
use Memoize;
use List::MoreUtils qw(first_index);

use MooseX::App::Role;

use HPC::Runner::Command::Utils::Traits qw(ArrayRefOfStrs);

with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ParseInput';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Files';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Directives';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Submit';
with 'HPC::Runner::Command::submit_jobs::Utils::Log';
with
'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps::AssignTaskDeps';

use HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobStats;
use HPC::Runner::Command::submit_jobs::Utils::Scheduler::Job;

=head1 HPC::Runner::Command::submit_jobs::Utils::Scheduler


=head2 Command Line Options

#TODO Move this over to docs

=head3 config

Config file to pass to command line as --config /path/to/file. It should be a yaml or other config supplied by L<Config::Any>
This is optional. Paramaters can be passed straight to the command line

=head3 example.yml

    ---
    infile: "/path/to/commands/testcommand.in"
    outdir: "path/to/testdir"
    module:
        - "R2"
        - "shared"

=cut

=head3 infile

infile of commands separated by newline. The usual bash convention of escaping a newline is also supported.

=head4 example.in

    cmd1
    #Multiline command
    cmd2 --input --input \
    --someotherinput
    wait
    #Wait tells slurm to make sure previous commands have exited with exit status 0.
    cmd3  ##very heavy job
    newnode
    #cmd3 is a very heavy job so lets start the next job on a new node

=cut

=head3 jobname

Specify a job name, and jobs will be 001_jobname, 002_jobname, 003_jobname

Separating this out from Base - submit_jobs and execute_job have different ways of dealing with this

=cut

option 'jobname' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    default   => 'hpcjob_001',
    traits    => ['String'],
    predicate => 'has_jobname',
    handles   => {
        add_jobname     => 'append',
        clear_jobname   => 'clear',
        replace_jobname => 'replace',
        prepend_jobname => 'prepend',
        match_jobname   => 'match',
    },
    trigger => sub {
        my $self = shift;
        $self->check_add_to_jobs();
    },
    documentation =>
      q{Specify a job name, each job will be appended with its batch order},
);

=head3 max_array_size

=cut

option 'max_array_size' => (
    is      => 'rw',
    isa     => 'Int',
    default => 200,
);

=head3 use_batches

The default is to submit using job arrays.

If specified it will submit each job individually.

Example:

#HPC jobname=gzip
#HPC commands_per_node=1
gzip 1
gzip 2
gzip 3

Batches:
sbatch 001_gzip.sh
sbatch 002_gzip.sh
sbatch 003_gzip.sh

Arrays:

sbatch --array=1-3 gzip.sh

=cut

option 'use_batches' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    required => 0,
    documentation =>
q{Switch to use batches. The default is to use job arrays. Warning! This was the default way of submitting before 3.0, but is not well supported.},
);

=head3 afterok

The afterok switch in slurm. --afterok 123 will tell slurm to start this job after job 123 has completed successfully.

=cut

option 'afterok' => (
    traits   => ['Array'],
    is       => 'rw',
    required => 0,
    isa      => ArrayRefOfStrs,
    documentation =>
'afterok switch in slurm. --afterok 123,134 will tell slurm to start this job after 123,134 have exited successfully',
    default   => sub { [] },
    cmd_split => qr/,/,
    handles   => {
        all_afterok   => 'elements',
        has_afterok   => 'count',
        clear_afterok => 'clear',
        join_afterok  => 'join',
    },
);

=head3 no_submit_to_slurm

Bool value whether or not to submit to slurm. If you are looking to debug your files, or this script you will want to set this to zero.
Don't submit to slurm with --no_submit_to_slurm from the command line or
$self->no_submit_to_slurm(0); within your code

DEPRECATED - use --dry_run instead
=cut

# option 'no_submit_to_slurm' => (
#     is       => 'rw',
#     isa      => 'Bool',
#     default  => 0,
#     required => 0,
#     documentation =>
# q{Bool value whether or not to submit to slurm. If you are looking to debug your files, or this script you will want to set this to zero.},
# );

=head3 template_file

actual template file

One is generated here for you, but you can always supply your own with --template_file /path/to/template

#TODO add back PBS support and add SGE support

=cut

has 'template_file' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;

        my ( $fh, $filename ) = tempfile();

        my $tt = <<EOF;
#!/bin/bash
#
#SBATCH --share
#SBATCH --job-name=[% JOBNAME %]
#SBATCH --output=[% OUT %]
[% IF job.has_account %]
#SBATCH --account=[% job.account %]
[% END %]
[% IF job.has_account %]
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

[% COMMAND %]

EOF

        print $fh $tt;
        return $filename;
    },
    predicate => 'has_template_file',
    clearer   => 'clear_template_file',
    documentation =>
      q{Path to Slurm template file if you do not wish to use the default}
);

=head3 serial

Option to run all jobs serially, one after the other, no parallelism
The default is to use 4 procs

=cut

option 'serial' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation =>
q{Use this if you wish to run each job run one after another, with each job starting only after the previous has completed successfully},
    predicate => 'has_serial',
    clearer   => 'clear_serial'
);

=head3 use_custom

Supply your own command instead of mcerunner/threadsrunner/etc

=cut

option 'custom_command' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_custom_command',
    clearer   => 'clear_custom_command',
    required  => 0
);

=head2 Internal Attributes

=head3 scheduler_ids

Our current scheduler job dependencies

=cut

#Keep this or afterok?

has 'scheduler_ids' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str|Num]',
    default => sub { [] },
    handles => {
        all_scheduler_ids   => 'elements',
        add_scheduler_id    => 'push',
        join_scheduler_ids  => 'join',
        count_scheduler_ids => 'count',
        has_scheduler_ids   => 'count',
        clear_scheduler_ids => 'clear',
    },
);

has 'array_deps' => (
    traits  => ['Hash'],
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { return {} },
    handles => {
        has_array_deps   => 'count',
        array_dep_pairs  => 'kv',
        set_array_dep    => 'set',
        get_array_dep    => 'get',
        exists_array_dep => 'exists',
    },
);

=head3 job_stats

Object describing the number of jobs, number of batches per job, etc

=cut

has 'job_stats' => (
    is      => 'rw',
    isa     => 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobStats',
    default => sub {
        return HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobStats
          ->new();
    }
);

=head3 deps

Call as

    #HPC deps=job01,job02

=cut

has 'deps' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => ArrayRefOfStrs,
    coerce    => 1,
    predicate => 'has_deps',
    clearer   => 'clear_deps',
    required  => 0,
    trigger   => sub {
        my $self = shift;

        $self->graph_job_deps->{ $self->jobname } = $self->deps;
        $self->jobs->{ $self->jobname }->{deps} = $self->deps;

    }
);

=head3 current_job

Keep track of our currently running job

=cut

has 'current_job' => (
    is        => 'rw',
    isa       => 'Str',
    default   => '',
    required  => 0,
    predicate => 'has_current_job',
);

=head3 current_batch

Keep track of our currently batch

=cut

has 'current_batch' => (
    is       => 'rw',
    required => 0,
);

=head3 template

template object for writing slurm batch submission script

=cut

has 'template' => (
    is       => 'rw',
    required => 0,
    default  => sub {
        return Template->new( ABSOLUTE => 1, PRE_CHOMP => 1, TRIM => 1 );
    },
);

=head3 cmd_counter

keep track of the number of commands - when we get to more than commands_per_node restart so we get submit to a new node.
This is the number of commands within a batch. Each new batch resets it.

=cut

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

=head3 total_cmd_counter

=cut

has 'total_cmd_counter' => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 0,
    handles  => {
        inc_total_cmd_counter   => 'inc',
        reset_total_cmd_counter => 'reset',
    },
);

=head2 batch_counter

Keep track of how many batches we have submited to slurm

=cut

has 'batch_counter' => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 1,
    handles  => {
        inc_batch_counter   => 'inc',
        reset_batch_counter => 'reset',
    },
);

=head2 job_counter

Keep track of how many jobes we have submited to slurm

=cut

has 'job_counter' => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 1,
    handles  => {
        inc_job_counter   => 'inc',
        reset_job_counter => 'reset',
    },
);

=head3 batch

List of commands to submit to slurm

=cut

has 'batch' => (
    traits    => ['String'],
    is        => 'rw',
    isa       => 'Str',
    default   => q{},
    required  => 0,
    handles   => { add_batch => 'append', },
    clearer   => 'clear_batch',
    predicate => 'has_batch',
);

=head3 jobs

Contains all of our info for jobs

    {
        job03 => {
            deps => ['job01', 'job02'],
            schedulerIds => ['123.hpc.inst.edu'],
            submitted => 1/0,
            batch => 'String of whole commands',
            cmds => [
                'cmd1',
                'cmd2',
            ]
        },
        schedule => ['job01', 'job02', 'job03']
    }

=cut

has 'jobs' => (
    is      => 'rw',
    isa     => 'DBM::Deep',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $fh   = tempfile();
        my $db   = DBM::Deep->new( fh => $fh, num_txns => 2 );
        return $db;

        # return {};
    },
);

has 'jobs_current_job' => ( is => 'rw', );

=head3 graph_job_deps

Hashref of jobdeps to pass to Algorithm::Dependency

Job03 depends on job01 and job02

    { 'job03' => ['job01', 'job02'] }

=cut

has 'graph_job_deps' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    handles => {
        set_graph_job_deps    => 'set',
        get_graph_job_deps    => 'get',
        exists_graph_job_deps => 'exists',
        has_no_graph_job_deps => 'is_empty',
        num_graph_job_depss   => 'count',
        delete_graph_job_deps => 'delete',
        graph_job_deps_pairs  => 'kv',
    },
    default => sub { my $self = shift; return { $self->jobname => [] } },
);

=head2 Subroutines

=head3 Workflow

There are a lot of things happening here

parse_file_slurm #we also resolve the dependency tree and write out the batch files in here
schedule_jobs
iterate_schedule

    for $job (@scheduled_jobs)
        (set current_job)
        process_jobs
        if !use_batches
            submit_job #submit the whole job is using job arrays - which is the default
        pre_process_batch
            (current_job, current_batch)
            scheduler_ids_by_batch
            if use_batches
                submit_job
            else
                run scontrol to update our jobs by job array id

=cut

=head3 run

=cut

sub run {
    my $self = shift;

    $self->logname('slurm_logs');
    $self->check_add_to_jobs;

    #TODO add back in support for serial workflows
    if ( $self->serial ) {
        $self->procs(1);
    }

    $self->check_files;
    $self->check_jobname;

    $self->parse_file_slurm;
    $self->iterate_schedule;
}

=head3 check_jobname

Check to see if we the user has chosen the default jobname, 'job'

=cut

sub check_jobname {
    my $self = shift;

    $self->increase_jobname if $self->match_jobname(qr/^hpcjob_/);
}

=head3 check_add_to_jobs

Make sure each jobname has an entry. We set the defaults as the global configuration.

=cut

#Apply hpcjob_001 hpc_meta as globals

sub check_add_to_jobs {
    my $self = shift;

    if ( !exists $self->jobs->{ $self->jobname } ) {
        $self->jobs->{ $self->jobname } =
          HPC::Runner::Command::submit_jobs::Utils::Scheduler::Job->new(
            mem              => $self->mem,
            walltime         => $self->walltime,
            cpus_per_task    => $self->cpus_per_task,
            nodes_count      => $self->nodes_count,
            ntasks_per_nodes => $self->ntasks_per_node,
          );
        $self->jobs->{ $self->jobname }->partition( $self->partition )
          if $self->has_partition;
        $self->jobs->{ $self->jobname }->account( $self->account )
          if $self->has_account;
    }
    $self->graph_job_deps->{ $self->jobname } = [];
    if ( !exists $self->job_files->{ $self->jobname } ) {
        $self->job_files->{ $self->jobname } =
          File::Temp->new( UNLINK => 0, SUFFIX => '.dat' );
    }
    if ( !exists $self->batch_tags->{ $self->jobname } ) {
        $self->batch_tags->{ $self->jobname } = [];
    }
}

=head3 increase_jobname

Increase jobname. job_001, job_002. Used for graph_job_deps

=cut

sub increase_jobname {
    my $self = shift;

    $self->inc_job_counter;
    my $counter = $self->job_counter;

    #TODO Change this to 4
    $counter = sprintf( "%03d", $counter );

    $self->jobname( "hpcjob_" . $counter );
}

=head3 check_files

Check to make sure the outdir exists.
If it doesn't exist the entire path will be created

=cut

sub check_files {
    my ($self) = @_;

    make_path( $self->outdir ) if !-d $self->outdir;
}

=head3 iterate_schedule

Iterate over the schedule generated by schedule_jobs

=cut

sub iterate_schedule {
    my $self = shift;

    ##No batch_tags here
    return if $self->has_no_schedules;
    $self->reset_job_counter;
    $self->reset_batch_counter;

    $self->clear_scheduler_ids;
    $self->app_log->info('Beginning to submit jobs to the scheduler');

    $self->app_log->info(
        'Schedule is ' . join( ", ", @{ $self->schedule } ) . "\n" );

    foreach my $job ( $self->all_schedules ) {

        $self->app_log->info( 'Submitting all ' . $job . ' job types' );

        $self->reset_batch_counter;
        $self->current_job($job);

        $self->reset_cmd_counter;
        next unless $self->iterate_job_deps;

        $self->log_job_info;
        $self->process_jobs;
    }

    $self->update_job_scheduler_deps_by_task;

    $self->summarize_jobs;
}

=head3 iterate_job_deps

Check to see if we are actually submitting

Make sure each dep has already been submitted

Return job schedulerIds

=cut

sub iterate_job_deps {
    my $self = shift;

    $self->clear_scheduler_ids;
    my $deps = $self->graph_job_deps->{ $self->current_job };

    return unless $deps;

    my $submit_ok = 1;
    foreach my $dep ( @{$deps} ) {

        if ( $self->jobs->{$dep}->submission_failure ) {
            $self->jobs->{ $self->current_job }->submission_failure(1);
            $self->app_log->warn( 'Trying to submit job '
                  . $self->current_job
                  . ' which depends upon '
                  . $dep );
            $self->app_log->warn(
                'Job ' . $dep . ' failed, so we are skipping this submission' );
            $submit_ok = 0;
            $self->clear_scheduler_ids;
        }
        else {
            map { $self->add_scheduler_id($_) }
              $self->jobs->{$dep}->all_scheduler_ids;
        }
    }

    return $submit_ok;
}

=head3 process_jobs

=cut

sub process_jobs {
    my $self = shift;

    my $jobref = $self->jobs->{ $self->current_job };

    return if $self->jobs->{ $self->current_job }->submission_failure;
    return if $jobref->submitted;

    $self->prepare_batch_files_array;

    $self->work;
}

=head3 pre_process_batch

Log info for the job to the screen

=cut

sub log_job_info {
    my $self = shift;

    $self->app_log->info( 'There are '
          . $self->jobs->{ $self->current_job }->count_batches . ' '
          . $self->desc
          . ' for job type '
          . $self->current_job );

    $self->app_log->info( 'Submitted in '
          . $self->jobs->{ $self->current_job }->{num_job_arrays}
          . ' job arrays.'
          . "\n" )
      unless $self->use_batches;
}

=head3 work

Process the batch
Submit to the scheduler slurm/pbs/etc
Take care of the counters

=cut

sub work {
    my $self = shift;

    $self->process_batch;
    $self->clear_batch;

    $self->reset_cmd_counter;
}

=head3 process_batch

Create the slurm submission script from the slurm template
Write out template, submission job, and infile for parallel runner

=cut

#TODO think of more informative sub name
#TODO split this into process_arrays and process_batches

sub process_batch {
    my $self = shift;

    my $ok;
    $ok = $self->join_scheduler_ids(':') if $self->has_scheduler_ids;

    my $count_by = $self->prepare_batch_indexes;

    for ( my $x = 0 ; $x <= scalar @{$count_by} ; $x++ ) {
        my $batch_indexes = $count_by->[$x];
        next unless $batch_indexes;

        my $counter = $self->gen_counter_str;

        ##Create file per submission
        $self->prepare_files;

        # $DB::single = 2;
        my $array_str = '';
        $array_str = $self->gen_array_str($batch_indexes)
          if $self->can('gen_array_str');

        my $command = $self->process_submit_command($counter);

        $self->process_template( $counter, $command, $ok, $array_str );

        $self->post_process_jobs;

        $self->post_process_batch_indexes($batch_indexes);
    }
}

=head3 post_process_batch_indexes

Put the scheduler_id in each batch

=cut

sub post_process_batch_indexes {
    my $self          = shift;
    my $batch_indexes = shift;
    my $scheduler_id = $self->jobs->{ $self->current_job }->scheduler_ids->[-1];

    for (
        my $x = $batch_indexes->{batch_index_start} - 1 ;
        $x <= $batch_indexes->{batch_index_end} - 1 ;
        $x++
      )
    {
        my $batch = $self->jobs->{ $self->current_job }->batches->[$x];
        next unless $batch;
        $batch->{scheduler_id} = $scheduler_id;
    }

}

=head3 post_process_jobs

=cut

sub post_process_jobs {
    my $self = shift;

    $self->jobs->{ $self->current_job }->submitted(1);

    $self->inc_job_counter;
}

1;
