package ETLp::Plugin::Iterative::Gzip;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::Gzip - Plugin to gzip files

=cut

class ETLp::Plugin::Iterative::Gzip extends ETLp::Plugin {
    use IO::Compress::Gzip qw($GzipError);
    
=head1 METHODS

=head2 type 

Registers the plugin type.

=cut

    sub type {
        return 'gzip';
    }
    
=head2 run

Gzips the supplied filename. Will not proceed if the name ends in .gz

=head3 paramaters

    * filename - the name of the file to be gzipped
    
-head3 returns

    * new filename - the name for the file following

=cut

    method run (Str $filename) {
        my $file_process = $self->audit->item->file_process;
        
        # Don't continue if the file is already gzipped
        if ($filename =~ /\.gz$/) {
            $file_process->update_message("file already gzipped");
            return $filename;
        }
    
        my $output = $filename . '.gz';
    
        unless (IO::Compress::Gzip::gzip $filename => $output) {
            unlink $output;
            ETLpException->throw(error => $GzipError);
        };
    
        unlink $filename;
        $file_process->update_message("file gzipped");
        return $output;
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application