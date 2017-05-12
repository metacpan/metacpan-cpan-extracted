package ETLp::Execute::Iteration;

use MooseX::Declare;

=head1 NAME

ETLp::Execute::Iteration - Execute an Iterative Pipeline

=head1 DESCRIPTION

Takes the array ref of Pipeline items and executes each item in turn

=head1 METHODS

=head2 new

=head3 parameters

All of the following parameters are mandatory

    * pipeline. an arrayref pipeline items
    * config. The application configuration
    
=head3 retuns

    * void

=cut

class ETLp::Execute::Iteration with ETLp::Role::Config {
    use Try::Tiny;
    use Data::Dumper;
    use File::LocalizeNewlines;
    use File::Basename;
    use File::Copy;
    use Carp;
    use ETLp::Exception;
    
    has 'pipeline' => (is => 'ro', isa => 'ArrayRef', required => 1);
    has 'config'   => (is => 'ro', isa => 'HashRef',  required => 1);
    
    $Data::Dumper::Deparse = 1;
    
    method run {
        my $warning = 0;
        
        try {
            FILE_LOOP: foreach my $filename ($self->_get_source_files) {
                ITEM_LOOP:
                foreach my $item (@{$self->pipeline}) {
                    $self->logger->debug("Item: " . Dumper($item));
    
                    # Create an audit entry for the item
                    my $audit_item = $self->audit->create_item(
                        name  => $item->{name},
                        type  => $item->{type},
                        phase => $item->{phase},
                    );
    
                    # The action to be taken when an error is encountered
                    my $on_error = $item->{on_error}
                        || $self->config->{config}->{on_error}
                        || 'die';
                        
                    $self->logger->debug("On error: $on_error");
                        
                    if ($item->{localize}) {
                        my $f = File::LocalizeNewlines->new();
                        my $count = $f->localize($filename);
                    }
    
                    my $next_file_loop = 0;
                    my $next_item_loop = 0;
                    
                    # Execute the item
                    try {
                        $self->logger->debug("Processing file: $filename");
                        $filename = $item->{runner}($filename);
                        $self->logger->debug("New file name: $filename");
                    } catch {
                        my $error = "Error processing $filename: $_";
                        my $fail_dir = $self->config->{config}->{fail_dir};
                        
                        move $filename, $fail_dir ||
                            ETLpException->throw(error =>
                                "Cannot move $filename to $fail_dir: $!");
                            
                        $filename = $fail_dir .'/' . basename($filename);
                        
                        $audit_item->update_message(''.$error);
                        $audit_item->update_status('failed');
                        
                        if ($on_error eq 'die') {
                            ETLpException->throw(error => $error);
                        }
                        $warning = 1;
                        
                        $self->logger->error($error);
                        
                        # Can't go to next loop item from within the catch
                        # block so set the flags to do it later
                        $next_file_loop = 1 if ($on_error eq 'skip');
                        $next_item_loop = 1 if ($on_error eq 'ignore');
                    };
                    
                    next FILE_LOOP if $next_file_loop;
                    next ITEM_LOOP if $next_item_loop;
                    
                    # Yay, it worked!
                    $audit_item->update_status('succeeded');
                }
            }            
        } catch {
            my $error = $_;
            if (ref $error eq 'ETLpException') {                
                $self->logger->error($error->error);
                $self->audit->update_message($error->error);
            } else {                
                $self->logger->error($error);
                $self->audit->update_message($error);
            }
            $self->audit->update_status('failed');
            $error->rethrow;
        };
        
        if ($warning) {
            $self->audit->update_status('warning');
        } else {
            $self->audit->update_status('succeeded');
        }
    }
    
    # Get a list of files to process
    method _get_source_files {
        my $incoming_dir = $self->config->{config}->{incoming_dir} ||
            ETLpException->throw(error =>"incoming_dir is not defined");
        my $filename_format = $self->config->{config}->{filename_format} ||
            ETLpException->throw(error => "filename_format is not defined");
            
        $filename_format = '\/' . $filename_format
            unless (substr($filename_format, 0, 2) eq '\/');
            
        $self->logger->debug('Getting the source files');
        $self->logger->debug("Incoming dir: $incoming_dir");
        $self->logger->debug("filename format: $filename_format");
        
        my @all_sources_files = glob("$incoming_dir/*");
    
        $self->logger->debug("All files: " . Dumper(\@all_sources_files));
        my @files =
            #map { $incoming_dir . '/' . $_ }
            grep(/$filename_format/, @all_sources_files);
    
        $self->logger->debug("File to load: " . Dumper(\@files));
    
        return @files;
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application


