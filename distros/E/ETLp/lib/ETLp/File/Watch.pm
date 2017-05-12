package ETLp::File::Watch;

use MooseX::Declare;

=head1 NAME

ETLp::File::Watch - Waits for the appearance of a specific file or
  one or more files that match the supplied patterns

=head1 SYNOPSIS

A watcher will look for the existence of a file matching the supplied pattern
(glob not regex) and then exits. Generally it signals that processing is
required by the next item in the pipeline (which will generally want to use
the file that matches that pattern).

Generally, detection of a file matching the pattern shouldn't be sufficient
grounds for a watcher to exit. It should poll the file size at intervals to
determine whether it is still growing. A watcher should only exit when the file
size stops changing.

    use ETLp::File::Watch;

    my $watcher = ETLp::File::Watch->new(
        directory    => "$Bin/../incoming",
        file_pattern => 'data*.zip',
        duration     => '5h'
    );
   
    unless ($watcher->watch() {
        die "file not detected";
    }
   
=head1 METHODS

=head2 new

Creates a new watcher

=head3 Parameters

A hashref containing:

    * directory. Optional string. The location of the watch file
    * file_pattern: Required string. The pattern (glob) that the watcher is
      waiting for
    * call: Required string. The config file and section to invoke when a file
      is successfully found
    * duration. Required. How long the watcher should wait before giving up. The
      time can be specified by the duration (integer) followed by s, m, h or d -
      (seconds, minutes, hours or days)
    * wait_time. Optional integer. The time in seconds between each iteration of the
      check. Defaults to 1
    * raise_no_file_error. Optional boolean. If set to 1, an error will be raised if the
      watcher expires without encountering a file. Deafults to 0.
    * exit_on_detection. Optional boolean. If set to 1
   
=head3 Returns

    * A file watcher
   
=head2 watch

Watches for the existence of a file pattern

=head3 Parameters

    * None
   
=head3 Returns

    * Void

=cut

class ETLp::File::Watch with ETLp::Role::Config {
    use Moose;
    use DateTime;
    use FindBin qw($Bin);
    use Fcntl ':flock';
    use ETLp::Utility::Command;
    use ETLp::Types;
    use ETLp::Exception;
    use Try::Tiny;

    has 'directory'    => (is => 'ro', isa => 'Str');
    has 'file_pattern' => (is => 'rw', isa => 'Str', required => 1);
    has 'call'         => (is => 'ro', isa => 'Str', required => 1);
    has 'wait_time'    =>
        (is => 'ro', isa => 'PositiveInt', required => 0, default => 1);
    has 'duration' => (is => 'ro', isa => 'Str', required => 1);
    has 'raise_no_file_error' =>
        (is => 'ro', isa => 'Bool', required => 0, default => 0);
    has 'exit_on_detection' =>
        (is => 'ro', isa => 'Bool', required => 0, default => 0);
    
    use constant UNIT_MAP => {
        s => 'seconds',
        m => 'minutes',
        h => 'hours',
        d => 'days'
    };
    
    method watch {
        my $file_pattern = $self->{_file_pattern};
        my $file_found   = 0;
    
        $self->logger->info("Waiting for file: $file_pattern");
    
        my $dt = DateTime->now;
    
        # Add the duration to the current time. This is when the watcher
        # should stop
        if ($self->duration =~ /^\s*(\d+)\s*(s|m|h|d)\s*$/) {
            my $measure = $1;
            my $unit    = $2;
    
            $dt->add(UNIT_MAP->{$unit} => $measure);
        } else {
            ETLpException->throw(
                error => "Invalid duration: " . $self->duration
            );
        }
    
        # The end time as an epoch (which is what the time function returns)
        my $expire_time = $dt->epoch;
    
        while (time < $expire_time) {
    
            my @files = glob($file_pattern);
    
            # unfortunately, globbing returns the original pattern
            # if there is no expansion and no match, so make sure that
            # if there is one "match" that it really is a file
            if (scalar(@files) ==1) {
                if (-f $files[0]) {
                     $file_found = 1;
                     $self->_run_command;
                }
            }
    
            if (scalar(@files) > 1) {
                $file_found = 1;
                $self->_run_command;
            }
           
            last if ($self->exit_on_detection && $file_found);
    
            sleep $self->wait_time;
        }
    
        # Raise an error if we've expired before encountering a file
        if ($file_found == 0) {
            if ($self->raise_no_file_error) {
                ETLpException->throw(error => "No file found");
            }
            return 0;
        }
    
        $self->logger->info('Exiting file watcher');
        return 1;
    }
    
    method _run_command {
        my $command = "$0 " . $self->call;
        my $os      = ETLp::Utility::Command->new();
        
        try {
            $os->run($command)
        } catch {
            ETLpException->throw($_)
        }
    }
    
    method BUILD {
        $self->{_file_pattern} = $self->file_pattern;
    
        if ($self->directory) {
            $self->{_file_pattern} = $self->directory . '/' .
                $self->{_file_pattern};
        }
    }
}
