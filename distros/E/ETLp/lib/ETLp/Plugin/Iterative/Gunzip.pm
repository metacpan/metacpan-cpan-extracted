package ETLp::Plugin::Iterative::Gunzip;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::Gunzip - Plugin to gunzip files

=cut

class ETLp::Plugin::Iterative::Gunzip extends ETLp::Plugin {
    use IO::Uncompress::Gunzip qw($GunzipError);
    
=head1 METHODS

=head2 type 

Registers the plugin type.

=cut

    sub type {
        return 'gunzip';
    }
    
=head2 run

Gunzips the supplied filename. Will not proceed if the name ends in .gz

=head3 paramaters

    * filename - the name of the file to be gunzipped
    
-head3 returns

    * new filename - the name for the file following gunzipping

=cut

    method run (Str $filename) {
        my $file_process = $self->audit->item->file_process;
        my $output; 
    
        if ($filename =~ /(.*)\.gz$/) {
            $output = $1;
        } else {
            $self->logger->debug("$filename is not gzipped");
            $file_process->update_message("file is not gzipped");
            return $filename;
        }
    
        unless (IO::Uncompress::Gunzip::gunzip $filename => $output) {
            unlink $output if -f $output;
            ETLpException->throw(error => $GunzipError);
        };
    
        unlink $filename;
        $file_process->update_message("file gunzipped");
        return $output;
        
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application