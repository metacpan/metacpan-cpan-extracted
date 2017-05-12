package ETLp::Plugin::Iterative::Perl;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::Perl - Plugin for calling Perl subroutines

=cut

class ETLp::Plugin::Iterative::Perl extends ETLp::Plugin {
    use File::Basename;
    use UNIVERSAL::require;
    use Try::Tiny;
    
=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the pipeline

=cut

    sub type {
        return 'perl';
    }
    
    method run (Str $filename) {
        my $item = $self->item;
        my $package  = $item->{package};
        my $sub      = $item->{sub};
        my $params   = $item->{params};
        my $interim_params;
        
        my $call = "\$filename = ${package}::$sub($params)";
        $self->logger->debug("Call: $call");
        
        my $file_process = $self->audit->item->file_process;
        
        try {
            $package->require;
            eval "$call" ||
                ETLpException->throw(error =>"Unable to run $call: $!");
        } catch {
            my $error = $_;
            
            if (ref $error) {
                my $message = $call . ' ' . $error->error;
                $file_process->update_message($message);
                $file_process->update_status('failed');
                $error->rethrow;
            }
            
            my $message = $call . ' ' . $error;
            
            $file_process->update_message($message);
            $file_process->update_status('failed');
                
            $self->logger->debug("Not an ETLpException");
            ETLpException->throw(error => $error);
        };
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application