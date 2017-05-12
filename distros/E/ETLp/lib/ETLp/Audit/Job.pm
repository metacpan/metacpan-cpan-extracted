package ETLp::Audit::Job;

use MooseX::Declare;

=head1 NAME

ETLp::Audit::Job - audit the execution of an ETLp job

=head1 DESCRIPTION

This class is used to manage the job's audit record

=cut

use DateTime;

class ETLp::Audit::Job with (ETLp::Role::Config, ETLp::Role::Schema,
                             ETLp::Role::Audit) {
    use Try::Tiny;
    use DateTime;
    use ETLp::Types;
    use ETLp::Audit::Item;
    
=head1 ATTRIBUTES

The attributes are populated during instantiation, and should not be provided
at object creation time

=head2 id

The Job identifier

=head2 session_id

The database session associated with the job

=head2 item

The currently executing item

=cut
    
    has 'session_id' => (is => 'rw', isa => 'Int', required => 0);   
    has 'id' => (is => 'rw', isa => 'Int', required => 0);
    has 'name' => (is => 'ro', isa => 'Str', required => 1);
    has 'section' => (is => 'ro', isa => 'Str', required => 1);
    has 'config'  => (is => 'ro', isa => 'HashRef', required => 1);
    
=head1 METHODS

=head2 create_item

Create an audit item

=head3 parameters (Hash)

    * Str name: Name of the item
    * Str type: The item type
    * Str phase: The item phase
    
=head3 returns

    * An ETLp::Audit::Item
    
=cut
    
    method create_item(Str :$name, Str :$type, Str :$phase) {    
        my $item = ETLp::Audit::Item->new(
            name       => $name,
            type       => $type,
            phase      => $phase,
            job        => $self,
            config     => $self->config
        );
        $self->{item} = $item;
        return $item;
    }
    
    method item {
        return $self->{item};
    }
    
    method _start_audit {
        my $now = $self->now;
        try {
            $self->schema->txn_do(
                sub {
                    my $config = $self->EtlpConfiguration->find_or_create(
                        {
                            config_name => $self->name,
                            date_created => $now,
                            date_updated => $now
                        },                                                                                               
                        {key => 'etlp_configuration_u1'}
                    );
                    
                    my $section = $self->EtlpSection->find_or_create(
                        {
                            config_id    => $config->config_id,
                            section_name => $self->section,
                            date_created => $now,
                            date_updated => $now
                        },
                        {key => 'etlp_section_u1'}
                    );
                    
                    my $job = $self->EtlpJob->create(
                        {
                            section_id    => $section->section_id,
                            status_id     => $self->get_status_id('running'),
                            session_id    => $self->session_id,
                            process_id    => $$,
                            date_created  => $now,
                            date_updated  => $now
                        }
                    );
                    
                    $self->id($job->job_id);
                }
            )
            
        } catch {
            $self->logger->logdie("Cannot create job audit record: $_");
        };
    }    
    
=head2 update_status

Update the job's status

=head3 parameters

    * status_name: The name of the status
    
=head3 returns

    * void

=cut

    method update_status(Str $status_name) {
        my $job  = $self->EtlpJob->find($self->id);
        $job->status_id($self->get_status_id($status_name));
        $self->update($job, $self->now);
    }
    
=head2 update_message

Update the audit message

=head3 parameters

    * message: The message associated with the Job
    
=head3 returns

    * void
    
=cut
    
    method update_message(Str $message)  {
        my $job = $self->EtlpJob->find($self->id);
        $job->message($message);
        $self->update($job, $self->now);
    }
    
=head2 update

Update the audit record date

=head3 parameters

    * message: The message associated with the Job
    
=head3 returns

    * void
    
=cut
    
    method update(ETLp::Schema::Result::EtlpJob $job,
                       Maybe[DateTime] $date) {
        $date = $self->now unless $date;
        try {
            $self->schema->txn_do(
                sub {
                    $job->date_updated($date);
                    $job->update;
                }
            )
        }
        catch {
            $self->logger->logdie("Cannot update job record: $_");
        };
    }
    
    method _get_session_id {
        my $driver = $self->get_driver;
        my $session_id;

        # The session should be that of the main database connection not
        # that of the audit session
        if ($driver eq 'Oracle') {
            my $sql = q{
                select sid from v$mystat where rownum = 1
            };

            ($session_id) =
              $self->dbh->selectrow_array($sql);
        } else {
            $session_id = 1;
        }
        
        return $session_id;
    }
    
    method BUILD {
        $self->session_id($self->_get_session_id);
        $self->_start_audit;
    }
    
}

=head1 ROLES CONSUMED

 * ETLp::Role::Config
 * ETLp::Role::Schema
 
=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
    
=cut