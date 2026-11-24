package Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateFindingRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateFindingRequest'];

coerce 'CreateFindingRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateFindingRequest'->new($_) };

declare 'RepeatedCreateFindingRequest',
    as ArrayRef[CreateFindingRequest()];

coerce 'RepeatedCreateFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateFindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFindingRequest',
    as HashRef[CreateFindingRequest()];

declare 'CreateSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateSourceRequest'];

coerce 'CreateSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateSourceRequest'->new($_) };

declare 'RepeatedCreateSourceRequest',
    as ArrayRef[CreateSourceRequest()];

coerce 'RepeatedCreateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSourceRequest',
    as HashRef[CreateSourceRequest()];

declare 'GetOrganizationSettingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetOrganizationSettingsRequest'];

coerce 'GetOrganizationSettingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetOrganizationSettingsRequest'->new($_) };

declare 'RepeatedGetOrganizationSettingsRequest',
    as ArrayRef[GetOrganizationSettingsRequest()];

coerce 'RepeatedGetOrganizationSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetOrganizationSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrganizationSettingsRequest',
    as HashRef[GetOrganizationSettingsRequest()];

declare 'GetSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetSourceRequest'];

coerce 'GetSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetSourceRequest'->new($_) };

declare 'RepeatedGetSourceRequest',
    as ArrayRef[GetSourceRequest()];

coerce 'RepeatedGetSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSourceRequest',
    as HashRef[GetSourceRequest()];

declare 'GroupAssetsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupAssetsRequest'];

coerce 'GroupAssetsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupAssetsRequest'->new($_) };

declare 'RepeatedGroupAssetsRequest',
    as ArrayRef[GroupAssetsRequest()];

coerce 'RepeatedGroupAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringGroupAssetsRequest',
    as HashRef[GroupAssetsRequest()];

declare 'GroupAssetsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupAssetsResponse'];

coerce 'GroupAssetsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupAssetsResponse'->new($_) };

declare 'RepeatedGroupAssetsResponse',
    as ArrayRef[GroupAssetsResponse()];

coerce 'RepeatedGroupAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringGroupAssetsResponse',
    as HashRef[GroupAssetsResponse()];

declare 'GroupFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupFindingsRequest'];

coerce 'GroupFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupFindingsRequest'->new($_) };

declare 'RepeatedGroupFindingsRequest',
    as ArrayRef[GroupFindingsRequest()];

coerce 'RepeatedGroupFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringGroupFindingsRequest',
    as HashRef[GroupFindingsRequest()];

declare 'GroupFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupFindingsResponse'];

coerce 'GroupFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupFindingsResponse'->new($_) };

declare 'RepeatedGroupFindingsResponse',
    as ArrayRef[GroupFindingsResponse()];

coerce 'RepeatedGroupFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringGroupFindingsResponse',
    as HashRef[GroupFindingsResponse()];

declare 'GroupResult',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupResult'];

coerce 'GroupResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupResult'->new($_) };

declare 'RepeatedGroupResult',
    as ArrayRef[GroupResult()];

coerce 'RepeatedGroupResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupResult'->new($_) } @$_ ] };

declare 'MapStringGroupResult',
    as HashRef[GroupResult()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupResult::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupResult::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GroupResult::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'ListSourcesRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListSourcesRequest'];

coerce 'ListSourcesRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListSourcesRequest'->new($_) };

declare 'RepeatedListSourcesRequest',
    as ArrayRef[ListSourcesRequest()];

coerce 'RepeatedListSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListSourcesRequest',
    as HashRef[ListSourcesRequest()];

declare 'ListSourcesResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListSourcesResponse'];

coerce 'ListSourcesResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListSourcesResponse'->new($_) };

declare 'RepeatedListSourcesResponse',
    as ArrayRef[ListSourcesResponse()];

