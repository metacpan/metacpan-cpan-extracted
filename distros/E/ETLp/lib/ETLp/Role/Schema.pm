package ETLp::Role::Schema;

use MooseX::Declare;

=head1 NAME

ETLp::Role::Schema - Access to ETLp resultsets

=head1 DESCRIPTION

This role provides user-friendly methods for ETLp resultset objects

=head1 METHODS

=head2 schema

Returns the ETLp::Schema

=head1 RESULTSET METHODS

Returns a schema resultset for the supplied method name

    * EtlpConfiguration
    * EtlpFile
    * EtlpFileProcess
    * EtlpItem
    * EtlpJob
    * EtlpPhase
    * EtlpSection
    * EtlpStatus
    * EtlpUser

=cut

role ETLp::Role::Schema {
    
    use ETLp::Config;
    
    method schema {
        return ETLp::Config->schema;
    }
    
    method EtlpAppConfig {
        return $self->schema->resultset('EtlpAppConfig');
    }
    
    method EtlpConfiguration {
        return $self->schema->resultset('EtlpConfiguration');
    }    
    
    method EtlpDayOfWeek {
        return $self->schema->resultset('EtlpDayOfWeek');
    }
    
    method EtlpFile {
        return $self->schema->resultset('EtlpFile');
    }    
    
    method EtlpFileProcess {
        return $self->schema->resultset('EtlpFileProcess');
    }    
    
    method EtlpItem {
        return $self->schema->resultset('EtlpItem');
    }
    
    method EtlpJob {
        return $self->schema->resultset('EtlpJob');
    }
    
    method EtlpMonth {
        return $self->schema->resultset('EtlpMonth');
    }  
    
    method EtlpPhase {
        return $self->schema->resultset('EtlpPhase');
    }
    
    method EtlpSchedule {
        return $self->schema->resultset('EtlpSchedule');
    }
    
    method EtlpScheduleDayOfMonth{
        return $self->schema->resultset('EtlpScheduleDayOfMonth');
    }
    
    method EtlpScheduleDayOfWeek {
        return $self->schema->resultset('EtlpScheduleDayOfWeek');
    }
    
    method EtlpScheduleHour {
        return $self->schema->resultset('EtlpScheduleHour');
    }
    
    method EtlpScheduleMinute {
        return $self->schema->resultset('EtlpScheduleMinute');
    }
    
    method EtlpScheduleMonth {
        return $self->schema->resultset('EtlpScheduleMonth');
    }
    
    method EtlpSection {
        return $self->schema->resultset('EtlpSection');
    }
    
    method EtlpStatus {
        return $self->schema->resultset('EtlpStatus');
    }
    
    method EtlpUser {
        return $self->schema->resultset('EtlpUser');
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

