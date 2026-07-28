package Google::Cloud::Networkservices::V1::Dep::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventType',
    as (Int | Str);

declare 'LoadBalancingScheme',
    as (Int | Str);

declare 'WireFormat',
    as (Int | Str);

declare 'BodySendMode',
    as (Int | Str);

declare 'ExtensionChain',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ExtensionChain'];

coerce 'ExtensionChain',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ExtensionChain'->new($_) };

declare 'RepeatedExtensionChain',
    as ArrayRef[ExtensionChain()];

coerce 'RepeatedExtensionChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ExtensionChain'->new($_) } @$_ ] };

declare 'MapStringExtensionChain',
    as HashRef[ExtensionChain()];

declare 'MatchCondition',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ExtensionChain::MatchCondition'];

coerce 'MatchCondition',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ExtensionChain::MatchCondition'->new($_) };

declare 'RepeatedMatchCondition',
    as ArrayRef[MatchCondition()];

coerce 'RepeatedMatchCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ExtensionChain::MatchCondition'->new($_) } @$_ ] };

declare 'MapStringMatchCondition',
    as HashRef[MatchCondition()];

declare 'Extension',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ExtensionChain::Extension'];

coerce 'Extension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ExtensionChain::Extension'->new($_) };

declare 'RepeatedExtension',
    as ArrayRef[Extension()];

coerce 'RepeatedExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ExtensionChain::Extension'->new($_) } @$_ ] };

declare 'MapStringExtension',
    as HashRef[Extension()];

declare 'LbTrafficExtension',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::LbTrafficExtension'];

coerce 'LbTrafficExtension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::LbTrafficExtension'->new($_) };

declare 'RepeatedLbTrafficExtension',
    as ArrayRef[LbTrafficExtension()];

coerce 'RepeatedLbTrafficExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::LbTrafficExtension'->new($_) } @$_ ] };

declare 'MapStringLbTrafficExtension',
    as HashRef[LbTrafficExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::LbTrafficExtension::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::LbTrafficExtension::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::LbTrafficExtension::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListLbTrafficExtensionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListLbTrafficExtensionsRequest'];

coerce 'ListLbTrafficExtensionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListLbTrafficExtensionsRequest'->new($_) };

declare 'RepeatedListLbTrafficExtensionsRequest',
    as ArrayRef[ListLbTrafficExtensionsRequest()];

coerce 'RepeatedListLbTrafficExtensionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListLbTrafficExtensionsRequest'->new($_) } @$_ ] };

declare 'MapStringListLbTrafficExtensionsRequest',
    as HashRef[ListLbTrafficExtensionsRequest()];

declare 'ListLbTrafficExtensionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListLbTrafficExtensionsResponse'];

coerce 'ListLbTrafficExtensionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListLbTrafficExtensionsResponse'->new($_) };

declare 'RepeatedListLbTrafficExtensionsResponse',
    as ArrayRef[ListLbTrafficExtensionsResponse()];

coerce 'RepeatedListLbTrafficExtensionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListLbTrafficExtensionsResponse'->new($_) } @$_ ] };

declare 'MapStringListLbTrafficExtensionsResponse',
    as HashRef[ListLbTrafficExtensionsResponse()];

declare 'GetLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::GetLbTrafficExtensionRequest'];

coerce 'GetLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::GetLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedGetLbTrafficExtensionRequest',
    as ArrayRef[GetLbTrafficExtensionRequest()];

coerce 'RepeatedGetLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::GetLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringGetLbTrafficExtensionRequest',
    as HashRef[GetLbTrafficExtensionRequest()];

declare 'CreateLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::CreateLbTrafficExtensionRequest'];

coerce 'CreateLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::CreateLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedCreateLbTrafficExtensionRequest',
    as ArrayRef[CreateLbTrafficExtensionRequest()];

coerce 'RepeatedCreateLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::CreateLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLbTrafficExtensionRequest',
    as HashRef[CreateLbTrafficExtensionRequest()];

declare 'UpdateLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::UpdateLbTrafficExtensionRequest'];

coerce 'UpdateLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::UpdateLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedUpdateLbTrafficExtensionRequest',
    as ArrayRef[UpdateLbTrafficExtensionRequest()];

coerce 'RepeatedUpdateLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::UpdateLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLbTrafficExtensionRequest',
    as HashRef[UpdateLbTrafficExtensionRequest()];

declare 'DeleteLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::DeleteLbTrafficExtensionRequest'];

coerce 'DeleteLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::DeleteLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedDeleteLbTrafficExtensionRequest',
    as ArrayRef[DeleteLbTrafficExtensionRequest()];

coerce 'RepeatedDeleteLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::DeleteLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLbTrafficExtensionRequest',
    as HashRef[DeleteLbTrafficExtensionRequest()];

declare 'LbRouteExtension',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::LbRouteExtension'];

coerce 'LbRouteExtension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::LbRouteExtension'->new($_) };

declare 'RepeatedLbRouteExtension',
    as ArrayRef[LbRouteExtension()];

coerce 'RepeatedLbRouteExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::LbRouteExtension'->new($_) } @$_ ] };

