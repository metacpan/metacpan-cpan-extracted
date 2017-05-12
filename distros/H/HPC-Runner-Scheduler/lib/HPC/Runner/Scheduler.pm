package HPC::Runner::Scheduler;

use File::Path qw(make_path remove_tree);
use File::Temp qw/ tempfile tempdir /;
use IO::File;
use IO::Select;
use Cwd;
use IPC::Open3;
use Symbol;
use Template;
use Log::Log4perl qw(:easy);
use DateTime;
use Data::Dumper;
use List::Util qw(shuffle);
use List::MoreUtils qw(firstidx);
use JSON;

use Moose;
use namespace::autoclean;
extends 'HPC::Runner';
with 'MooseX::SimpleConfig';

# For pretty man pages!
$ENV{TERM} = 'xterm-256color';

our $VERSION = '0.09';

=encoding utf-8

=head1 NAME

HPC::Runner::Scheduler - Base Library for HPC::Runner::Slurm and HPC::Runner::PBS

=head1 SYNOPSIS

    pbsrunner.pl/slurmrunner.pl/mcerunner.pl --infile list_of_commands

=head1 DESCRIPTION

HPC::Runner::Scheduler is a base library for creating templates of HPC Scheduler (Slurm, PBS, etc) submission scripts.

All the scheduler variables: memory, cpus, nodes, partitions/queues, are abstracted to a template. Instead of writing an entire submission template

    slurmrunner.pl --infile list_of_commands #with list of optional parameters

Please see the indepth usage guide at L<HPC::Runner::Usage>

=cut

=head1 User Options

User options can be passed to the script with script --opt1 or in a configfile. It uses MooseX::SimpleConfig for the commands

=head2 configfile

Config file to pass to command line as --configfile /path/to/file. It should be a yaml or xml (untested)
This is optional. Paramaters can be passed straight to the command line

=head3 example.yml

    ---
    infile: "/path/to/commands/testcommand.in"
    outdir: "path/to/testdir"
    module:
        - "R2"
        - "shared"

=cut

has '+configfile' => (
    required => 0,
    documentation =>
        q{If you get tired of putting all your options on the command line create a config file instead.
    ---
    infile: "/path/to/commands/testcommand.in"
    outdir: "path/to/testdir"
    module:
        - "R2"
        - "shared"
    }
);

=head2 infile

infile of commands separated by newline

=head3 example.in

    cmd1
    cmd2 --input --input \
    --someotherinput
    wait
    #Wait tells slurm to make sure previous commands have exited with exit status 0.
    cmd3  ##very heavy job
    newnode
    #cmd3 is a very heavy job so lets start the next job on a new node

=cut

=head2 module

modules to load with slurm
Should use the same names used in 'module load'

Example. R2 becomes 'module load R2'

=cut

has 'module' => (
    is            => 'rw',
    isa           => 'ArrayRef',
    required      => 0,
    documentation => q{List of modules to load ex. R2, samtools, etc},
    default       => sub { [] },
);

=head2 afterok

The afterok switch in slurm. --afterok 123 will tell slurm to start this job after job 123 has completed successfully.

=cut

has afterok => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 0,
    default  => sub {
        return [];
    },
);

=head2 cpus_per_task

slurm item --cpus_per_task defaults to 4, which is probably fine

=cut

has 'cpus_per_task' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    default   => 4,
    predicate => 'has_cpus_per_task',
    clearer   => 'clear_cpus_per_task'
);

=head2 commands_per_node

--commands_per_node defaults to 8, which is probably fine

=cut

has 'commands_per_node' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => 8,
    documentation =>
        q{Commands to run on each node. This is not the same as concurrent_commands_per_node!},
    predicate => 'has_commands_per_node',
    clearer   => 'clear_commands_per_node'
);

=head2 nodes_count

Number of nodes to use on a job. This is only useful for mpi jobs.

PBS:
#PBS -l nodes=nodes_count:ppn=16 this

Slurm:
#SBATCH --nodes nodes_count

=cut

has 'nodes_count' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => 1,
    documentation =>
        q{Number of nodes requested. You should only use this if submitting parallel jobs.},
    predicate => 'has_nodes_count',
    clearer   => 'clear_nodes_count'
);

=head2 partition

#Should probably have something at some point that you can specify multiple partitions....

Specify the partition. Defaults to the partition that has the most nodes.

=cut

has 'partition' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => '',
    documentation =>
        q{Slurm partition to submit jobs to. Defaults to the partition with the most available nodes},
    predicate => 'has_partition',
    clearer   => 'clear_partition'
);

=head2 walltime

Define PBS walltime

=cut

has 'walltime' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '04:00:00',
    predicate => 'has_walltime',
    clearer => 'clear_walltime,'
);

=head2 mem

=cut

has 'mem' => (
    is => 'rw',
    isa => 'Str|Undef',
    predicate => 'has_mem',
    clearer => 'clear_mem',
    required => 0,
    documentation => q{Supply a memory limit},
);


#=head2 nodelist

#Defaults to the nodes on the defq queue

#=cut

#has 'nodelist' => (
    #is       => 'rw',
    #isa      => 'ArrayRef',
    #required => 0,
    #default  => sub { return [] },
    #documentation =>
        #q{List of nodes to submit jobs to. Defaults to the partition with the most nodes.},
#);

=head2 submit_slurm

Bool value whether or not to submit to slurm. If you are looking to debug your files, or this script you will want to set this to zero.
Don't submit to slurm with --nosubmit_to_slurm from the command line or
$self->submit_to_slurm(0); within your code

=cut

has 'submit_to_slurm' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 1,
    required => 1,
    documentation =>
        q{Bool value whether or not to submit to slurm. If you are looking to debug your files, or this script you will want to set this to zero.},
);

=head2 first_pass

Do a first pass of the file to get all the stats

=cut

has 'first_pass' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Bool',
    default  => 1,
    required => 1,
);

=head2 template_file

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
#SBATCH --get-user-env
#SBATCH --job-name=[% JOBNAME %]
#SBATCH --output=[% OUT %]
[% IF PARTITION %]
#SBATCH --partition=[% PARTITION %]
[% END %]
[% IF CPU %]
#SBATCH --cpus-per-task=[% CPU %]
[% END %]
[% IF self.has_mem %]
#SBATCH --mem=[% self.mem %]
[% END %]
[% IF self.has_walltime %]
#SBATCH --time=[% self.walltime %]
[% END %]
[% IF AFTEROK %]
#SBATCH --dependency=afterok:[% AFTEROK %]
[% END %]

[% IF MODULE %]
[% FOR d = MODULE %]
module load [% d %]
[% END %]
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

=head2 serial

Option to run all jobs serially, one after the other, no parallelism
The default is to use 4 procs

=cut

has serial => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation =>
        q{Use this if you wish to run each job run one after another, with each job starting only after the previous has completed successfully},
    predicate => 'has_serial',
    clearer   => 'clear_serial'
);

=head2 user

user running the script. Passed to slurm for mail information

=cut

has 'user' => (
    is       => 'rw',
    isa      => 'Str',
    default  => sub { return $ENV{LOGNAME} || $ENV{USER} || getpwuid($<); },
    required => 1,
    documentation =>
        q{This defaults to your current user ID. This can only be changed if running as an admin user}
);

=head2 use_threads

Bool value to indicate whether or not to use threads. Default is uses processes

If using threads your perl must be compiled to use threads!

=cut

has 'use_threads' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    required      => 0,
    documentation => q{Use threads to run jobs},
);

=head2 use_processes

Bool value to indicate whether or not to use processes. Default is uses processes

=cut

has 'use_processes' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    required      => 0,
    documentation => q{Use processes to run jobs},
);

=head2 use_gnuparallel

Bool value to indicate whether or not to use processes. Default is uses processes

=cut

has 'use_gnuparallel' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    required => 0,
    documentation =>
        q{Use gnu-parallel to run jobs and manage threads. This is the best option if you do not know how many threads your application uses!}
);

=head2 use_custom

Supply your own command instead of mcerunner/threadsrunner/etc

=cut

has 'custom_command' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_custom_command',
    clearer   => 'clear_custom_command',
);

=head1 Internal Variables

You should not need to mess with any of these.

=head2 template

template object for writing slurm batch submission script

=cut

has 'template' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    required => 0,
    default  => sub { return Template->new( ABSOLUTE => 1 ) },
);

=head2 cmd_counter

keep track of the number of commands - when we get to more than commands_per_node restart so we get submit to a new node.
This is the number of commands within a batch. Each new batch resets it.

=cut

has 'cmd_counter' => (
    traits   => [ 'Counter', 'NoGetopt' ],
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => 0,
    handles  => {
        inc_cmd_counter   => 'inc',
        dec_cmd_counter   => 'dec',
        reset_cmd_counter => 'reset',
    },
);

=head2 node_counter

Keep track of which node we are on

=cut

has 'node_counter' => (
    traits   => [ 'Counter', 'NoGetopt' ],
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => 0,
    handles  => {
        inc_node_counter   => 'inc',
        dec_node_counter   => 'dec',
        reset_node_counter => 'reset',
    },
);

=head2 batch_counter

Keep track of how many batches we have submited to slurm

=cut

has 'batch_counter' => (
    traits   => [ 'Counter', 'NoGetopt' ],
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => 1,
    handles  => {
        inc_batch_counter   => 'inc',
        dec_batch_counter   => 'dec',
        reset_batch_counter => 'reset',
    },
);

#=head2 node

#Node we are running on

#=cut

#has 'node' => (
    #traits  => ['NoGetopt'],
    #is      => 'rw',
    #isa     => 'Str|Undef',
    #lazy    => 1,
    #default => sub {
        #my $self = shift;
        #return $self->nodelist()->[0] if $self->nodelist;
        #return "";
    #}
#);

=head2 batch

List of commands to submit to slurm

=cut

has 'batch' => (
    traits   => [ 'String', 'NoGetopt', ],
    is       => 'rw',
    isa      => 'Str',
    default  => q{},
    required => 0,
    handles   => { add_batch => 'append', },
    clearer   => 'clear_batch',
    predicate => 'has_batch',
);

=head2 cmdfile

File of commands for mcerunner/parallelrunner
Is cleared at the end of each slurm submission

=cut

has 'cmdfile' => (
    traits   => [ 'String', 'NoGetopt' ],
    default  => q{},
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    handles => { clear_cmdfile => 'clear', },
);

=head2 slurmfile

File generated from slurm template

=cut

has 'slurmfile' => (
    traits   => [ 'String', 'NoGetopt' ],
    default  => q{},
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    handles => { clear_slurmfile => 'clear', },
);

=head2 slurm_decides

Do not specify a node or partition in your sbatch file. Let Slurm decide which nodes/partition to submit jobs.

=cut

has 'slurm_decides' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 job_stats

HashRef of job stats - total jobs submitted, total processes, etc

=cut

has 'job_stats' => (
    traits   => ['NoGetopt'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        my $self = shift;
        my $href = {};
        $href->{total_processes} = 0;
        $href->{jobnames}        = {};
        $href->{total_batches}   = 0;
        $href->{batches}         = {};
    }
);

=head2 job_deps

#HPC jobname=assembly
#HPC job_deps=gzip,fastqc

=cut

has 'job_deps' => (
    traits   => ['NoGetopt'],
    is => 'rw',
    isa => 'HashRef',
    required => 0,
    default => sub {
        my $self = shift;
        $self->jobname => [];
    },
    lazy => 1,
);


=head2 job_scheduler_id

Job Scheduler ID running the script. Passed to slurm for mail information

=cut

has 'job_scheduler_id' => (
    is => 'rw',
    isa => 'Str|Undef',
    default => sub { return $ENV{SBATCH_JOB_ID} || $ENV{PBS_JOBID} || undef; },
    required => 1,
    documentation => q{This defaults to your current Job Scheduler ID. Ignore this if running on a single node},
    predicate => 'has_job_scheduler_id',
    clearer => 'clear_job_scheduler_id',
);

=head2 jobname

Specify a job name, and jobs will be jobname_1, jobname_2, jobname_x

=cut

has 'jobname' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    traits  => ['String'],
    default => q{job},
    default => sub { return $ENV{SBATCH_JOB_NAME} || $ENV{PBS_JOBNAME} || 'job'; },
    predicate => 'has_jobname',
    handles => {
        add_jobname => 'append',
        clear_jobname => 'clear',
        replace_jobname => 'replace',
    },
    documentation => q{Specify a job name, each job will be appended with its batch order},
);

=head2 jobref

Array of arrays details slurm/process/scheduler job id. Index -1 is the most recent job submissisions, and there will be an index -2 if there are any job dependencies

=cut

has 'jobref' => (
    traits  => ['NoGetopt'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ [] ]  },
);

