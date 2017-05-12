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

use MooseX::App::Role;

use HPC::Runner::Command::Utils::Traits qw(ArrayRefOfStrs);

with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ParseInput';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Files';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler::Directives';

use HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobStats;
use HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobDeps;

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

=cut

option 'no_submit_to_slurm' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    required => 0,
    documentation =>
q{Bool value whether or not to submit to slurm. If you are looking to debug your files, or this script you will want to set this to zero.},
);

=head3 template_file

actual template file

One is generated here for you, but you can always supply your own with --template_file /path/to/template

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
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_scheduler_ids    => 'elements',
        add_scheduler_id     => 'push',
        map_scheduler_ids    => 'map',
        filter_scheduler_ids => 'grep',
        find_scheduler_id    => 'first',
        get_scheduler_id     => 'get',
        join_scheduler_ids   => 'join',
        count_scheduler_ids  => 'count',
        has_scheduler_ids    => 'count',
        has_no_scheduler_ids => 'is_empty',
        sorted_scheduler_ids => 'sort',
        clear_scheduler_ids  => 'clear',
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

=head2 array_counter

Keep track of how many batches we have submited to slurm

=cut

has 'array_counter' => (
    traits   => ['Counter'],
    is       => 'rw',
    isa      => 'Num',
    required => 1,
    default  => 1,
    handles  => {
        inc_array_counter   => 'inc',
        reset_array_counter => 'reset',
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
        my $db   = DBM::Deep->new( fh => $fh );
        return $db;
    },
);

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
          HPC::Runner::Command::submit_jobs::Utils::Scheduler::JobDeps->new(
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

    return if $self->has_no_schedules;
    $self->reset_job_counter;
    $self->reset_batch_counter;

    $self->clear_scheduler_ids;
    $self->app_log->info('Beginning to submit jobs to the scheduler');

    $self->app_log->info(
        'Schedule is ' . join( ", ", @{ $self->schedule } ) . "\n" );

    foreach my $job ( $self->all_schedules ) {

        $self->app_log->info( 'Submitting all ' . $job . ' job types' );

        $self->current_job($job);

        $DB::single = 2;

        $self->reset_cmd_counter;
        $self->iterate_deps();

        $self->process_jobs();
    }

    $self->summarize_jobs;
}

=head3 iterate_deps

Check to see if we are actually submitting

Make sure each dep has already been submitted

Return job schedulerIds

=cut

#TODO Update this to return batch ids

sub iterate_deps {
    my $self = shift;

    my $deps = $self->graph_job_deps->{ $self->current_job };

    foreach my $dep ( @{$deps} ) {

        if (   $self->no_submit_to_slurm
            && $self->jobs->{$dep}->is_not_submitted )
        {
            die print "A cyclic dependencies found!!!\n";
        }
        else {
            map { $self->add_scheduler_id($_) }
              $self->jobs->{$dep}->all_scheduler_ids;
        }
    }
}

=head3 process_jobs

=cut

sub process_jobs {
    my $self = shift;

    my $jobref = $self->jobs->{ $self->current_job };

    if ( !$jobref->can('submitted') ) {
        warn
"You seem to be mixing and matching job dependency declarations. Here there be dragons!\n";
    }

    #TODO This should give a warning
    return if $jobref->submitted;

    $DB::single = 2;

    #If using arrays
    if ( !$self->use_batches ) {
        $self->work;
    }

    $self->pre_process_batch;

}

=head3 post_process_jobs

=cut

sub post_process_jobs {
    my $self = shift;

    $self->jobs->{ $self->current_job }->submitted(1);

    $self->inc_job_counter;

    $self->clear_scheduler_ids;
}

=head3 pre_process_batch

Go through the batch, add it, and see if we have any tags

=cut

