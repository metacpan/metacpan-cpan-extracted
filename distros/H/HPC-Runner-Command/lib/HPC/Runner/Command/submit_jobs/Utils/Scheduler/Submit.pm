package HPC::Runner::Command::submit_jobs::Utils::Scheduler::Submit;

use Moose::Role;
use Cwd;
use IPC::Open3;
use IO::Select;
use Symbol;
use Try::Tiny;

=head3 process_submit_command

splitting this off from the main command

DEPRACATED process_batch_command

Command that hpcrunner.pl execute_job/execute_array uses

=cut

sub process_submit_command {
    my $self    = shift;
    my $counter = shift;

    my $command = "";

    my $logname = $self->create_log_name($counter);

    $self->jobs->{ $self->current_job }->add_lognames($logname);

    $command = "sleep 20\n";
    $command .= "cd " . getcwd() . "\n";
    if ( $self->has_custom_command ) {
        $command .= $self->custom_command . " \\\n";
    }
    else {
        $command .= "hpcrunner.pl " . $self->subcommand . " \\\n";
    }

    $command .= "\t--project " . $self->project . " \\\n" if $self->has_project;

    my $batch_index_start = $self->gen_batch_index_str;

    my $log = "";
    if ( $self->no_log_json ) {
        $log =  "\t--no_log_json \\\n";
    }

    $command .=
        "\t--infile "
      . $self->cmdfile . " \\\n"
      . "\t--outdir "
      . $self->outdir . " \\\n"
      . "\t--commands "
      . $self->jobs->{ $self->current_job }->commands_per_node . " \\\n"
      . "\t--batch_index_start "
      . $self->gen_batch_index_str . " \\\n"
      . "\t--procs "
      . $self->jobs->{ $self->current_job }->procs . " \\\n"
      . "\t--logname "
      . $logname . " \\\n"
      . $log
      . "\t--data_tar "
      . $self->data_tar . " \\\n"
      . "\t--process_table "
      . $self->process_table;

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

sub create_log_name {
    my $self    = shift;
    my $counter = shift;

    my $logname;

    if ( $self->has_project ) {
        $logname = $self->project . "_" . $counter . "_" . $self->current_job;
    }
    else {
        $logname = $counter . "_" . $self->current_job;
    }

    return $logname;
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

=head3 process_template

=cut

sub process_template {
    my $self      = shift;
    my $counter   = shift;
    my $command   = shift;
    my $ok        = shift;
    my $array_str = shift;

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

    if ( defined $scheduler_id ) {
        $self->jobs->{ $self->current_job }->add_scheduler_ids($scheduler_id);
    }
    else {
        $self->jobs->{ $self->current_job }->add_scheduler_ids('000xxx');
    }
}

=head3 submit_to_scheduler

Submit the job to the scheduler.

Inputs: self, submit_command (sbatch, qsub, etc)

Returns: exitcode, stdout, stderr

This subroutine was just about 100% from the following perlmonks discussions. All that I did was add in some logging.

http://www.perlmonks.org/?node_id=151886

This is probably overkill - but occasionally the scheduler takes longer than we think to exit

=cut

sub submit_to_scheduler {
    my $self           = shift;
    my $submit_command = shift;

    my ( $infh, $outfh, $errfh, $exitcode, $cmdpid, $stdout, $stderr );
    $errfh = gensym();
    try {
        $cmdpid = open3( $infh, $outfh, $errfh, $submit_command );
    }
    catch {
        $exitcode = $?;
        $self->app_log->fatal( 'Cmd failed : ' . $submit_command );
        $self->app_log->fatal( 'Cmd failed with exitcode ' . $exitcode );
        return [ $exitcode, '', $@ ];
    };

    return unless $cmdpid;

    my $sel = new IO::Select;    # create a select object
    $sel->add( $outfh, $errfh ); # and add the fhs

    while ( my @ready = $sel->can_read ) {
        foreach my $fh (@ready) {    # loop through them
            my $line;
            my $len = sysread $fh, $line, 4096;
            next unless defined $len;
            if ( $len == 0 ) {
                $sel->remove($fh);
                close($fh);
            }
            else {                   # we read data alright
                if ( $fh == $outfh ) {
                    $stdout .= $line;
                }
                elsif ( $fh == $errfh ) {
                    $stderr .= $line;
                }
            }
        }
    }

    waitpid( $cmdpid, 1 );
    $exitcode = $?;

    $sel->remove($outfh);
    $sel->remove($infh);

    return ( $exitcode, $stdout, $stderr );
}

sub job_failure {
    my $self = shift;

    $self->log->warn( "Submit scripts will be written, "
          . "but will not be submitted to the queue." );
    $self->log->warn(
"Any pending jobs that depend upon this job will NOT be submitted to the queue."
    );
    $self->log->warn(
        "Please look at your submission scripts in " . $self->outdir );
    $self->log->warn(
        "And your logs in " . $self->logdir . "\nfor more information" );
    $self->log->warn(
"Task dependencies are not calculated until the end of submission ... please to do not exit unless you are sure!"
    );
    $self->jobs->{ $self->current_job }->submission_failure(1);
}

1;
