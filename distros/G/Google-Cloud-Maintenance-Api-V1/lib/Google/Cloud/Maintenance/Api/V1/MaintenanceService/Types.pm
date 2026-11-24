package Google::Cloud::Maintenance::Api::V1::MaintenanceService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MaintenanceCategory',
    as (Int | Str);

declare 'SummarizeMaintenancesRequest',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::SummarizeMaintenancesRequest'];

coerce 'SummarizeMaintenancesRequest',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::SummarizeMaintenancesRequest'->new($_) };

declare 'RepeatedSummarizeMaintenancesRequest',
    as ArrayRef[SummarizeMaintenancesRequest()];

coerce 'RepeatedSummarizeMaintenancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::SummarizeMaintenancesRequest'->new($_) } @$_ ] };

declare 'MapStringSummarizeMaintenancesRequest',
    as HashRef[SummarizeMaintenancesRequest()];

declare 'SummarizeMaintenancesResponse',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::SummarizeMaintenancesResponse'];

coerce 'SummarizeMaintenancesResponse',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::SummarizeMaintenancesResponse'->new($_) };

declare 'RepeatedSummarizeMaintenancesResponse',
    as ArrayRef[SummarizeMaintenancesResponse()];

coerce 'RepeatedSummarizeMaintenancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::SummarizeMaintenancesResponse'->new($_) } @$_ ] };

declare 'MapStringSummarizeMaintenancesResponse',
    as HashRef[SummarizeMaintenancesResponse()];

declare 'MaintenanceSummary',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary'];

coerce 'MaintenanceSummary',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary'->new($_) };

declare 'RepeatedMaintenanceSummary',
    as ArrayRef[MaintenanceSummary()];

coerce 'RepeatedMaintenanceSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSummary',
    as HashRef[MaintenanceSummary()];

declare 'Stats',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary::Stats'];

coerce 'Stats',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary::Stats'->new($_) };

declare 'RepeatedStats',
    as ArrayRef[Stats()];

coerce 'RepeatedStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary::Stats'->new($_) } @$_ ] };

declare 'MapStringStats',
    as HashRef[Stats()];

declare 'Aggregate',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary::Aggregate'];

coerce 'Aggregate',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary::Aggregate'->new($_) };

declare 'RepeatedAggregate',
    as ArrayRef[Aggregate()];

coerce 'RepeatedAggregate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceSummary::Aggregate'->new($_) } @$_ ] };

declare 'MapStringAggregate',
    as HashRef[Aggregate()];

declare 'ResourceMaintenance',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance'];

coerce 'ResourceMaintenance',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance'->new($_) };

declare 'RepeatedResourceMaintenance',
    as ArrayRef[ResourceMaintenance()];

coerce 'RepeatedResourceMaintenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance'->new($_) } @$_ ] };

declare 'MapStringResourceMaintenance',
    as HashRef[ResourceMaintenance()];

declare 'State',
    as (Int | Str);

declare 'Resource',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'Maintenance',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::Maintenance'];

coerce 'Maintenance',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::Maintenance'->new($_) };

declare 'RepeatedMaintenance',
    as ArrayRef[Maintenance()];

coerce 'RepeatedMaintenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::Maintenance'->new($_) } @$_ ] };

declare 'MapStringMaintenance',
    as HashRef[Maintenance()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ResourceMaintenance::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'MaintenanceControl',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceControl'];

coerce 'MaintenanceControl',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceControl'->new($_) };

declare 'RepeatedMaintenanceControl',
    as ArrayRef[MaintenanceControl()];

coerce 'RepeatedMaintenanceControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::MaintenanceControl'->new($_) } @$_ ] };

declare 'MapStringMaintenanceControl',
    as HashRef[MaintenanceControl()];

declare 'Control',
    as (Int | Str);

declare 'ListResourceMaintenancesRequest',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ListResourceMaintenancesRequest'];

coerce 'ListResourceMaintenancesRequest',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ListResourceMaintenancesRequest'->new($_) };

declare 'RepeatedListResourceMaintenancesRequest',
    as ArrayRef[ListResourceMaintenancesRequest()];

coerce 'RepeatedListResourceMaintenancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ListResourceMaintenancesRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceMaintenancesRequest',
    as HashRef[ListResourceMaintenancesRequest()];

declare 'ListResourceMaintenancesResponse',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::ListResourceMaintenancesResponse'];

coerce 'ListResourceMaintenancesResponse',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ListResourceMaintenancesResponse'->new($_) };

declare 'RepeatedListResourceMaintenancesResponse',
    as ArrayRef[ListResourceMaintenancesResponse()];

coerce 'RepeatedListResourceMaintenancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::ListResourceMaintenancesResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceMaintenancesResponse',
    as HashRef[ListResourceMaintenancesResponse()];

declare 'GetResourceMaintenanceRequest',
    as InstanceOf['Google::Cloud::Maintenance::Api::V1::MaintenanceService::GetResourceMaintenanceRequest'];

coerce 'GetResourceMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::GetResourceMaintenanceRequest'->new($_) };

declare 'RepeatedGetResourceMaintenanceRequest',
    as ArrayRef[GetResourceMaintenanceRequest()];

coerce 'RepeatedGetResourceMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Maintenance::Api::V1::MaintenanceService::GetResourceMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceMaintenanceRequest',
    as HashRef[GetResourceMaintenanceRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Maintenance::Api::V1::MaintenanceService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
