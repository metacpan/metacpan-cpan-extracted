package Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListAppConnectorsRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ListAppConnectorsRequest'];

coerce 'ListAppConnectorsRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ListAppConnectorsRequest'->new($_) };

declare 'RepeatedListAppConnectorsRequest',
    as ArrayRef[ListAppConnectorsRequest()];

coerce 'RepeatedListAppConnectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ListAppConnectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListAppConnectorsRequest',
    as HashRef[ListAppConnectorsRequest()];

declare 'ListAppConnectorsResponse',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ListAppConnectorsResponse'];

coerce 'ListAppConnectorsResponse',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ListAppConnectorsResponse'->new($_) };

declare 'RepeatedListAppConnectorsResponse',
    as ArrayRef[ListAppConnectorsResponse()];

coerce 'RepeatedListAppConnectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ListAppConnectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListAppConnectorsResponse',
    as HashRef[ListAppConnectorsResponse()];

declare 'GetAppConnectorRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::GetAppConnectorRequest'];

coerce 'GetAppConnectorRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::GetAppConnectorRequest'->new($_) };

declare 'RepeatedGetAppConnectorRequest',
    as ArrayRef[GetAppConnectorRequest()];

coerce 'RepeatedGetAppConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::GetAppConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetAppConnectorRequest',
    as HashRef[GetAppConnectorRequest()];

declare 'CreateAppConnectorRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::CreateAppConnectorRequest'];

coerce 'CreateAppConnectorRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::CreateAppConnectorRequest'->new($_) };

declare 'RepeatedCreateAppConnectorRequest',
    as ArrayRef[CreateAppConnectorRequest()];

coerce 'RepeatedCreateAppConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::CreateAppConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAppConnectorRequest',
    as HashRef[CreateAppConnectorRequest()];

declare 'UpdateAppConnectorRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::UpdateAppConnectorRequest'];

coerce 'UpdateAppConnectorRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::UpdateAppConnectorRequest'->new($_) };

declare 'RepeatedUpdateAppConnectorRequest',
    as ArrayRef[UpdateAppConnectorRequest()];

coerce 'RepeatedUpdateAppConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::UpdateAppConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAppConnectorRequest',
    as HashRef[UpdateAppConnectorRequest()];

declare 'DeleteAppConnectorRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::DeleteAppConnectorRequest'];

coerce 'DeleteAppConnectorRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::DeleteAppConnectorRequest'->new($_) };

declare 'RepeatedDeleteAppConnectorRequest',
    as ArrayRef[DeleteAppConnectorRequest()];

coerce 'RepeatedDeleteAppConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::DeleteAppConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAppConnectorRequest',
    as HashRef[DeleteAppConnectorRequest()];

declare 'ResolveInstanceConfigRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ResolveInstanceConfigRequest'];

coerce 'ResolveInstanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ResolveInstanceConfigRequest'->new($_) };

declare 'RepeatedResolveInstanceConfigRequest',
    as ArrayRef[ResolveInstanceConfigRequest()];

coerce 'RepeatedResolveInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ResolveInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringResolveInstanceConfigRequest',
    as HashRef[ResolveInstanceConfigRequest()];

declare 'ResolveInstanceConfigResponse',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ResolveInstanceConfigResponse'];

coerce 'ResolveInstanceConfigResponse',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ResolveInstanceConfigResponse'->new($_) };

declare 'RepeatedResolveInstanceConfigResponse',
    as ArrayRef[ResolveInstanceConfigResponse()];

coerce 'RepeatedResolveInstanceConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ResolveInstanceConfigResponse'->new($_) } @$_ ] };

declare 'MapStringResolveInstanceConfigResponse',
    as HashRef[ResolveInstanceConfigResponse()];

declare 'ReportStatusRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ReportStatusRequest'];

coerce 'ReportStatusRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ReportStatusRequest'->new($_) };

declare 'RepeatedReportStatusRequest',
    as ArrayRef[ReportStatusRequest()];

coerce 'RepeatedReportStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::ReportStatusRequest'->new($_) } @$_ ] };

declare 'MapStringReportStatusRequest',
    as HashRef[ReportStatusRequest()];

declare 'AppConnector',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector'];

coerce 'AppConnector',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector'->new($_) };

declare 'RepeatedAppConnector',
    as ArrayRef[AppConnector()];

coerce 'RepeatedAppConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector'->new($_) } @$_ ] };

declare 'MapStringAppConnector',
    as HashRef[AppConnector()];

declare 'State',
    as (Int | Str);

declare 'PrincipalInfo',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::PrincipalInfo'];

coerce 'PrincipalInfo',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::PrincipalInfo'->new($_) };

declare 'RepeatedPrincipalInfo',
    as ArrayRef[PrincipalInfo()];

coerce 'RepeatedPrincipalInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::PrincipalInfo'->new($_) } @$_ ] };

declare 'MapStringPrincipalInfo',
    as HashRef[PrincipalInfo()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::PrincipalInfo::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::PrincipalInfo::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::PrincipalInfo::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnector::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AppConnectorOperationMetadata',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnectorOperationMetadata'];

coerce 'AppConnectorOperationMetadata',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnectorOperationMetadata'->new($_) };

declare 'RepeatedAppConnectorOperationMetadata',
    as ArrayRef[AppConnectorOperationMetadata()];

coerce 'RepeatedAppConnectorOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::AppConnectorOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringAppConnectorOperationMetadata',
    as HashRef[AppConnectorOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
