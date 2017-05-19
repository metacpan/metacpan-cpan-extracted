package HPC::Runner::Command::execute_job::Utils::Log;

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;

use IPC::Open3;
use IO::Select;
use Symbol;

# use Log::Log4perl qw(:easy);
# use Data::Dumper;
# use DateTime;
# use DateTime::Format::Duration;
# use Cwd;
# use File::Path qw(make_path);
# use File::Spec;

with 'HPC::Runner::Command::Utils::Log';

##Command Log
has 'command_log' => ( is => 'rw', );

#TODO This should be changed to execute_jobs Logging
#We also have task_tags as an ArrayRef for JobDeps

has 'task_tags' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        set_task_tag     => 'set',
        get_task_tag     => 'get',
        has_no_task_tags => 'is_empty',
        num_task_tags    => 'count',
        delete_task_tag  => 'delete',
        task_tag_pairs   => 'kv',
    },
);

#TODO This should be changed to execute_jobs Logging
#We also have task_tags as an ArrayRef for JobDeps

# has 'task_deps' => (
#     traits  => ['Hash'],
#     is      => 'rw',
#     isa     => 'HashRef',
#     default => sub { {} },
#     handles => {
#         set_task_dep     => 'set',
#         get_task_dep     => 'get',
#         has_no_task_deps => 'is_empty',
#         num_task_deps    => 'count',
#         delete_task_dep  => 'delete',
#         task_dep_pairs   => 'kv',
#     },
# );

=head3 table_data

Each time we make an update to the table throw it in here

=cut

has 'table_data' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        set_table_data    => 'set',
        get_table_data    => 'get',
        delete_table_data => 'delete',
        has_no_table_data => 'is_empty',
        num_table_data    => 'count',
        table_data_pairs  => 'kv',
        clear_table_data  => 'clear',
    },
);

#TODO Move this to App/execute_job/Log ... something to mark that this logs the
#individual processes that are executed

=head3 _log_commands

Log the commands run them. Cat stdout/err with IO::Select so we hopefully don't break things.

This example was just about 100% from the following perlmonks discussions.

http://www.perlmonks.org/?node_id=151886

You can use the script at the top to test the runner. Just download it, make it executable, and put it in the infile as

perl command.pl 1
perl command.pl 2
#so on and so forth

=cut

sub _log_commands {
    my ( $self, $pid ) = @_;

    my $dt1 = DateTime->now( time_zone => 'local' );

    $DB::single = 2;
    my $ymd = $dt1->ymd();
    my $hms = $dt1->hms();

    $self->clear_table_data;
    $self->set_table_data( start_time => "$ymd $hms" );

    my ( $cmdpid, $exitcode ) = $self->log_job;

    #TODO Make table data its own class and return it
    $self->set_table_data( cmdpid     => $cmdpid );

    my $meta = $self->pop_note_meta;
    $self->set_task_tag( $cmdpid => $meta ) if $meta;

    $self->log_cmd_messages( "info",
        "Finishing job " . $self->counter . " with ExitCode $exitcode",
        $cmdpid );

    my $dt2      = DateTime->now();
    my $duration = $dt2 - $dt1;
    my $format   = DateTime::Format::Duration->new( pattern =>
          ' %e days, %H hours, %M minutes, %S seconds' );

    $self->log_cmd_messages( "info",
        "Total execution time " . $format->format_duration($duration),
        $cmdpid );

    $self->log_table( $cmdpid, $exitcode, $format->format_duration($duration) );

    return $exitcode;
}

=head3 name_log

Default is dt, jobname, counter

=cut

#TODO move to execute_jobs

sub name_log {
    my $self   = shift;
    my $cmdpid = shift;

    my $counter = $self->counter;

    $self->logfile( $self->set_logfile );
    $counter = sprintf( "%03d", $counter );
    $self->append_logfile( "-CMD_" . $counter . "-$cmdpid.md" );

    $self->set_task_tag( "$counter" => $cmdpid );
}

#TODO move to execute_jobs

sub log_table {
    my $self     = shift;
    my $cmdpid   = shift;
    my $exitcode = shift;
    my $duration = shift;

    my $dt1 = DateTime->now( time_zone => 'local' );
    my $ymd = $dt1->ymd();
    my $hms = $dt1->hms();

    $self->set_table_data( exit_time => "$ymd $hms" );
    $self->set_table_data( exitcode  => $exitcode );
    $self->set_table_data( duration  => $duration );

    my $version = $self->version || "0.0";
    my $task_tags = "";

    my $logfile = $self->logdir . "/" . $self->logfile;

    open( my $pidtablefh, ">>" . $self->process_table )
      or die $self->app_log->fatal("Couldn't open process file $!\n");

    #or die print "Couldn't open process file $!\n";

    if ( $self->can('task_tags') ) {
        my $aref = $self->get_task_tag($cmdpid) || [];
        $task_tags = join( ", ", @{$aref} ) || "";

        $self->set_table_data( task_tags => $task_tags );
    }

    if ( $self->can('version') && $self->has_version ) {
        $version = $self->version;
        $self->set_table_data( version => $version );
    }

    if ( $self->can('job_scheduler_id') && $self->can('jobname') ) {
        my $schedulerid = $self->job_scheduler_id || '';

        my $jobname = $self->jobname || '';
        print $pidtablefh <<EOF;
|$version|$schedulerid|$jobname|$task_tags|$cmdpid|$exitcode|$duration|
EOF

        $self->set_table_data( schedulerid => $schedulerid );
        $self->set_table_data( jobname     => $jobname );
    }
    else {
        print $pidtablefh <<EOF;
|$cmdpid|$exitcode|$duration|
EOF
    }
}

