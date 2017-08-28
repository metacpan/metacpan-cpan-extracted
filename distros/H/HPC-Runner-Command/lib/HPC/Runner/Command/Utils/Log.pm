package HPC::Runner::Command::Utils::Log;

use Log::Log4perl qw(:easy);
use Data::Dumper;
use IPC::Open3;
use IO::Select;
use Symbol;
use DateTime;
use DateTime::Format::Duration;
use Cwd;
use File::Path qw(make_path);
use File::Spec;
use File::Slurp;

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;
use Path::Tiny;

=head1 HPC::Runner::Command::Utils::Log

Class for all logging attributes

=head2 Command Line Options


=head3 logdir

Pattern to use to write out logs directory. Defaults to outdir/prunner_current_date_time/log1 .. log2 .. log3.

=cut

option 'logdir' => (
    is       => 'rw',
    isa      => AbsPath,
    coerce   => 1,
    lazy     => 1,
    required => 1,
    default  => sub {
        my $self = shift;
        $self->set_logdir;
    },
    documentation => 'Directory where logfiles are written.'
      . ' Defaults to current_working_directory/prunner_current_date_time/log1 .. log2 .. log3',
    trigger => sub {
        my $self = shift;
        my $val  = shift;
        $self->_make_the_dirs($val);
    },
);

=head3 show_process_id

Show process_id in each log file. This is useful for aggregating logs

=cut

option 'show_processid' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Show the process ID per logging message. '
      . 'This is useful when aggregating logs.',
);

=head3 process_table

We also want to write all cmds and exit codes to a table

#TODO add a json format also

=cut

option 'process_table' => (
    isa     => Path,
    is      => 'rw',
    lazy    => 1,
    coerce  => 1,
    default => sub {
        my $self = shift;
        make_path( $self->logdir );
        my $process_table =
          File::Spec->catdir( $self->logdir, "001-task_table.md" );
        $process_table = path($process_table);
        $process_table->touchpath;

        my $header =
"|| Version || Scheduler Id || Jobname || Task Tags || ProcessID || ExitCode || Duration ||\n";
        write_file( $process_table, { append => 1 }, $header )
          or $self->app_log->warn("Couldn't open process file! $!\n");

        return $process_table;
    },
    trigger => sub {
        my $self = shift;
        $self->process_table->touchpath;
    },
);

=head3 metastr

JSON string passed from HPC::Runner::App::Scheduler. It describes the total number of jobs, processes, and job batches.

=cut

option 'metastr' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q{Meta str passed from HPC::Runner::Command::Scheduler},
    required      => 0,
);

option 'logname' => (
    isa      => 'Str',
    is       => 'rw',
    default  => 'hpcrunner_logs',
    required => 0,
);

=head2 Internal Attributes

You shouldn't be calling these directly.

=cut

has 'dt' => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { return DateTime->now( time_zone => 'local' ); },
    lazy    => 1,
);

##TODO Put this in its own class
##Application log
has 'app_log' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $file_name = File::Spec->catdir( $self->logdir, 'main.log' );
        $self->_make_the_dirs( $self->logdir );
        my $log_conf = q(
log4perl.category = INFO, FILELOG, Screen
log4perl.appender.Screen = \
    Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
    Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
    [%d] %m %n
log4perl.appender.FILELOG           = Log::Log4perl::Appender::File
log4perl.appender.FILELOG.mode      = append
log4perl.appender.FILELOG.layout    = Log::Log4perl::Layout::PatternLayout
log4perl.appender.FILELOG.layout.ConversionPattern = %d %p %m %n
        );
        $log_conf .= "log4perl.appender.FILELOG.filename  = $file_name";

        Log::Log4perl->init( \$log_conf );
        return get_logger();
    }
);

##Submit Log
has 'log' => (
    is      => 'rw',
    default => sub { my $self = shift; return $self->init_log },
    lazy    => 1
);

has 'logfile' => (
    traits  => ['String'],
    is      => 'rw',
    default => \&set_logfile,
    handles => {
        append_logfile  => 'append',
        prepend_logfile => 'prepend',
        clear_logfile   => 'clear',
    }
);

=head2 Subroutines

=head3 set_logdir

Set the log directory

=cut

sub set_logdir {
    my $self = shift;

    my $logdir;

    if ( $self->has_version ) {
        if ( $self->has_project ) {
            $logdir =
              File::Spec->catdir( 'hpc-runner', $self->version, $self->project,
                'logs', $self->set_logfile . '-' . $self->logname );
        }
        else {
            $logdir =
              File::Spec->catdir( 'hpc-runner', $self->version,
                'logs', $self->set_logfile . '-' . $self->logname );
        }
    }
    else {
        if ( $self->has_project ) {
            $logdir =
              File::Spec->catdir( 'hpc-runner', $self->project,
                'logs', $self->set_logfile . '-' . $self->logname );
        }
        else {
            $logdir =
              File::Spec->catdir( 'hpc-runner',
                'logs', $self->set_logfile . '-' . $self->logname );
        }
    }

    $logdir =~ s/\.log$//;

    # my $dt = DateTime->now( time_zone => 'local' );
    # $dt = "$dt";
    # $dt =~ s/:/-/g;
    #
    # $logdir = File::Spec->catdir( $logdir, $dt );

    $self->_make_the_dirs($logdir);

    return $logdir;
}

=head3 set_logfile

Set logfile

=cut

sub set_logfile {
    my $self = shift;

    my $tt = DateTime->now( time_zone => 'local' )->ymd();
    return "$tt";
}

=head3 init_log

Initialize Log4perl log

=cut

sub init_log {
    my $self = shift;

    Log::Log4perl->easy_init(
        {
            level => $TRACE,
            utf8  => 1,
            mode  => 'append',
            file  => ">>" . File::Spec->catdir( $self->logdir, $self->logfile ),
            layout => '%d: %p %m%n '
        }
    );

    my $log = get_logger();
    return $log;
}

sub log_main_messages {
    my ( $self, $level, $message ) = @_;

    return unless $message;
    $level = 'info' unless $level;
    $self->log->$level($message);
}

1;
