package HPC::Runner::Command::execute_job::Utils::MCE;

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;

with 'HPC::Runner::Command::execute_job::Base';

use MCE;
use MCE::Queue;
use DateTime;
use DateTime::Format::Duration;
use Memoize;

=head1 HPC::Runner::App::MCE

Execute the job.

=cut

=head2 Command Line Options

=cut

option 'commands' => (
    is       => 'rw',
    isa      => 'Num',
    required => 0,
    default  => 1,
);

has 'read_command' => (
    is        => 'rw',
    isa       => 'Num|Undef',
    required  => 0,
    predicate => 'has_read_command',
    lazy      => 1,
    default   => sub {
        my $self = shift;
        if ( $self->can('task_id') && $self->can('batch_index_start') ) {
            return $self->task_id - $self->batch_index_start - 1;
        }
        elsif ( $self->can('batch_index_start') ) {
            return $self->batch_index_start;
        }
        else {
            $self->log->fatal(
                'Not able to determine job execution type.  Exiting.');
            exit 1;
        }
    }
);

option 'single_node' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    handles => {
        'not_single_node' => 'not',
    }
);

=head3 jobname

Specify a job name, and jobs will be 001_jobname, 002_jobname, 003_jobname

=cut

option 'jobname' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    traits   => ['String'],
    default  => q{job},
    default  => sub {
        return
             $ENV{SLURM_JOB_NAME}
          || $ENV{SBATCH_JOB_NAME}
          || $ENV{PBS_JOBNAME}
          || 'job';
    },
    predicate => 'has_jobname',
    handles   => {
        add_jobname   => 'append',
        clear_jobname => 'clear',
    },
    documentation =>
      q{Specify a job name, each job will be appended with its batch order},
);

=head2 Attributes

=cut

has 'queue' => (
    is   => 'rw',
    lazy => 0,     ## must be 0 to ensure the queue is created prior to spawning
    default => sub {
        my $self = shift;
        return MCE::Queue->new();
    }
);

has 'mce' => (
    is      => 'rw',
    lazy    => 1,
    clearer => '_clear_mce',
    default => sub {
        my $self = shift;
        return MCE->new(
            max_workers => $self->procs,
            use_threads => 0,
            user_func   => sub {
                my $mce = shift;
                while (1) {
                    my ( $counter, $cmd ) = $self->queue->dequeue(2);
                    last unless defined $counter;
                    $self->counter($counter);
                    $self->cmd($cmd);
                    $self->run_command_mce();
                }
            }
        );
    }
);

has 'using_mce' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 1,
    required => 1,
);

=head2 Subroutines

=cut

=head3 go

Initialize MCE queues

=cut

sub run_mce {
    my $self = shift;

    my $dt1 = DateTime->now();

    $self->prepend_logfile("MAIN_");
    $self->append_logfile(".log");
    $self->log( $self->init_log );

    $self->mce->spawn;

    #MCE specific
    $self->parse_file_mce;

    #$DB::single = 2;

    # MCE workers dequeue 2 elements at a time. Thus the reason for * 2.
    $self->queue->enqueue( (undef) x ( $self->procs * 2 ) );

    # MCE will automatically shutdown after running for 1 or no args.
    $self->mce->run(1);

    #End MCE specific

    my $dt2      = DateTime->now();
    my $duration = $dt2 - $dt1;
    my $format   = DateTime::Format::Duration->new( pattern =>
          '%Y years, %m months, %e days, %H hours, %M minutes, %S seconds' );

    $self->log_main_messages( 'info',
        "Total execution time " . $format->format_duration($duration) );
    return;
}

=head3 parse_file_mce

The default method of parsing the file.

    #starts a comment
    wait - says wait until all other processes/threads exitcode

    #this is a one line command
    echo "starting"

    #This is a multiline command
    echo "starting line 1" \
        echo "starting line 2" \
        echo "finishing

=cut