sub pre_process_batch {
    my $self = shift;

    $DB::single = 2;
    $self->clear_batch;

    my $orig_scheduler_ids = dclone( $self->scheduler_ids );
    my @batches            = @{ $self->jobs->{ $self->current_job }->batches };

    my $desc = "batches";
    $desc = "tasks" unless $self->use_batches;
    $self->app_log->info( 'There are '
          . scalar @batches . ' '
          . $desc
          . ' for job type '
          . $self->current_job );

    $self->app_log->info( 'Submitted in '
          . $self->jobs->{ $self->current_job }->{num_job_arrays}
          . ' job arrays.'
          . "\n" )
      unless $self->use_batches;

    foreach my $batch (@batches) {
        next unless $batch;
        $self->current_batch($batch);

        if ( $self->use_batches ) {

            $DB::single = 2;
            $self->batch( $batch->batch_str );
            $self->scheduler_ids_by_batch;

            $self->work;
            $self->scheduler_ids($orig_scheduler_ids);
        }
        else {
            $self->scheduler_ids_by_array;
        }

        #Only need this for job_arrays
        $self->inc_batch_counter;

    }
}

=head3 scheduler_ids_by_batch

When defining job tags there is an extra level of dependency

=cut

sub scheduler_ids_by_batch {
    my $self = shift;

    my $scheduler_index = $self->current_batch->scheduler_index;

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

=head3 scheduler_ids_by_array

=cut

sub scheduler_ids_by_array {
    my $self = shift;

    my $scheduler_index = $self->current_batch->scheduler_index;
    return unless $scheduler_index;

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

    $DB::single = 2;

    my $batch_scheduler_id =
      $self->jobs->{ $self->current_job }->scheduler_ids->[$index_in_batch];

    $self->current_batch->scheduler_id($batch_scheduler_id);

    my @jobs = keys %{$scheduler_index};

    foreach my $job (@jobs) {

        next unless $job;
        my $batch_index = $scheduler_index->{$job};

        my $job_start = $self->jobs->{$job}->{batch_index_start};
        my $job_end   = $self->jobs->{$job}->{batch_index_end};

        my @job_array = ( $job_start .. $job_end );

        foreach my $index ( @{$batch_index} ) {

            my $x = $self->index_in_batch_deps( $job, $index );

            #we should give a warning here
            if ( !defined $x ) {
                print "Internal There is no index in batch!\n";
                $self->app_log->warn(
                        "Job name $job does not have an appropriate index for "
                      . $self->current_job
                      . " array index $index" );
                next;
            }
            my $dep_scheduler_id = $self->jobs->{$job}->scheduler_ids->[$x];

            next unless $dep_scheduler_id;

            my $array_dep = [
                $batch_scheduler_id . '_' . $self->batch_counter,
                $dep_scheduler_id . '_' . $job_array[$index]
            ];
            $self->current_batch->add_array_deps($array_dep);
        }

    }

    $self->update_job_deps;
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

    my $x = 0;

    foreach my $batch_index ( $self->jobs->{$job}->all_batch_indexes ) {
        my $batch_start = $batch_index->{batch_index_start} - 1;
        my $batch_end   = $batch_index->{batch_index_end} - 1;

        if ( $index >= $batch_start && $index <= $batch_end ) {
            return $x;
        }
        $x++;
    }

    return undef;
}

sub index_in_batch_deps {
    my $self  = shift;
    my $job   = shift;
    my $index = shift;

    my $x = 0;

    my $len =
      $self->jobs->{$job}->batch_index_end -
      $self->jobs->{$job}->batch_index_start;
    my @search_indexes =
      ( $self->jobs->{$job}->batch_index_start .. $self->jobs->{$job}
          ->batch_index_end );

    my $search_index = $search_indexes[$index];

    foreach my $batch_index ( $self->jobs->{$job}->all_batch_indexes ) {
        my $batch_start = $batch_index->{batch_index_start};
        my $batch_end   = $batch_index->{batch_index_end};

        if ( $search_index >= $batch_start && $search_index <= $batch_end ) {
            return $x;
        }

        $x++;
    }

    return undef;
}

=head3 work

Process the batch
Submit to the scheduler slurm/pbs/etc
Take care of the counters

=cut

sub work {
    my $self = shift;

    $DB::single = 2;

    if ( $self->use_batches ) {
        return unless $self->has_batch;
    }

    $self->process_batch;
    $self->clear_batch;

    $self->reset_cmd_counter;
}

=head3 process_batch()

Create the slurm submission script from the slurm template
Write out template, submission job, and infile for parallel runner

=cut

#TODO think of more informative sub name
#TODO split this into process_arrays and process_batches

sub process_batch {
    my $self = shift;

    return if $self->no_submit_to_slurm;

    $DB::single = 2;

    my $ok;
    if ( $self->has_scheduler_ids ) {
        $ok = $self->join_scheduler_ids(':');
    }

    my $count_by;
    if ( $self->use_batches ) {
        $count_by = [
            {
                batch_index_start =>
                  $self->jobs->{ $self->current_job }->{batch_index_start},
                batch_index_end =>
                  $self->jobs->{ $self->current_job }->{batch_index_end},
            }
        ];
    }
    else {
        $count_by = $self->jobs->{ $self->current_job }->batch_indexes;
    }

    foreach my $batch_indexes (
        @{$count_by} )
    {

        my $counter;

        my ( $batch_counter, $job_counter ) = $self->prepare_counter;

        $counter = $job_counter;
        if ( $self->use_batches ) {
            $counter = $batch_counter;
        }

        $self->prepare_files();

        my $array_str = "";
        if ( !$self->use_batches ) {

            $array_str = $batch_indexes->{batch_index_start} . "-"
              . $batch_indexes->{batch_index_end};

            $self->prepare_batch_files_array(
                $batch_indexes->{batch_index_start},
                $batch_indexes->{batch_index_end}
            );
        }
        else {
            $DB::single = 2;
            my $jobname = $self->resolve_project($job_counter);

            $self->cmdfile(
                $self->outdir . "/$jobname" . "_" . $batch_counter . ".in" );
            $self->write_batch_file;
        }

        my $command = $self->process_batch_command($counter);

        $self->process_template( $counter, $command, $ok, $array_str );

        $self->post_process_jobs();
    }
}

=head3 process_template

=cut

sub process_template {
    my $self      = shift;
    my $counter   = shift;
    my $command   = shift;
    my $ok        = shift;
    my $array_str = shift;

    $DB::single = 2;

    #TODO Rewrite this to only use self

    my $jobname = $self->resolve_project($counter);

    $self->template->process(
        $self->template_file,
        {
            JOBNAME   => $jobname,
            USER      => $self->user,
            COMMAND   => $command,
            ARRAY_STR => $array_str,
            AFTEROK   => $ok,
            MODULES   => $self->jobs->{ $self->current_job }->join_modules(' '),
            OUT       => $self->logdir
              . "/$counter" . "_"
              . $self->current_job . ".log",
            job => $self->jobs->{ $self->current_job },
        },
        $self->slurmfile
    ) || die $self->template->error;

    chmod 0777, $self->slurmfile;

    my $scheduler_id = $self->submit_jobs;

    try {
        $self->jobs->{ $self->current_job }->add_scheduler_ids($scheduler_id);
    }
    catch {
        if ( defined $_ ) {
            $self->app_log->fatal(
'Not all jobs were submitted successfully. Exiting. Error follows.'
            );
            exit 1;
        }
        else {
            return;
        }
    };

}

=head3 process_batch_command

splitting this off from the main command

=cut

sub process_batch_command {
    my $self    = shift;
    my $counter = shift;

    my ( $command, $subcommand );

    if ( $self->use_batches ) {
        $subcommand = "execute_job";
    }
    else {
        $subcommand = "execute_array";
    }

    my $logname;
    if ( $self->has_project ) {
        $logname = $self->project . "_" . $counter . "_" . $self->current_job;
    }
    else {
        $logname = $counter . "_" . $self->current_job;
    }

    $command = "sleep 20 && \\\n";
    $command .= "cd " . getcwd() . "\n";
    if ( $self->has_custom_command ) {
        $command .= $self->custom_command . " \\\n";
    }
    else {
        $command .= "hpcrunner.pl $subcommand \\\n";
    }

    if ( $self->has_project ) {
        $command .= "\t--project " . $self->project . " \\\n";
    }

    $command .=
        "\t--procs "
      . $self->jobs->{ $self->current_job }->procs . " \\\n"
      . "\t--outdir "
      . $self->outdir . " \\\n"
      . "\t--logname "
      . $logname . " \\\n"
      . "\t--process_table "
      . $self->process_table;

    $command .= "\\\n\t--infile " . $self->cmdfile if $self->use_batches;

    #TODO Update metastring to give array index
    my $metastr =
      $self->job_stats->create_meta_str( $counter, $self->batch_counter,
        $self->current_job, $self->use_batches,
        $self->jobs->{ $self->current_job } );

    $command .= " \\\n\t" if $metastr;
    $command .= $metastr  if $metastr;

    my $pluginstr = $self->create_plugin_str;
    $command .= $pluginstr if $pluginstr;

    my $version_str = $self->create_version_str;
    $command .= $version_str if $version_str;

    $command .= "\n\n";
    return $command;
}

=head3 create_version_str

If there is a version add it

=cut

#TODO Move to git

sub create_version_str {
    my $self = shift;

    my $version_str = "";

    if ( $self->has_git && $self->has_version ) {
        $version_str .= " \\\n\t";
        $version_str .= "--version " . $self->version;
    }

    return $version_str;
}

=head3 submit_to_scheduler

Submit the job to the scheduler.

Inputs: self, submit_command (sbatch, qsub, etc)

Returns: exitcode, stdout, stderr

This subroutine was just about 100% from the following perlmonks discussions. All that I did was add in some logging.

http://www.perlmonks.org/?node_id=151886

=cut

sub submit_to_scheduler {
    my $self           = shift;
    my $submit_command = shift;

    my ( $infh, $outfh, $errfh );
    $errfh = gensym();    # if you uncomment this line, $errfh will
                          # never be initialized for you and you
                          # will get a warning in the next print
                          # line.
    my $cmdpid;
    eval {
        $cmdpid =
          open3( $infh, $outfh, $errfh, "$submit_command " . $self->slurmfile );
    };
    die $@ if $@;

    my $sel = new IO::Select;    # create a select object
    $sel->add( $outfh, $errfh ); # and add the fhs
    my ( $stdout, $stderr );

    while ( my @ready = $sel->can_read ) {
        foreach my $fh (@ready) {    # loop through them
            my $line;

            # read up to 4096 bytes from this fh.
            my $len = sysread $fh, $line, 4096;
            if ( not defined $len ) {

                # There was an error reading
                $self->log_main_messages( 'fatal', "Error from child: $!" );
            }
            elsif ( $len == 0 ) {

                # Finished reading from this FH because we read
                # 0 bytes.  Remove this handle from $sel.
                $sel->remove($fh);
                close($fh);
            }
            else {    # we read data alright
                if ( $fh == $outfh ) {
                    $stdout .= $line;

                    $self->log_main_messages( 'debug', $line );
                }
                elsif ( $fh == $errfh ) {
                    $stderr .= $line;

                    $self->log_main_messages( 'error', $line );
                }
                else {
                    $self->log_main_messages( 'fatal', "Shouldn't be here!" );
                }
            }
        }
    }

    waitpid( $cmdpid, 1 );
    my $exitcode = $?;

    $sel->remove($outfh);
    $sel->remove($infh);

    sleep(5);
    return ( $exitcode, $stdout, $stderr );
}

=head3 summarize_jobs

=cut

sub summarize_jobs {
    my $self = shift;

    my $t    = Text::ASCIITable->new();
    my $x    = 0;
    my @rows = ();

    foreach my $job ( $self->all_schedules ) {

        # use Data::Dumper;
        #   print Dumper($self->jobs->{$job});
        for ( my $x = 0 ; $x < $self->jobs->{$job}->count_scheduler_ids ; $x++ )
        {
            my $row = [];

            #TODO Add testing coverage for using batches
            $DB::single = 2;
            my $batch_start =
              $self->jobs->{$job}->batch_indexes->[$x]->{'batch_index_start'};
            my $batch_end =
              $self->jobs->{$job}->batch_indexes->[$x]->{'batch_index_end'};
            my $len = ( $batch_end - $batch_start ) + 1;

            push( @{$row}, $job );
            push( @{$row}, $self->jobs->{$job}->scheduler_ids->[$x] );
            push( @{$row}, "$batch_start-$batch_end" );
            push( @{$row}, $len );
            push( @rows,   $row );
        }
    }
    $t->setCols(
        [ "Job Name", "Scheduler ID", "Task Indices", "Total Tasks" ] );
    map { $t->addRow($_) } @rows;
    $self->app_log->info("Job Summary");
    $self->app_log->info( "\n" . $t );
}

1;
