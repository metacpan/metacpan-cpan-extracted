package ETLp::Audit::Item;

use MooseX::Declare;

=head1 NAME

ETLp::Audit::Item - audit the execution of an ETLp job

=head1 DESCRIPTION

This class is used to manage an individual audit item

=cut

class ETLp::Audit::Item with (ETLp::Role::Config, ETLp::Role::Schema,
                              ETLp::Role::Audit)  {

    use DateTime;
    use Try::Tiny;
    use ETLp::Types;
    use ETLp::Audit::FileProcess;
    use DateTime;
    
    has 'job' =>
      (is => 'ro', isa => 'ETLp::Audit::Job', required => 1, weak_ref => 1);
    has 'name'   => (is => 'ro', isa => 'Str',     required => 1);
    has 'phase'  => (is => 'ro', isa => 'Str',     required => 1);
    has 'type'   => (is => 'ro', isa => 'Str',     required => 1);
    has 'config' => (is => 'ro', isa => 'HashRef', required => 1);
    
    method id {
        return $self->{id};
    }
    
=head2 update_message

Sets the item message

=cut

    method update_message(Str $message) {
        my $item = $self->EtlpItem()->find($self->id);
        $item->message($message);
        $self->update($item, $self->now);
    }
    
=head2 update_status

Sets the status of the item

=cut
    
    method update_status(Str $status_name) {
        my $item = $self->EtlpItem()->find($self->id);
        $item->status_id($self->get_status_id($status_name));
        $self->update($item, $self->now);
    }
    
=head2 update

Saves the supplied item to the database

=cut

    method update(ETLp::Schema::Result::EtlpItem $item,
                  DateTime $date) {
        $item->date_updated($date);
        my $job  = $self->EtlpJob->find($self->job->id);
        try {
            $self->schema->txn_do(
                sub {
                    $item->update;
                    $self->job->update($job, $date);
                }
            )
        }
        catch {
            $self->logger->logdie("Cannot update job item record: $_");
        };
    }
    
=head2 create_file_process

Create a file process audit object

=cut

    method create_file_process(Str $filename) {
        my $file_process = ETLp::Audit::FileProcess->new(
            filename => $filename,
            item     => $self,
            config   => $self->config,
        );
        $self->{file_process} = $file_process;
        return $file_process;
    }

=head2 file_process

Returns the file_process audit object

=cut

    method file_process {
        return $self->{file_process};
    }
    
    # Create a new item record
    method _create {
        my $now  = $self->now;
    
        try {
            $self->schema->txn_do(
                sub {
                    my $process_item = $self->EtlpItem()->create(
                        {
                            item_type    => $self->type,
                            phase_id     => $self->get_phase_id($self->phase),
                            status_id    => $self->get_status_id('running'),
                            job_id       => $self->job->id,
                            item_name    => $self->name,
                            date_created => $now,
                            date_updated => $now,
                        }
                    );
    
                    $self->{id} = $process_item->item_id;
                }
            );
        }
        catch {
            $self->logger->logdie("Cannot create job item record: $_");
        };
    }
    
    # These attributes cannot be updated
    method _protected_attributes {
        return [qw/item_id job_id phase_id type_id date_created date_updated/];
    }
    
    method BUILD {
        $self->_create;
    }
    
}
                              
=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut

1;