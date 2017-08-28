package HPC::Runner::Command::submit_jobs::Plugin::SGE;

use Moose::Role;
use namespace::autoclean;

use Data::Dumper;
use Log::Log4perl;
use File::Temp qw/ tempfile /;

with 'HPC::Runner::Command::submit_jobs::Plugin::Role::Log';

=head1 HPC::Runner::Command::Plugin::Scheduler::Slurm;

=cut

has 'submit_command' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'qsub',
);

has 'template_file' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;

        my ( $fh, $filename ) = tempfile();

        my $tt = <<EOF;
#!/usr/bin/env bash
#
#$ -N [% JOBNAME %]
#$ -S /bin/bash
#$ -cwd
[% IF job.has_queue %]
#$-q [% job.queue %]
[% END %]
#$ -pe smp [% job.cpus_per_task %]
[% IF job.has_walltime %]
#$ -l h_rt=[% job.walltime %]
[% END %]
#$ -j y
#$ -o [% OUT %]
[% IF job.has_mem %]
#$ -l mh_vem=[% job.mem %]
[% END %]
[% IF ARRAY_STR %]
#$ -t=[% ARRAY_STR %]
[% END %]

[% IF AFTEROK %]
#$ -hold_jid=[% AFTEROK %]
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
      q{Path to Slurm template file if you do not wish to use the default}
);

=head2 Subroutines

=cut

=head3 submit_jobs

Submit jobs to slurm queue using PBS.

Format is

 "Your job <job_id> ("<job_name>") has been submitted"

=cut

sub submit_jobs {
    my $self = shift;

    my ( $exitcode, $stdout, $stderr ) =
      $self->submit_to_scheduler(
        $self->submit_command . " " . $self->slurmfile );
    sleep(5);

    if ( $exitcode != 0 ) {
        $self->log->fatal("Job was not submitted successfully");
        $self->log->warn( "STDERR: " . $stderr ) if $stderr;
        $self->log->warn( "STDOUT: " . $stdout ) if $stdout;
    }

    # my $jobid = $stdout;
    my $jobid;
    ($jobid) = $stdout =~ m/Your job (\d.*) \(/;

    if ( !$jobid ) {
        $self->job_failure;
    }
    else {
        $self->log->debug(
            "Submited job " . $self->slurmfile . "\n\tWith SGE jobid $jobid" );
    }

    return $jobid;
}

=head3 update_job_deps

Update the job dependencies if using job_array (not batches)

NOTE - Task dependencies may not be supported.


=cut

sub update_job_deps {
    my $self = shift;

    return unless $self->has_array_deps;

    $self->log->warn('Task dependencies in SGE is still very experimental!');
    $self->log->warn( 'Please raise any problems as an issue at github.' . "\n"
          . "\thttp://github.com/biosails/HPC-Runner-Command" );

    while ( my ( $current_task, $v ) = each %{ $self->array_deps } ) {

        my $cmd;
        if ( $self->use_batches ) {
            my $dep_tasks = join( ':', @$v );
            $cmd = "qalter -hold_jid \"$dep_tasks\" $current_task ";
        }
        else {
            foreach my $tv ( @{$v} ) {
                my @tmp = split( '_', $tv );
                $tv = $tmp[0] . '[' . $tmp[1] . ']';
            }

            my @tmp = split( '_', $current_task );
            $current_task = $tmp[0] . '[' . $tmp[1] . ']';

            my $dep_tasks = join( ':', @$v );
            $cmd = "qalter -hold_jid \"$dep_tasks\" \"$current_task\" ";
        }

        $self->submit_to_scheduler($cmd);
    }
}

1;