=head1 SUBROUTINES/METHODS

=cut

=head2 run()

First sub called
Calling system module load * does not work within a screen session!

=cut

sub run {
    my $self = shift;

    if ( $self->serial ) {
        $self->procs(1);
    }

    $self->check_files;

    $self->first_pass(1);
    $self->parse_file_slurm;
    $self->do_stats;

    $DB::single = 2;
    $self->first_pass(0);
    $self->parse_file_slurm;
}

=head2 do_stats

Do some stats on our job stats
Foreach job name get the number of batches, and have a put that in batches->batch->job_batches

=cut

sub do_stats {
    my $self = shift;

    my @jobs = keys %{$self->job_stats->{jobnames}};

    foreach my $batch (keys %{$self->job_stats->{batches}}){
        my $href = $self->job_stats->{batches}->{$batch};
        my $jobname = $href->{jobname};
        my @job_batches = @{$self->job_stats->{jobnames}->{$jobname} };

        my $index = firstidx {$_ eq $batch} @job_batches;
        $index += 1;
        my $lenjobs = $#job_batches + 1;
        $self->job_stats->{batches}->{$batch}->{job_batches} = $index."/".$lenjobs;


        $href->{total_processes} = $self->job_stats->{total_processes};
        $href->{total_batches} = $self->job_stats->{total_batches};
        $href->{batch_count} = $href->{batch}."/".$self->job_stats->{total_batches};
    }
}

=head2 check_files()

Check to make sure the outdir exists.
If it doesn't exist the entire path will be created

=cut

sub check_files {
    my ($self) = @_;
    my ($t);

    $t = $self->outdir;
    $t =~ s/\/$//g;
    $self->outdir($t);

    #make the outdir
    make_path( $self->outdir ) if !-d $self->outdir;

    #$self->get_nodes;
}

=head2 parse_file_slurm

Parse the file looking for the following conditions

lines ending in `\`
wait
nextnode

Batch commands in groups of $self->cpus_per_task, or smaller as wait and nextnode indicate

=cut

sub parse_file_slurm {
    my $self = shift;
    my $fh = IO::File->new( $self->infile, q{<} )
        or print "Error opening file  "
        . $self->infile . "  "
        . $!;    # even better!

    $self->reset_cmd_counter;
    $self->reset_node_counter;
    $self->reset_batch_counter;
    $self->jobref( [] );

    if ( $self->afterok ) {
        $self->wait(1);
        $self->jobref->[0] = $self->afterok;
        push( @{ $self->jobref }, [] );
    }

    while (<$fh>) {
        my $line = $_;
        next unless $line;
        next unless $line =~ m/\S/;
        $self->process_lines($line);
    }
    $self->work if $self->has_batch;
    push( @{ $self->jobref }, [] ) if $self->serial;
    close($fh);
}

sub process_lines {
    my $self = shift;
    my $line = shift;

    #Do a sanity check for nohup
    if ( $line =~ m/^nohup/ ) {
        die print
            "You cannot submit jobs to the queue using nohup! Please remove nohup and try again.\n";
    }

#if( $self->cmd_counter > 0 && 0 == $self->cmd_counter % ($self->commands_per_node + 1) && $self->batch ){
    if (   $self->cmd_counter > 0
        && 0 == $self->cmd_counter % ( $self->commands_per_node )
        && $self->batch )
    {
        #Run this batch and start the next
        $self->work;
        push( @{ $self->jobref }, [] ) if $self->serial;
    }

    $self->check_hpc_meta($line);
    return if $line =~ m/^#/;

    if ( $self->has_cmd ) {
        $self->add_cmd($line);
        $self->add_batch($line);
        if ( $line =~ m/\\$/ ) {
            return;
        }
        else {
            $self->add_cmd("\n");
            $self->add_batch("\n");
            $self->clear_cmd;
            $self->inc_cmd_counter;
        }
    }
    else {
        $self->add_cmd($line);

        if ( $line =~ m/\\$/ ) {
            $self->add_batch($line);

            #next;
            return;
        }
        elsif ( $self->match_cmd(qr/^wait$/) ) {

          #submit this batch and get the job id so the next can depend upon it
            $self->clear_cmd;
            $self->wait(1);
            $self->work if $self->has_batch;
            push( @{ $self->jobref }, [] );
        }
        elsif ( $self->match_cmd(qr/^newnode$/) ) {
            $self->clear_cmd;
            $self->work if $self->has_batch;
            push( @{ $self->jobref }, [] ) if $self->serial;
        }
        else {
            #Don't want to increase command count for wait and newnode
            $self->inc_cmd_counter;
        }
        $self->add_batch( $line . "\n" ) if $self->has_cmd;
        $self->clear_cmd;
    }

}

=head2 check_meta

allow for changing parameters mid through the script

#Job1
echo "this is job one" && \
    bin/dostuff bblahblahblah

#HPC cpu_per_task=12

echo "This is my new job with new HPC params!"

=cut

sub check_hpc_meta {
    my $self = shift;
    my $line = shift;
    my ( @match, $t1, $t2 );

    return unless $line =~ m/^#HPC/;

    @match = $line =~ m/HPC (\w+)=(.+)$/;
    ( $t1, $t2 ) = ( $match[0], $match[1] );

    if ( !$self->can($t1) ) {
        print "Option $t1 is an invalid option!\n";
        return;
    }

    if ($t1) {
        if ( $t1 eq "module" ) {
            $self->$t1( [$t2] );
        }
        else {
            $self->$t1($t2);
        }
    }
    else {
        @match = $line =~ m/HPC (\w+)$/;
        $t1    = $match[0];
        return unless $t1;
        $t1 = "clear_$t1";
        $self->$t1;
    }
}

sub check_note_meta {
    my $self = shift;
    my $line = shift;

    return unless $line =~ m/^#NOTE/;

    $self->add_batch( $line . "\n" );
}

=head2 work

Get the node #may be removed but we'll try it out
Process the batch
Submit to slurm
Take care of the counters

=cut

sub work {
    my $self = shift;

    $DB::single=2;

    $self->collect_stats if $self->first_pass;

    #if ( $self->node_counter > ( scalar @{ $self->nodelist } ) ) {
        #$self->reset_node_counter;
    #}
    #$self->node( $self->nodelist()->[ $self->node_counter ] )
        #if $self->nodelist;
    $self->process_batch unless $self->first_pass;

    $self->inc_batch_counter;
    $self->clear_batch;
    $self->inc_node_counter;

    $self->reset_cmd_counter;
}

=head2 collect_stats

Collect job stats

=cut

sub collect_stats {
    my $self = shift;

    return unless $self->first_pass;

    my $counter = $self->batch_counter;
    $counter = sprintf( "%03d", $counter );

    #Get the total processes
    my $href = $self->job_stats;
    $href->{total_processes} += $self->cmd_counter;

    #Get the command count
    my $command_count = ($href->{total_processes} - $self->cmd_counter) + 1;
    #Get number of commands in this batch
    $href->{batches}->{ $counter . "_" . $self->jobname } = {
        commands => $self->cmd_counter,
        jobname   => $self->jobname,
        batch     => $self->batch_counter,
        command_count     => $command_count."-".$href->{total_processes},
    };

    my $jobhref = {};
    $jobhref->{ $self->jobname } = [];

    if ( exists $href->{jobnames}->{ $self->jobname } ) {
        my $tarray = $href->{jobnames}->{ $self->jobname };
        push( @{$tarray}, $counter . "_" . $self->jobname );
    }
    else {
        $href->{jobnames}->{ $self->jobname }
            = [ $counter . "_" . $self->jobname ];
    }

    $href->{total_batches} += 1;
    $self->job_stats($href);
}

=head2 process_batch()

Create the slurm submission script from the slurm template
Write out template, submission job, and infile for parallel runner

=cut

sub process_batch {
    my $self = shift;
    my ( $cmdfile, $slurmfile, $slurmsubmit, $fh, $command );

    my $counter = $self->batch_counter;
    $counter = sprintf( "%03d", $counter );

#$self->cmdfile($self->outdir."/".$self->jobname."_".$self->batch_counter.".in");
#$self->slurmfile($self->outdir."/".$self->jobname."_".$self->batch_counter.".sh");
    $self->cmdfile(
        $self->outdir . "/$counter" . "_" . $self->jobname . ".in" );
    $self->slurmfile(
        $self->outdir . "/$counter" . "_" . $self->jobname . ".sh" );

    $fh = IO::File->new( $self->cmdfile, q{>} )
        or print "Error opening file  " . $self->cmdfile . "  " . $!;

    print $fh $self->batch if defined $fh && defined $self->batch;
    $fh->close;

    my $ok;
    if ( $self->wait ) {
        $ok = join( ":", @{ $self->jobref->[-2] } ) if $self->jobref->[-2];
    }

    $command    = $self->process_batch_command();
    $DB::single = 2;

    $self->template->process(
        $self->template_file,
        {   JOBNAME   => $counter . "_" . $self->jobname,
            USER      => $self->user,
            CPU       => $self->cpus_per_task,
            PARTITION => $self->partition,
            AFTEROK   => $ok,
            OUT       => $self->logdir
                . "/$counter" . "_"
                . $self->jobname . ".log",
            MODULE  => $self->module,
            self    => $self,
            COMMAND => $command
        },
        $self->slurmfile
    ) || die $self->template->error;

    chmod 0777, $self->slurmfile;

    $self->submit_slurm if $self->submit_to_slurm;
}

=head2 process_batch_command

splitting this off from the main command

=cut

#TODO add support for custom commands
#TODO Change this all to a plugin system

sub process_batch_command {
    my ($self) = @_;
    my $command;

    #Giving outdir/jobname doesn't work unless a full file path is supplied
    #Need to get absolute path going on...
    #$self->cmdfile($self->jobname."_batch".$self->batch_counter.".in");

    my $counter = $self->batch_counter;
    $counter = sprintf( "%03d", $counter );

    $command = "cd " . getcwd() . "\n";
    if ( $self->has_custom_command ) {
        $command
            .= $self->custom_command
            . " --procs "
            . $self->procs
            . " --infile "
            . $self->cmdfile
            . " --outdir "
            . $self->outdir
            . " --logname "
            ."$counter" . "_"
            . $self->jobname
            . " --process_table "
            . $self->process_table;
    }
    elsif ( $self->use_gnuparallel ) {
        $command
            .= "cat "
            . $self->cmdfile
            . " | parallelparser.pl | parallel --joblog "
            . $self->outdir
            . "/main.log --gnu -N 1 -q  gnuparallelrunner.pl --command `echo {}` --outdir "
            . $self->outdir
            . " --logname $counter" . "_"
            . $self->jobname
            . " --seq {#}" . "\n";
    }
    elsif ( $self->use_threads ) {
        $command
            .= "paralellrunner.pl --procs "
            . $self->procs
            . " --infile "
            . $self->cmdfile
            . " --outdir "
            . $self->outdir
            . " --logname $counter" . "_"
            . $self->jobname
            . " --process_table "
            . $self->process_table;
    }
    elsif ( $self->use_processes ) {
        $command
            .= "mcerunner.pl --procs "
            . $self->procs
            . " --infile "
            . $self->cmdfile
            . " --outdir "
            . $self->outdir
            . " --logname $counter" . "_"
            . $self->jobname
            . " --process_table "
            . $self->process_table;
    }
    else {
        die print "None of the job processes were chosen!\n";
    }


    my $metastr = $self->create_meta_str;
    $command .= $metastr if $metastr;

    my $pluginstr = $self->create_plugin_str;
    $command .= $pluginstr if $pluginstr;

    return $command;
}

sub create_meta_str {
    my $self = shift;

    my $counter = $self->batch_counter;
    $counter = sprintf( "%03d", $counter );
    my $batchname = $counter . "_" . $self->jobname;

    my $batch = $self->job_stats->{batches}->{$batchname};

    my $json = JSON->new->allow_nonref;
    my $json_text   = $json->encode( $batch );

    $DB::single=2;
    $json_text = " --metastr \'$json_text\'";
    return $json_text;
}

sub create_plugin_str {
    my $self = shift;

    return unless $self->plugins;
    my $plugins   = $self->plugins;
    my $pluginstr = "";
    if ($plugins) {
        if ( ref($plugins) ) {
            my @plugins = @{$plugins};
            foreach my $plugin (@plugins) {
                $pluginstr .= " --plugins $plugin";
            }
        }
        else {
            $pluginstr = " --plugins $plugins";
        }
    }

    return $pluginstr;
}

__PACKAGE__->meta->make_immutable;

#use namespace::autoclean;

1;

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HPC::Runner::Slurm>
L<HPC::Runner::PBS>
L<HPC::Runner::MCE>

=cut

__END__