sub parse_file_mce {
    my $self = shift;

    $self->process_table;
    
    my $fh = IO::File->new( $self->infile, q{<} )
      or $self->log_main_messages( "fatal",
        "Error opening file  " . $self->infile . "  " . $! );
    die print "The infile does not exist!\n" unless $fh;

    if ( $self->single_node ) {
        $self->log_main_messages( 'info', 'Running in single node mode' );
        while (<$fh>) {
            my $line = $_;
            $self->process_lines($line);
        }
    }
    elsif ( defined $self->read_command ) {
        $self->log_main_messages( 'info',
            'Executing Command # ' . $self->read_command );
        my $cmds = $self->parse_cmd_file($fh);

        foreach my $cmd (@$cmds) {
            map { $self->process_lines( $_ . "\n" ) } split( "\n", $cmd );
            $self->wait(0);
        }
    }
    else {
        $self->log_main_messages( 'fatal', 'No running mode found. Exiting' );
        exit 1;
    }
}

sub parse_cmd_file {
    my $self = shift;
    my $fh   = shift;

    my $x         = 0;
    my $add_cmds  = 0;
    my $cmd_count = 0;

    my @cmds = ();
    my $cmd  = '';
    while (<$fh>) {
        my $line = $_;
        next unless $line;

        $cmd .= $line;
        next if $line =~ m/\\$/;
        next if $line =~ m/^#/;
        if ( $x == $self->read_command && $cmd_count <= $self->commands ) {
            $add_cmds = 1;
        }
        if ($add_cmds) {
            push( @cmds, $cmd );
            $cmd_count++;
        }
        $x++;

        if ( $x >= $self->read_command && $cmd_count >= $self->commands ) {
            last;
        }
        $cmd = '';
    }

    close($fh);
    return \@cmds;
}

##TODO separate out single node mode
sub process_lines {
    my $self = shift;
    my $line = shift;

    if ( $line =~ m/^#TASK/ ) {
        $self->add_cmd($line);
    }

    $self->check_single_node($line) if $self->single_node;

    return if $line =~ m/^#/;
    $self->add_cmd($line);

    ##Bash style we continue to the next lime if the current line ends in \
    return if $line =~ m/\\$/;
    if ( $self->match_cmd(qr/^wait$/) ) {
        $self->hold_pool;
    }
    else {
        $self->add_pool;
    }
}

sub check_single_node {
    my $self = shift;
    my $line = shift;

    if ( $line =~ m/^#HPC jobname=/ ) {
        $self->hold_pool;
        $self->_clear_mce;
        my ( $t1, $t2 ) = parse_meta($line);
        $self->jobname($t2);
        ##Trigger outdir
        $self->logname($t2);
        $self->logfile( $self->set_logfile );
        $self->logdir( $self->set_logdir );
    }
    if ( $line =~ m/^#HPC procs=/ ) {
        $self->hold_pool;
        $self->_clear_mce;
        my ( $t1, $t2 ) = parse_meta($line);
        $self->procs($t2);
        $self->hold_pool;
    }
}

sub add_pool {
    my $self = shift;
    $self->log_main_messages( 'debug', "Enqueuing command:\n\t" . $self->cmd );

    $self->queue->enqueue( $self->counter, $self->cmd )
      if $self->has_cmd;
    $self->clear_cmd;
    $self->inc_counter;
}

sub hold_pool {
    my $self = shift;

    $self->log_main_messages( 'debug', "Beginning command:\n\t" . $self->cmd )
      if $self->has_cmd;
    $self->log_main_messages( 'debug',
        'Waiting for all threads to complete...' )
      if $self->has_cmd;

    $self->wait(1);
    push( @{ $self->jobref }, [] );
    $self->queue->enqueue( (undef) x ( $self->procs * 2 ) );
    $self->mce->run(0);    # 0 indicates do not shutdown after running

    $self->log_main_messages( 'debug',
        'All children have completed processing!' );
    $self->clear_cmd;
}

memoize('parse_meta');

sub parse_meta {
    my $line = shift;
    my ( @match, $t1, $t2 );

    @match = $line =~ m/ (\w+)=(.+)$/;
    ( $t1, $t2 ) = ( $match[0], $match[1] );

    return ( $t1, $2 );
}

=head3 run_command_mce

MCE knows which subcommand to use from Runner/MCE - object mce

=cut

sub run_command_mce {
    my $self = shift;

    my $pid = $$;

    #$DB::single = 2;

    push( @{ $self->jobref->[-1] }, $pid );
    $self->_log_commands($pid);

    return;
}

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>
Mario Roy E<lt>marioeroy@gmail.comE<gt>

=cut

1;
