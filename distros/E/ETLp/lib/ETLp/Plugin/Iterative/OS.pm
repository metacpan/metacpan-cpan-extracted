package ETLp::Plugin::Iterative::OS;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::OS - Plugin for calling the Operating System

=cut

class ETLp::Plugin::Iterative::OS extends ETLp::Plugin {
    use File::Basename;
    use ETLp::Utility::Command;
    use Data::Dumper;

=head1 METHODS

=head2 type 

Registers the plugin type.

=cut

    sub type {
        return 'os';
    }

=head2 run

Executes the supplied Command.

=head3 parameters

    * filename - the name of the file currently being processed
    
=head3 returns

    * new filename - the name for the file following
    
=head1 ITEM

The item attribute hashref contains specific configuration information
for ETLp::Plugin::Iterative::OS:

=head2 command

The operating system command being run

=head2 timeout

This is an optional parameter that specifies when the command execution
should abort (in seconds).

=cut

    method run(Str $filename) {
        my $item    = $self->item;
        my $command = $item->{command};
        my $timeout = $item->{timeout} || 20;
        
        $self->logger->debug(Dumper($self->config));

        my $message;

        $self->logger->debug("Raw command:\n$command");
        $self->logger->debug("Timeout:\n$timeout");

        my $aud_file_process = $self->audit->item->file_process;

        if ($item->{hide_command}) {
            $message = $item->{command};
        } else {
            $message = $command;
        }

        $aud_file_process->update_message($message);

        my $cmd = ETLp::Utility::Command->new(time_out => $timeout);

        my ($output, $retcode) = $cmd->run($command);

        if ($retcode || $cmd->errstr) {
            ETLpException->throw(error => "Error running:\n$message:\n" .
                                 $cmd->errstr ."\n" . $retcode);
        }

        $self->audit->item->update_message($message . "\n" . $output);
        $aud_file_process->update_status('succeeded');
        return $filename;
    };
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
