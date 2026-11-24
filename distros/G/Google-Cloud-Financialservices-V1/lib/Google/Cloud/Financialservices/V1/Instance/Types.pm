package Google::Cloud::Financialservices::V1::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instance',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'ImportRegisteredPartiesRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesRequest'];

coerce 'ImportRegisteredPartiesRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesRequest'->new($_) };

declare 'RepeatedImportRegisteredPartiesRequest',
    as ArrayRef[ImportRegisteredPartiesRequest()];

coerce 'RepeatedImportRegisteredPartiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesRequest'->new($_) } @$_ ] };

declare 'MapStringImportRegisteredPartiesRequest',
    as HashRef[ImportRegisteredPartiesRequest()];

declare 'UpdateMode',
    as (Int | Str);

declare 'ImportRegisteredPartiesResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesResponse'];

coerce 'ImportRegisteredPartiesResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesResponse'->new($_) };

declare 'RepeatedImportRegisteredPartiesResponse',
    as ArrayRef[ImportRegisteredPartiesResponse()];

coerce 'RepeatedImportRegisteredPartiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::ImportRegisteredPartiesResponse'->new($_) } @$_ ] };

declare 'MapStringImportRegisteredPartiesResponse',
    as HashRef[ImportRegisteredPartiesResponse()];

declare 'ExportRegisteredPartiesRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesRequest'];

coerce 'ExportRegisteredPartiesRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesRequest'->new($_) };

declare 'RepeatedExportRegisteredPartiesRequest',
    as ArrayRef[ExportRegisteredPartiesRequest()];

coerce 'RepeatedExportRegisteredPartiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesRequest'->new($_) } @$_ ] };

declare 'MapStringExportRegisteredPartiesRequest',
    as HashRef[ExportRegisteredPartiesRequest()];

declare 'ExportRegisteredPartiesResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesResponse'];

coerce 'ExportRegisteredPartiesResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesResponse'->new($_) };

declare 'RepeatedExportRegisteredPartiesResponse',
    as ArrayRef[ExportRegisteredPartiesResponse()];

coerce 'RepeatedExportRegisteredPartiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Instance::ExportRegisteredPartiesResponse'->new($_) } @$_ ] };

declare 'MapStringExportRegisteredPartiesResponse',
    as HashRef[ExportRegisteredPartiesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