declare 'MapStringLbRouteExtension',
    as HashRef[LbRouteExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::LbRouteExtension::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::LbRouteExtension::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::LbRouteExtension::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListLbRouteExtensionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListLbRouteExtensionsRequest'];

coerce 'ListLbRouteExtensionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListLbRouteExtensionsRequest'->new($_) };

declare 'RepeatedListLbRouteExtensionsRequest',
    as ArrayRef[ListLbRouteExtensionsRequest()];

coerce 'RepeatedListLbRouteExtensionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListLbRouteExtensionsRequest'->new($_) } @$_ ] };

declare 'MapStringListLbRouteExtensionsRequest',
    as HashRef[ListLbRouteExtensionsRequest()];

declare 'ListLbRouteExtensionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListLbRouteExtensionsResponse'];

coerce 'ListLbRouteExtensionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListLbRouteExtensionsResponse'->new($_) };

declare 'RepeatedListLbRouteExtensionsResponse',
    as ArrayRef[ListLbRouteExtensionsResponse()];

coerce 'RepeatedListLbRouteExtensionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListLbRouteExtensionsResponse'->new($_) } @$_ ] };

declare 'MapStringListLbRouteExtensionsResponse',
    as HashRef[ListLbRouteExtensionsResponse()];

declare 'GetLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::GetLbRouteExtensionRequest'];

coerce 'GetLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::GetLbRouteExtensionRequest'->new($_) };

declare 'RepeatedGetLbRouteExtensionRequest',
    as ArrayRef[GetLbRouteExtensionRequest()];

coerce 'RepeatedGetLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::GetLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringGetLbRouteExtensionRequest',
    as HashRef[GetLbRouteExtensionRequest()];

declare 'CreateLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::CreateLbRouteExtensionRequest'];

coerce 'CreateLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::CreateLbRouteExtensionRequest'->new($_) };

declare 'RepeatedCreateLbRouteExtensionRequest',
    as ArrayRef[CreateLbRouteExtensionRequest()];

coerce 'RepeatedCreateLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::CreateLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLbRouteExtensionRequest',
    as HashRef[CreateLbRouteExtensionRequest()];

declare 'UpdateLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::UpdateLbRouteExtensionRequest'];

coerce 'UpdateLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::UpdateLbRouteExtensionRequest'->new($_) };

declare 'RepeatedUpdateLbRouteExtensionRequest',
    as ArrayRef[UpdateLbRouteExtensionRequest()];

coerce 'RepeatedUpdateLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::UpdateLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLbRouteExtensionRequest',
    as HashRef[UpdateLbRouteExtensionRequest()];

declare 'DeleteLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::DeleteLbRouteExtensionRequest'];

coerce 'DeleteLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::DeleteLbRouteExtensionRequest'->new($_) };

declare 'RepeatedDeleteLbRouteExtensionRequest',
    as ArrayRef[DeleteLbRouteExtensionRequest()];

coerce 'RepeatedDeleteLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::DeleteLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLbRouteExtensionRequest',
    as HashRef[DeleteLbRouteExtensionRequest()];

declare 'LbEdgeExtension',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::LbEdgeExtension'];

coerce 'LbEdgeExtension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::LbEdgeExtension'->new($_) };

declare 'RepeatedLbEdgeExtension',
    as ArrayRef[LbEdgeExtension()];

coerce 'RepeatedLbEdgeExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::LbEdgeExtension'->new($_) } @$_ ] };

declare 'MapStringLbEdgeExtension',
    as HashRef[LbEdgeExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::LbEdgeExtension::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::LbEdgeExtension::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::LbEdgeExtension::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListLbEdgeExtensionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListLbEdgeExtensionsRequest'];

coerce 'ListLbEdgeExtensionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListLbEdgeExtensionsRequest'->new($_) };

declare 'RepeatedListLbEdgeExtensionsRequest',
    as ArrayRef[ListLbEdgeExtensionsRequest()];

coerce 'RepeatedListLbEdgeExtensionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListLbEdgeExtensionsRequest'->new($_) } @$_ ] };

declare 'MapStringListLbEdgeExtensionsRequest',
    as HashRef[ListLbEdgeExtensionsRequest()];

declare 'ListLbEdgeExtensionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListLbEdgeExtensionsResponse'];

coerce 'ListLbEdgeExtensionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListLbEdgeExtensionsResponse'->new($_) };

declare 'RepeatedListLbEdgeExtensionsResponse',
    as ArrayRef[ListLbEdgeExtensionsResponse()];

coerce 'RepeatedListLbEdgeExtensionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListLbEdgeExtensionsResponse'->new($_) } @$_ ] };

declare 'MapStringListLbEdgeExtensionsResponse',
    as HashRef[ListLbEdgeExtensionsResponse()];

declare 'GetLbEdgeExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::GetLbEdgeExtensionRequest'];

coerce 'GetLbEdgeExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::GetLbEdgeExtensionRequest'->new($_) };

declare 'RepeatedGetLbEdgeExtensionRequest',
    as ArrayRef[GetLbEdgeExtensionRequest()];

coerce 'RepeatedGetLbEdgeExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::GetLbEdgeExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringGetLbEdgeExtensionRequest',
    as HashRef[GetLbEdgeExtensionRequest()];

declare 'CreateLbEdgeExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::CreateLbEdgeExtensionRequest'];

coerce 'CreateLbEdgeExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::CreateLbEdgeExtensionRequest'->new($_) };

declare 'RepeatedCreateLbEdgeExtensionRequest',
    as ArrayRef[CreateLbEdgeExtensionRequest()];

coerce 'RepeatedCreateLbEdgeExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::CreateLbEdgeExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLbEdgeExtensionRequest',
    as HashRef[CreateLbEdgeExtensionRequest()];

declare 'UpdateLbEdgeExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::UpdateLbEdgeExtensionRequest'];

coerce 'UpdateLbEdgeExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::UpdateLbEdgeExtensionRequest'->new($_) };

declare 'RepeatedUpdateLbEdgeExtensionRequest',
    as ArrayRef[UpdateLbEdgeExtensionRequest()];

coerce 'RepeatedUpdateLbEdgeExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::UpdateLbEdgeExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLbEdgeExtensionRequest',
    as HashRef[UpdateLbEdgeExtensionRequest()];

declare 'DeleteLbEdgeExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::DeleteLbEdgeExtensionRequest'];

coerce 'DeleteLbEdgeExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::DeleteLbEdgeExtensionRequest'->new($_) };

declare 'RepeatedDeleteLbEdgeExtensionRequest',
    as ArrayRef[DeleteLbEdgeExtensionRequest()];

coerce 'RepeatedDeleteLbEdgeExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::DeleteLbEdgeExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLbEdgeExtensionRequest',
    as HashRef[DeleteLbEdgeExtensionRequest()];

declare 'AuthzExtension',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::AuthzExtension'];

coerce 'AuthzExtension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::AuthzExtension'->new($_) };

declare 'RepeatedAuthzExtension',
    as ArrayRef[AuthzExtension()];

coerce 'RepeatedAuthzExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::AuthzExtension'->new($_) } @$_ ] };

declare 'MapStringAuthzExtension',
    as HashRef[AuthzExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::AuthzExtension::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::AuthzExtension::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::AuthzExtension::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListAuthzExtensionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListAuthzExtensionsRequest'];

coerce 'ListAuthzExtensionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListAuthzExtensionsRequest'->new($_) };

declare 'RepeatedListAuthzExtensionsRequest',
    as ArrayRef[ListAuthzExtensionsRequest()];

coerce 'RepeatedListAuthzExtensionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListAuthzExtensionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthzExtensionsRequest',
    as HashRef[ListAuthzExtensionsRequest()];

declare 'ListAuthzExtensionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::ListAuthzExtensionsResponse'];

coerce 'ListAuthzExtensionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::ListAuthzExtensionsResponse'->new($_) };

declare 'RepeatedListAuthzExtensionsResponse',
    as ArrayRef[ListAuthzExtensionsResponse()];

coerce 'RepeatedListAuthzExtensionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::ListAuthzExtensionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthzExtensionsResponse',
    as HashRef[ListAuthzExtensionsResponse()];

declare 'GetAuthzExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::GetAuthzExtensionRequest'];

coerce 'GetAuthzExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::GetAuthzExtensionRequest'->new($_) };

declare 'RepeatedGetAuthzExtensionRequest',
    as ArrayRef[GetAuthzExtensionRequest()];

coerce 'RepeatedGetAuthzExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::GetAuthzExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthzExtensionRequest',
    as HashRef[GetAuthzExtensionRequest()];

declare 'CreateAuthzExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::CreateAuthzExtensionRequest'];

coerce 'CreateAuthzExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::CreateAuthzExtensionRequest'->new($_) };

declare 'RepeatedCreateAuthzExtensionRequest',
    as ArrayRef[CreateAuthzExtensionRequest()];

coerce 'RepeatedCreateAuthzExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::CreateAuthzExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuthzExtensionRequest',
    as HashRef[CreateAuthzExtensionRequest()];

declare 'UpdateAuthzExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::UpdateAuthzExtensionRequest'];

coerce 'UpdateAuthzExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::UpdateAuthzExtensionRequest'->new($_) };

declare 'RepeatedUpdateAuthzExtensionRequest',
    as ArrayRef[UpdateAuthzExtensionRequest()];

coerce 'RepeatedUpdateAuthzExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::UpdateAuthzExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthzExtensionRequest',
    as HashRef[UpdateAuthzExtensionRequest()];

declare 'DeleteAuthzExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Dep::DeleteAuthzExtensionRequest'];

coerce 'DeleteAuthzExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Dep::DeleteAuthzExtensionRequest'->new($_) };

declare 'RepeatedDeleteAuthzExtensionRequest',
    as ArrayRef[DeleteAuthzExtensionRequest()];

coerce 'RepeatedDeleteAuthzExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Dep::DeleteAuthzExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthzExtensionRequest',
    as HashRef[DeleteAuthzExtensionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::Dep::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
