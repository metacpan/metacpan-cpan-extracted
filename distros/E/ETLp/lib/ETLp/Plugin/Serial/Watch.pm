package ETLp::Plugin::Serial::Watch;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Serial::Watch - Plugin for File Watcher

=head1 DESCRIPTION

A file watcher is is a process that waits for the existence of a file
before calling the next job for further processing

=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the supplied perl code.

=head3 parameters

    * none
    
=head3 returns

    * void
    
=head1 ITEM

The item attribute hashref contains specific configuration information
for ETLp::Plugin::Serial::OS

=head2 command

The operating system command being run

=head2 timeout

This is an optional parameter that specifies when the command execution
should abort (in seconds).

=cut

class ETLp::Plugin::Serial::Watch extends ETLp::Plugin {
    use ETLp::File::Watch;
    use Data::Dumper;
    
    sub type {
        return 'watch';
    }
    
    method run {
        my $item = $self->item;
        my $directory = $self->config->{config}->{directory} ||
            ETLpException->throw("Directory not defined");
            
        $self->logger->debug("Directory: $directory");

        my $fw = ETLp::File::Watch->new(
            directory         => $directory,
            file_pattern      => $item->{file_pattern},
            call              => $self->config->{config}->{call},
            wait_time         => $item->{wait_time} || 1,
            duration          => $item->{duration},
            raise_no_file_error  => $item->{no_file_error} || 0,
            exit_on_detection => $item->{exit_on_detection}|| 0,
        );

        my $res = $fw->watch;
        
        if ($res == 1) {
            $self->audit->item->update_message('File(s) detected');
        } else {
            $self->audit->item->update_message('No file(s) detected');
        }
    }
    
}