coerce 'RepeatedListSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListSourcesResponse',
    as HashRef[ListSourcesResponse()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'ListAssetsResult',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsResponse::ListAssetsResult'];

coerce 'ListAssetsResult',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsResponse::ListAssetsResult'->new($_) };

declare 'RepeatedListAssetsResult',
    as ArrayRef[ListAssetsResult()];

coerce 'RepeatedListAssetsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListAssetsResponse::ListAssetsResult'->new($_) } @$_ ] };

declare 'MapStringListAssetsResult',
    as HashRef[ListAssetsResult()];

declare 'State',
    as (Int | Str);

declare 'ListFindingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListFindingsRequest'];

coerce 'ListFindingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListFindingsRequest'->new($_) };

declare 'RepeatedListFindingsRequest',
    as ArrayRef[ListFindingsRequest()];

coerce 'RepeatedListFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingsRequest',
    as HashRef[ListFindingsRequest()];

declare 'ListFindingsResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListFindingsResponse'];

coerce 'ListFindingsResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListFindingsResponse'->new($_) };

declare 'RepeatedListFindingsResponse',
    as ArrayRef[ListFindingsResponse()];

coerce 'RepeatedListFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::ListFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingsResponse',
    as HashRef[ListFindingsResponse()];

declare 'SetFindingStateRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::SetFindingStateRequest'];

coerce 'SetFindingStateRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::SetFindingStateRequest'->new($_) };

declare 'RepeatedSetFindingStateRequest',
    as ArrayRef[SetFindingStateRequest()];

coerce 'RepeatedSetFindingStateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::SetFindingStateRequest'->new($_) } @$_ ] };

declare 'MapStringSetFindingStateRequest',
    as HashRef[SetFindingStateRequest()];

declare 'RunAssetDiscoveryRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::RunAssetDiscoveryRequest'];

coerce 'RunAssetDiscoveryRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::RunAssetDiscoveryRequest'->new($_) };

declare 'RepeatedRunAssetDiscoveryRequest',
    as ArrayRef[RunAssetDiscoveryRequest()];

coerce 'RepeatedRunAssetDiscoveryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::RunAssetDiscoveryRequest'->new($_) } @$_ ] };

declare 'MapStringRunAssetDiscoveryRequest',
    as HashRef[RunAssetDiscoveryRequest()];

declare 'UpdateFindingRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateFindingRequest'];

coerce 'UpdateFindingRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateFindingRequest'->new($_) };

declare 'RepeatedUpdateFindingRequest',
    as ArrayRef[UpdateFindingRequest()];

coerce 'RepeatedUpdateFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateFindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFindingRequest',
    as HashRef[UpdateFindingRequest()];

declare 'UpdateOrganizationSettingsRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateOrganizationSettingsRequest'];

coerce 'UpdateOrganizationSettingsRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateOrganizationSettingsRequest'->new($_) };

declare 'RepeatedUpdateOrganizationSettingsRequest',
    as ArrayRef[UpdateOrganizationSettingsRequest()];

coerce 'RepeatedUpdateOrganizationSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateOrganizationSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOrganizationSettingsRequest',
    as HashRef[UpdateOrganizationSettingsRequest()];

declare 'UpdateSourceRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSourceRequest'];

coerce 'UpdateSourceRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSourceRequest'->new($_) };

declare 'RepeatedUpdateSourceRequest',
    as ArrayRef[UpdateSourceRequest()];

coerce 'RepeatedUpdateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSourceRequest',
    as HashRef[UpdateSourceRequest()];

declare 'UpdateSecurityMarksRequest',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSecurityMarksRequest'];

coerce 'UpdateSecurityMarksRequest',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSecurityMarksRequest'->new($_) };

declare 'RepeatedUpdateSecurityMarksRequest',
    as ArrayRef[UpdateSecurityMarksRequest()];

coerce 'RepeatedUpdateSecurityMarksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSecurityMarksRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecurityMarksRequest',
    as HashRef[UpdateSecurityMarksRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
