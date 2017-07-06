use strict;
use warnings;

package HPC::Runner::Command::submit_jobs::Logger::JSON;

use Moose::Role;

use JSON;
use File::Spec;
use Data::UUID;
use File::Path qw(make_path remove_tree);
use File::Slurp;
use DateTime;

=head3 create_json_submission

Create the data for the json submission

We don't actually do anything here, but its a handy wrapper for loggers that create the submission and then update it

=cut

sub create_json_submission {
    my $self = shift;

    # my $tar = $self->set_archive;
    # $self->archive($tar);
}

=head3 update_json_submission

Take the initial submission and update it to contain the hpcmeta

=cut

sub update_json_submission {
    my $self = shift;

    my $hpc_meta = $self->gen_hpc_meta;

    my $json_text = encode_json $hpc_meta;

    my $basename = $self->data_tar->basename('.tar.gz');
    my $submission_file = File::Spec->catdir( $basename, 'submission.json' );

    $self->archive->add_data( $submission_file, $json_text );
    $self->archive->write( $self->data_tar );

    return $hpc_meta;
}

=head3 gen_hpc_meta

Generate the HPC meta from the submission

#TODO Check for batches

=cut

sub gen_hpc_meta {
    my $self = shift;

    my $hpc_meta = {};
    $hpc_meta->{uuid}        = $self->submission_uuid;
    $hpc_meta->{project}     = $self->project if $self->has_project;
    my $dt = DateTime->now(time_zone => 'local');
    $hpc_meta->{submission_time} = "$dt";
    $hpc_meta->{jobs}        = [];
    $hpc_meta->{submissions} = {};

    foreach my $job ( $self->all_schedules ) {
        my $job_obj = {};

        #Dependencies
        my $ref       = $self->graph_job_deps->{$job};
        my $depstring = join( ", ", @{$ref} );
        my $count_cmd = $self->jobs->{$job}->cmd_counter;
        my $mem       = $self->jobs->{$job}->mem;
        my $cpus      = $self->jobs->{$job}->cpus_per_task;
        my $walltime  = $self->jobs->{$job}->walltime;
        my $cmd_start = $self->jobs->{$job}->{cmd_start};

        $job_obj->{job}           = $job;
        $job_obj->{deps}          = $depstring;
        $job_obj->{total_tasks}   = $count_cmd;
        $job_obj->{walltime}      = $walltime;
        $job_obj->{cpus_per_task} = $cpus;
        $job_obj->{mem}           = $mem;
        $job_obj->{cmd_start}     = $cmd_start;
        $job_obj->{cmd_end}       = $cmd_start + $count_cmd;
        $job_obj->{schedule}      = [];

        #I think this should be scheduler_ids
        for ( my $x = 0 ; $x < $self->jobs->{$job}->{num_job_arrays} ; $x++ ) {

            my $obj = {};

            #index start, index end
            next unless $self->jobs->{$job}->batch_indexes->[$x];

            my $batch_start =
              $self->jobs->{$job}->batch_indexes->[$x]->{'batch_index_start'};
            my $batch_end =
              $self->jobs->{$job}->batch_indexes->[$x]->{'batch_index_end'};
            my $len = ( $batch_end - $batch_start ) + 1;

            my $logname = $self->jobs->{$job}->lognames->[$x];
            if ($logname) {
                ##TASK IDS ARE 0 INDEXED
                $hpc_meta->{submissions}->{$logname}->{jobname} = $job;
                ##The entire job
                $hpc_meta->{submissions}->{$logname}->{job_task_index_start} =
                  $cmd_start + 0;
                $hpc_meta->{submissions}->{$logname}->{job_task_index_end} =
                  $cmd_start + $count_cmd - 1;

                ##This particular batch
                ##These are 1 indexed to match the command line parameters 1
                ##TODO clean up 0/1 indexed!!
                $hpc_meta->{submissions}->{$logname}->{batch_index_start} =
                  $batch_start;
                $hpc_meta->{submissions}->{$logname}->{batch_index_end} =
                  $batch_end;
            }

            my $scheduler_id = $self->jobs->{$job}->scheduler_ids->[$x] || '0';
            $obj->{task_indices} = "$batch_start-$batch_end";
            $obj->{total_tasks}  = $len;
            $obj->{scheduler_id} = $scheduler_id;

            push( @{ $job_obj->{schedule} }, $obj );
        }

        # $hpc_meta->{jobs}->{$job} = $job_obj;
        push( @{ $hpc_meta->{jobs} }, $job_obj );
    }

    # $hpc_meta->{batches} = $self->job_stats->batches;
    return $hpc_meta;
}

1;
