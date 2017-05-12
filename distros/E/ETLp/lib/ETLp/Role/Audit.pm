use MooseX::Declare;
use DateTime;
use MooseX::Types::DateTime qw(DateTime);

=head1 NAME

ETLp::Role::Audit - utility methods for ETLp auiditing

=head1 DESCRIPTION

This role provides a wrapper around ETLp::Config. It's purpose
is top provide simple access to the configuration setting

=head1 METHODS

=head2 get_driver

Return the  name of the DBD driver for the audit connection

=head2 now

Return the current date and time as a DateTime object for the local time_zone'

=head2 db_time
    
Return the supplied DateTime object as a DB-specific date and time string

=head2 db_now

Return the current date and time as a DB-specific string

=head2 get_status_id

Given a status name, return the primary key

=head2 get_phase_id

Given a phase name, return the primay key

=cut


role ETLp::Role::Audit {
    use DBI::Const::GetInfoType;
    use ETLp::Types;
    
    method get_driver {
        return $self->schema->storage->dbh->get_info($GetInfoType{SQL_DBMS_NAME})
    }
    
    method now {
        my $dt = DateTime->now(time_zone => 'local');
        return $dt;
    }
    
    method db_time(DateTime $date) {
        return $self->schema->storage->datetime_parser->format_datetime($date);
    }
    
    method db_now {
        return $self->db_time($self->now);
    }
    
    method get_status_id (Str $status_name) {
        my $status  = $self->EtlpStatus->search({status_name => $status_name});
        return $status->first->status_id;
    }
    
    method get_phase_id (Str $phase_name) {
        my $phase  = $self->EtlpPhase->search({phase_name => $phase_name});
        return $phase->first->phase_id;
    }
    
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut
