package ETLp::Plugin::Iterative::OS;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::OS - Plugin for calling the Operating System

=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the supplied Command.

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

class ETLp::Plugin::Serial::OS extends ETLp::Plugin {
    use Data::Dumper;
    
    sub type {
        return 'os';
    }
    
    method run {
        my $item    = $self->item;
        my $command = $item->{command};
        my $timeout = $item->{timeout} || 20;
        
        $self->logger->debug(Dumper($self->config));

        my $message;

        $self->logger->debug("Raw command:\n$command");
        $self->logger->debug("Timeout:\n$timeout");

        my $audit_item = $self->audit->item;

        if ($item->{hide_command}) {
            $message = $self->original_item->{command};
        } else {
            $message = $command;
        }

        $audit_item->update_message($message);

        my $cmd = ETLp::Utility::Command->new(time_out => $timeout);

        my ($output, $retcode) = $cmd->run($command);

        if ($retcode || $cmd->errstr) {
            $self->logger->error("OS execution error:\n" . $cmd->errstr);
            ETLpException->throw(error => "Error running:\n$message:\n" .
                "$output\n".                 $cmd->errstr);
        }

        $audit_item->update_message($message . "\n" . $output);
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application