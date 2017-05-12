package ETLp::Audit::FileProcess;

use MooseX::Declare;
use DateTime;

class ETLp::Audit::FileProcess with (ETLp::Role::Config, ETLp::Role::Schema,
                             ETLp::Role::Audit) {
    
    use ETLp::Types;
    use Try::Tiny;
    use ETLp::Exception;
    
    has 'item' =>
      (is => 'ro', isa => 'ETLp::Audit::Item', required => 1, weak_ref => 1);
    has 'filename' => (is => 'ro', isa => 'Str',     required => 1);
    has 'config'   => (is => 'ro', isa => 'HashRef', required => 1);
    
=head2 method_id

Return the primary key of the file process record

=cut
    method id {
        return $self->{id};
    }
    
=head2 canonical_filename

Returns the canonical filename of the file being processed

=cut
    method canonical_filename {
        return $self->{canonical_filename};
    }
  
=head2 details

Returns the current record (as a DBIx::Class Row)

=cut

    method details {
        return $self->EtlpFileProcess->find($self->id);
    }
    
    # create a canonical record for the processed file
    method _create_canonical_record {
        my $now  = $self->now;
        
        my $file = $self->EtlpFile->create(
            {
                canonical_filename => $self->canonical_filename,
                date_created       => $now,
                date_updated       => $now,
            }
        );
        
        return $file->file_id;
    }
    
    # Given the filename and format regex, determine the file format
    method _get_canonical_filename(Str $filename) {
    
        try {
            my $c_regex = $self->config->{config}->{filename_format};
            my $canonical_name;
        
            $self->logger->debug("c_regex $c_regex");
            $self->logger->debug("filename $filename\n");
        
            if ($filename =~ /$c_regex/) {
                $canonical_name = $1;
            }
        
            ETLpException->throw(error =>
                "Cannot determine canonical name for $filename, regex: $c_regex"
            )  unless $canonical_name;
            
            return $canonical_name;
        } catch {
            $self->logger->logdie($_);
        };
    }
    
=head2 get_canonical_id

Return the primary key of the canonical file record

=cut

    method get_canonical_id {
        my $canonical_file = $self->EtlpFile->search(
            {
                canonical_filename => $self->canonical_filename
            }
        )->single;
        
        if ($canonical_file) {
            return $canonical_file->file_id,
        } else {
            return;
        }
    }
    
=head2 update_message

Saves a message to the process run record

=cut

    method update_message(Str $message) {
        my $file_process = $self->EtlpFileProcess()->find($self->id);
        $file_process->message($message);
        $self->update($file_process, $self->now);
    }
    
=head2 update_status

Sets the status of the process run records

=cut
    
    method update_status(Str $status_name) {
        my $file_process = $self->EtlpFileProcess()->find($self->id);
        $file_process->status_id($self->get_status_id($status_name));
        $self->update($file_process, $self->now);
    }
    
=head2 update

Saves the file_process record item to the database

=cut

    method update(ETLp::Schema::Result::EtlpFileProcess $file_process,
                  DateTime $date) {
        $file_process->date_updated($date);
        my $item  = $self->EtlpItem->find($self->item->id);
        try {
            $self->schema->txn_do(
                sub {
                    $file_process->update;
                    $self->item->update($item, $date);
                }
            )
        }
        catch {
            $self->logger->logdie("Cannot update job item record: $_");
        };
    }

=head2 record_count

set the number of records loaded

=cut

    method record_count (Int $record_count) {
        my $file_process = $self->EtlpFileProcess()->find($self->id);
        $file_process->record_count($record_count);
        $self->update($file_process, $self->now);
    }

    # Create a new processing record for the file
    method _create {
        my $file_id = $self->get_canonical_id;
        my $now     = $self->db_now;
        
        unless ($file_id) {
            $file_id = $self->_create_canonical_record;
        }
        
        my $file_process = $self->EtlpFileProcess->create(
            {
                item_id      => $self->item->id,
                status_id    => $self->get_status_id('running'),
                filename     => $self->filename,
                file_id      => $file_id,
                date_created => $now,
                date_updated => $now,
            }
        );
        
        $self->{id} = $file_process->file_proc_id;
    }
    
    method BUILD {
        my $driver = $self->get_driver;
        $self->{canonical_filename} =
            $self->_get_canonical_filename($self->filename);
        $self->_create;
    }
};

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut

1;