#TODO move to execute_jobs

sub log_cmd_messages {
    my ( $self, $level, $message, $cmdpid ) = @_;

    return unless $message;
    return unless $level;

    if ( $self->show_processid && $cmdpid ) {
        $self->command_log->$level("PID: $cmdpid\t$message");
    }
    else {
        $self->command_log->$level($message);
    }
}


#TODO move to execute_jobs
sub log_job {
    my $self = shift;

    #Start running job
    my ( $infh, $outfh, $errfh );
    $errfh = gensym();    # if you uncomment this line, $errfh will
    my $cmdpid;
    eval { $cmdpid = open3( $infh, $outfh, $errfh, $self->cmd ); };

    if ($@) {
        die $self->app_log->fatal(
            "There was an error running the command $@\n");
    }

    if ( !$cmdpid ) {
        $self->app_log->fatal(
"There is no process id please contact your administrator with the full command\n"
        );
        die;
    }

    $infh->autoflush();

    # Start Command Log
    $self->start_command_log($cmdpid);

    $DB::single = 2;

    my $sel = new IO::Select;    # create a select object
    $sel->add( $outfh, $errfh ); # and add the fhs

    while ( my @ready = $sel->can_read ) {
        foreach my $fh (@ready) {    # loop through them
            my $line;

            # read up to 4096 bytes from this fh.
            my $len = sysread $fh, $line, 4096;
            if ( not defined $len ) {

                # There was an error reading
                $self->log_cmd_messages( "fatal", "Error from child: $!",
                    $cmdpid );
            }
            elsif ( $len == 0 ) {

                # Finished reading from this FH because we read
                # 0 bytes.  Remove this handle from $sel.
                $sel->remove($fh);
                next;
            }
            else {    # we read data alright
                if ( $fh == $outfh ) {
                    $self->log_cmd_messages( "info", $line, $cmdpid );
                }
                elsif ( $fh == $errfh ) {
                    $self->log_cmd_messages( "error", $line, $cmdpid );
                }
                else {
                    $self->log_cmd_messages( 'fatal', "Shouldn't be here!\n" );
                }
            }
        }
    }

    waitpid( $cmdpid, 1 );
    my $exitcode = $?;

    return ( $cmdpid, $exitcode );
}

=head3 start_command_log

Initialize the command log

Print out command info - schedulerId, taskId, cmdPID, etc.

=cut

sub start_command_log {
  my $self = shift;
  my $cmdpid = shift;

    if ( $self->job_scheduler_id ) {
        $self->name_log( "_SID_" . $self->job_scheduler_id . "_PID_" . $cmdpid );
    }
    else {
        $self->name_log( "PID_" . $cmdpid );
    }

    $self->command_log( $self->init_log );

    $DB::single = 2;

    $self->log_cmd_messages(
        "info",
        "\nStarting Job:\n\tJobID:\t"
          . $self->job_scheduler_id
          . " \n\tCmdPID:\t"
          . $cmdpid
          . "\n\n\n",
        $cmdpid
    );

    my $log_array_msg = "";
    if($self->can('task_id')){
      $log_array_msg = "Array ID:\t".$self->task_id;
    }

    $self->log_cmd_messages(
     "info",
     "\nHostname:\t".$self->hostname."\n"."Job Scheduler ID:\t".$self->job_scheduler_id."$log_array_msg\n\n"
    );

    #TODO counter is not terribly applicable with task ids
    $self->log_cmd_messages(
        "info",
        "Starting execution: "
          . $self->counter
          . "\n\nCOMMAND:\n"
          . $self->cmd
          . "\n\n\n",
        $cmdpid
    );
}

sub pop_note_meta {
    my $self = shift;

    my $lines = $self->cmd;
    return unless $lines;
    my @lines = split( "\n", $lines );
    my @ts = ();

    foreach my $line (@lines) {
        next unless $line;
        next unless $line =~ m/^#TASK/;

        my ( @match, $t1, $t2 );
        @match = $line =~ m/TASK (\w+)=(.+)$/;
        ( $t1, $t2 ) = ( $match[0], $match[1] );

        $DB::single = 2;
        if ($t1) {
            if ( $t1 eq "tags" ) {
                my @tmp = split( ",", $t2 );
                map { push( @ts, $_ ) } @tmp;
            }
            elsif ( $t1 eq "deps" ) {
                my @tmp = split( ",", $t2 );
                map { push( @ts, $_ ) } @tmp;
            }
            else {
                #We should give a warning here
                $self->$t1($t2);
                $self->log_main_messages( 'debug',
                        "Command:\n\t"
                      . $self->cmd
                      . "\nHas invalid #TASK attribute. Should be #TASK tags=thing1,thing2 or #TASK deps=thing1,thing2"
                );
            }
        }
    }
    return \@ts;
}
1;
