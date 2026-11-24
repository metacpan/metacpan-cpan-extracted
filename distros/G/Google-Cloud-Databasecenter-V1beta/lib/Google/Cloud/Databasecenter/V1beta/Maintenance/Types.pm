package Google::Cloud::Databasecenter::V1beta::Maintenance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Phase',
    as (Int | Str);

declare 'MaintenanceState',
    as (Int | Str);

declare 'PossibleFailureReason',
    as (Int | Str);

declare 'ResourceMaintenanceSchedule',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule'];

coerce 'ResourceMaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule'->new($_) };

declare 'RepeatedResourceMaintenanceSchedule',
    as ArrayRef[ResourceMaintenanceSchedule()];

coerce 'RepeatedResourceMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringResourceMaintenanceSchedule',
    as HashRef[ResourceMaintenanceSchedule()];

declare 'ResourceMaintenanceDenySchedule',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceDenySchedule'];

coerce 'ResourceMaintenanceDenySchedule',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceDenySchedule'->new($_) };

declare 'RepeatedResourceMaintenanceDenySchedule',
    as ArrayRef[ResourceMaintenanceDenySchedule()];

coerce 'RepeatedResourceMaintenanceDenySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Maintenance::ResourceMaintenanceDenySchedule'->new($_) } @$_ ] };

declare 'MapStringResourceMaintenanceDenySchedule',
    as HashRef[ResourceMaintenanceDenySchedule()];

declare 'UpcomingMaintenance',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Maintenance::UpcomingMaintenance'];

coerce 'UpcomingMaintenance',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Maintenance::UpcomingMaintenance'->new($_) };

declare 'RepeatedUpcomingMaintenance',
    as ArrayRef[UpcomingMaintenance()];

coerce 'RepeatedUpcomingMaintenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Maintenance::UpcomingMaintenance'->new($_) } @$_ ] };

declare 'MapStringUpcomingMaintenance',
    as HashRef[UpcomingMaintenance()];

declare 'MaintenanceInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Maintenance::MaintenanceInfo'];

coerce 'MaintenanceInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Maintenance::MaintenanceInfo'->new($_) };

declare 'RepeatedMaintenanceInfo',
    as ArrayRef[MaintenanceInfo()];

coerce 'RepeatedMaintenanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Maintenance::MaintenanceInfo'->new($_) } @$_ ] };

declare 'MapStringMaintenanceInfo',
    as HashRef[MaintenanceInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Maintenance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
