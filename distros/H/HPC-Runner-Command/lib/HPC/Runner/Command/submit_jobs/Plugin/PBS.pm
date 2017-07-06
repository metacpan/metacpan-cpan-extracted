package HPC::Runner::Command::submit_jobs::Plugin::PBS;

use Data::Dumper;
use IPC::Cmd qw[can_run];
use Log::Log4perl;
use File::Temp qw/ tempfile /;

use Moose::Role;

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
#PBS -N [% JOBNAME %]
[% IF job.has_queue %]
#PBS -q [% job.queue %]
[% END %]
#PBS -l nodes=[% job.nodes_count %]:ppn=[% job.cpus_per_task %]
[% IF job.has_walltime %]
#PBS -l walltime=[% job.walltime %]
[% END %]
#PBS -j oe
#PBS -o localhost:[% OUT %]
[% IF job.has_mem %]
#PBS -l mem=[% job.mem %]
[% END %]
[% IF ARRAY_STR %]
[% PERL %]
my \$stash = \$context->stash;
my \$array_str=\$stash->get('ARRAY_STR');
my \@array = split(':', \$array_str);
my \$step  = \$array[1];
\@array = split('-', \$array[0]);
if(\$step == 1){
print PERLOUT "\n#PBS -J=".\$array[0]."-".\$array[1];
}
else{
my \@new_array = ();
for(my \$x=\$array[0]; \$x <= \$array[1]; \$x = \$x + \$step){
  push(\@new_array, \$x);
}
print PERLOUT "\n#PBS -J=".join(',', \@new_array);
}
[% END %]
[% END %]
EOF

        if ( $self->use_batches ) {
            $tt .= <<EOF;
[% IF AFTEROK %]
#PBS -W depend=afterok:[% AFTEROK %]
[% END %]
EOF
        }
        else {
            $tt .= <<EOF;
[% IF AFTEROK %]
[% PERL %]
my \$stash = \$context->stash;
my \$afterok=\$stash->get('AFTEROK');
my \@array = split(':', \$afterok);
foreach my \$a (\@array){
  \$a = \$a."[]";
}
my \$newafterok = join(':', \@array);

print PERLOUT "\n#PBS -W depend=afterokarray:\$newafterok"
[% END %]
[% END %]
EOF
        }

        $tt .= <<EOF;
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

##Application log
##There is a bug in here somewhere - this be named anything ...
has 'log' => (
    is      => 'rw',
    default => sub {
        my $log_conf = q(
log4perl.rootLogger = DEBUG, Screen
log4perl.appender.Screen = \
  Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
  Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
  [%d] %m %n
      );
        Log::Log4perl::init( \$log_conf );
        return Log::Log4perl->get_logger();
    }
);

=head2 Subroutines

=cut

=head3 submit_jobs

Submit jobs to slurm queue using PBS.

=cut

#TODO IF THESE ARE ARRAYS I NEED -W depend=afterokarray:1234[]
# -W depend=afterokarray:12345678[5] for a task in the array

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

    my $jobid = $stdout;

    #When submitting job arrays the array will be 1234[].hpc.nyu.edu

    if ( !$jobid ) {
        $self->job_failure;
    }
    else {
        $self->log->debug(
            "Submited job " . $self->slurmfile . "\n\tWith PBS jobid $jobid" );
    }

    return $jobid;
}

=head3 update_job_deps

Update the job dependencies if using job_array (not batches)

TODO - not entirely sure this will work...

# This is for Torque
# http://docs.adaptivecomputing.com/torque/4-1-4/Content/topics/commands/qalter.htm
# $tv = $tmp[0] . ' -t '.$tmp[1];

=cut

sub update_job_deps {
    my $self = shift;

    return unless $self->has_array_deps;

    $self->log->warn('Task dependencies in PBS is still very experimental!');
    $self->log->warn( 'Please raise any problems as an issue at github.' . "\n"
          . "\thttp://github.com/biosails/HPC-Runner-Command" );

    while ( my ( $current_task, $v ) = each %{ $self->array_deps } ) {

        my $cmd;
        if ( $self->use_batches ) {
            my $dep_tasks = join( ':', @$v );
            $cmd = "qalter $current_task -W depend=afterok:$dep_tasks";
        }
        else {
            foreach my $tv ( @{$v} ) {

                # The format is schedulerId_arrayIndex
                $tv =~ s/\n//;
                my @tmp = split( '_', $tv );

                my $dep_scheduler_id =
                  $self->parse_pbs_scheduler_id( $tmp[0], $tmp[1] );
                $tv = $dep_scheduler_id;
            }

            my @tmp = split( '_', $current_task );
            my $current_scheduler_id =
              $self->parse_pbs_scheduler_id( $tmp[0], $tmp[1] );

            my $dep_tasks = join( ':', @$v );
            $dep_tasks = '"' . $dep_tasks . '"';

            $cmd =
"qalter \"$current_scheduler_id\" -W depend=afterokarray:$dep_tasks";

        }

        $self->submit_to_scheduler($cmd);
    }
}

=head3 parse_pbs_scheduler_id

PBS tasks look like
1234[].hpc.nyu.edu
This needs to be split in order to get the task right

=cut

sub parse_pbs_scheduler_id {
    my $self             = shift;
    my $pbs_scheduler_id = shift;
    my $task             = shift;

    my @split_host = split( '\.', $pbs_scheduler_id );
    my $scheduler_id = shift @split_host;
    $scheduler_id =~ s/\[\]//;
    my $host = join( '.', @split_host );

    my $current_scheduler_id = $scheduler_id . '[' . $task . '].' . $host;

    return $current_scheduler_id;
}

1;
