package Google::Cloud::Networkservices::V1beta1::Dep::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventType',
    as (Int | Str);

declare 'LoadBalancingScheme',
    as (Int | Str);

declare 'ExtensionChain',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain'];

coerce 'ExtensionChain',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain'->new($_) };

declare 'RepeatedExtensionChain',
    as ArrayRef[ExtensionChain()];

coerce 'RepeatedExtensionChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain'->new($_) } @$_ ] };

declare 'MapStringExtensionChain',
    as HashRef[ExtensionChain()];

declare 'MatchCondition',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain::MatchCondition'];

coerce 'MatchCondition',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain::MatchCondition'->new($_) };

declare 'RepeatedMatchCondition',
    as ArrayRef[MatchCondition()];

coerce 'RepeatedMatchCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain::MatchCondition'->new($_) } @$_ ] };

declare 'MapStringMatchCondition',
    as HashRef[MatchCondition()];

declare 'Extension',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain::Extension'];

coerce 'Extension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain::Extension'->new($_) };

declare 'RepeatedExtension',
    as ArrayRef[Extension()];

coerce 'RepeatedExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionChain::Extension'->new($_) } @$_ ] };

declare 'MapStringExtension',
    as HashRef[Extension()];

declare 'LbTrafficExtension',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::LbTrafficExtension'];

coerce 'LbTrafficExtension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::LbTrafficExtension'->new($_) };

declare 'RepeatedLbTrafficExtension',
    as ArrayRef[LbTrafficExtension()];

coerce 'RepeatedLbTrafficExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::LbTrafficExtension'->new($_) } @$_ ] };

declare 'MapStringLbTrafficExtension',
    as HashRef[LbTrafficExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::LbTrafficExtension::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::LbTrafficExtension::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::LbTrafficExtension::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListLbTrafficExtensionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ListLbTrafficExtensionsRequest'];

coerce 'ListLbTrafficExtensionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbTrafficExtensionsRequest'->new($_) };

declare 'RepeatedListLbTrafficExtensionsRequest',
    as ArrayRef[ListLbTrafficExtensionsRequest()];

coerce 'RepeatedListLbTrafficExtensionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbTrafficExtensionsRequest'->new($_) } @$_ ] };

declare 'MapStringListLbTrafficExtensionsRequest',
    as HashRef[ListLbTrafficExtensionsRequest()];

declare 'ListLbTrafficExtensionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ListLbTrafficExtensionsResponse'];

coerce 'ListLbTrafficExtensionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbTrafficExtensionsResponse'->new($_) };

declare 'RepeatedListLbTrafficExtensionsResponse',
    as ArrayRef[ListLbTrafficExtensionsResponse()];

coerce 'RepeatedListLbTrafficExtensionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbTrafficExtensionsResponse'->new($_) } @$_ ] };

declare 'MapStringListLbTrafficExtensionsResponse',
    as HashRef[ListLbTrafficExtensionsResponse()];

declare 'GetLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::GetLbTrafficExtensionRequest'];

coerce 'GetLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::GetLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedGetLbTrafficExtensionRequest',
    as ArrayRef[GetLbTrafficExtensionRequest()];

coerce 'RepeatedGetLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::GetLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringGetLbTrafficExtensionRequest',
    as HashRef[GetLbTrafficExtensionRequest()];

declare 'CreateLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::CreateLbTrafficExtensionRequest'];

coerce 'CreateLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::CreateLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedCreateLbTrafficExtensionRequest',
    as ArrayRef[CreateLbTrafficExtensionRequest()];

coerce 'RepeatedCreateLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::CreateLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLbTrafficExtensionRequest',
    as HashRef[CreateLbTrafficExtensionRequest()];

declare 'UpdateLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::UpdateLbTrafficExtensionRequest'];

coerce 'UpdateLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::UpdateLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedUpdateLbTrafficExtensionRequest',
    as ArrayRef[UpdateLbTrafficExtensionRequest()];

coerce 'RepeatedUpdateLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::UpdateLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLbTrafficExtensionRequest',
    as HashRef[UpdateLbTrafficExtensionRequest()];

declare 'DeleteLbTrafficExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::DeleteLbTrafficExtensionRequest'];

coerce 'DeleteLbTrafficExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::DeleteLbTrafficExtensionRequest'->new($_) };

declare 'RepeatedDeleteLbTrafficExtensionRequest',
    as ArrayRef[DeleteLbTrafficExtensionRequest()];

coerce 'RepeatedDeleteLbTrafficExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::DeleteLbTrafficExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLbTrafficExtensionRequest',
    as HashRef[DeleteLbTrafficExtensionRequest()];

declare 'LbRouteExtension',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::LbRouteExtension'];

coerce 'LbRouteExtension',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::LbRouteExtension'->new($_) };

declare 'RepeatedLbRouteExtension',
    as ArrayRef[LbRouteExtension()];

coerce 'RepeatedLbRouteExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::LbRouteExtension'->new($_) } @$_ ] };

declare 'MapStringLbRouteExtension',
    as HashRef[LbRouteExtension()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::LbRouteExtension::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::LbRouteExtension::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::LbRouteExtension::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListLbRouteExtensionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ListLbRouteExtensionsRequest'];

coerce 'ListLbRouteExtensionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbRouteExtensionsRequest'->new($_) };

declare 'RepeatedListLbRouteExtensionsRequest',
    as ArrayRef[ListLbRouteExtensionsRequest()];

coerce 'RepeatedListLbRouteExtensionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbRouteExtensionsRequest'->new($_) } @$_ ] };

declare 'MapStringListLbRouteExtensionsRequest',
    as HashRef[ListLbRouteExtensionsRequest()];

declare 'ListLbRouteExtensionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ListLbRouteExtensionsResponse'];

coerce 'ListLbRouteExtensionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbRouteExtensionsResponse'->new($_) };

declare 'RepeatedListLbRouteExtensionsResponse',
    as ArrayRef[ListLbRouteExtensionsResponse()];

coerce 'RepeatedListLbRouteExtensionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ListLbRouteExtensionsResponse'->new($_) } @$_ ] };

declare 'MapStringListLbRouteExtensionsResponse',
    as HashRef[ListLbRouteExtensionsResponse()];

declare 'GetLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::GetLbRouteExtensionRequest'];

coerce 'GetLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::GetLbRouteExtensionRequest'->new($_) };

declare 'RepeatedGetLbRouteExtensionRequest',
    as ArrayRef[GetLbRouteExtensionRequest()];

coerce 'RepeatedGetLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::GetLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringGetLbRouteExtensionRequest',
    as HashRef[GetLbRouteExtensionRequest()];

declare 'CreateLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::CreateLbRouteExtensionRequest'];

coerce 'CreateLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::CreateLbRouteExtensionRequest'->new($_) };

declare 'RepeatedCreateLbRouteExtensionRequest',
    as ArrayRef[CreateLbRouteExtensionRequest()];

coerce 'RepeatedCreateLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::CreateLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLbRouteExtensionRequest',
    as HashRef[CreateLbRouteExtensionRequest()];

declare 'UpdateLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::UpdateLbRouteExtensionRequest'];

coerce 'UpdateLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::UpdateLbRouteExtensionRequest'->new($_) };

declare 'RepeatedUpdateLbRouteExtensionRequest',
    as ArrayRef[UpdateLbRouteExtensionRequest()];

coerce 'RepeatedUpdateLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::UpdateLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLbRouteExtensionRequest',
    as HashRef[UpdateLbRouteExtensionRequest()];

declare 'DeleteLbRouteExtensionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::DeleteLbRouteExtensionRequest'];

coerce 'DeleteLbRouteExtensionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::DeleteLbRouteExtensionRequest'->new($_) };

declare 'RepeatedDeleteLbRouteExtensionRequest',
    as ArrayRef[DeleteLbRouteExtensionRequest()];

coerce 'RepeatedDeleteLbRouteExtensionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::DeleteLbRouteExtensionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLbRouteExtensionRequest',
    as HashRef[DeleteLbRouteExtensionRequest()];

declare 'ExtensionBinding',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding'];

coerce 'ExtensionBinding',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding'->new($_) };

declare 'RepeatedExtensionBinding',
    as ArrayRef[ExtensionBinding()];

coerce 'RepeatedExtensionBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding'->new($_) } @$_ ] };

declare 'MapStringExtensionBinding',
    as HashRef[ExtensionBinding()];

declare 'Target',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::Target::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::Target::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::Target::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'ResourceType',
    as (Int | Str);

declare 'MatchCondition',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition'];

coerce 'MatchCondition',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition'->new($_) };

declare 'RepeatedMatchCondition',
    as ArrayRef[MatchCondition()];

coerce 'RepeatedMatchCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition'->new($_) } @$_ ] };

declare 'MapStringMatchCondition',
    as HashRef[MatchCondition()];

declare 'StringMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::StringMatch'];

coerce 'StringMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::StringMatch'->new($_) };

declare 'RepeatedStringMatch',
    as ArrayRef[StringMatch()];

coerce 'RepeatedStringMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::StringMatch'->new($_) } @$_ ] };

declare 'MapStringStringMatch',
    as HashRef[StringMatch()];

declare 'HeaderMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::HeaderMatch'];

coerce 'HeaderMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::HeaderMatch'->new($_) };

declare 'RepeatedHeaderMatch',
    as ArrayRef[HeaderMatch()];

coerce 'RepeatedHeaderMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::HeaderMatch'->new($_) } @$_ ] };

declare 'MapStringHeaderMatch',
    as HashRef[HeaderMatch()];

declare 'To',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To'];

coerce 'To',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To'->new($_) };

declare 'RepeatedTo',
    as ArrayRef[To()];

coerce 'RepeatedTo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To'->new($_) } @$_ ] };

declare 'MapStringTo',
    as HashRef[To()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'HeaderSet',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To::Destination::HeaderSet'];

coerce 'HeaderSet',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To::Destination::HeaderSet'->new($_) };

declare 'RepeatedHeaderSet',
    as ArrayRef[HeaderSet()];

coerce 'RepeatedHeaderSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::MatchCondition::To::Destination::HeaderSet'->new($_) } @$_ ] };

declare 'MapStringHeaderSet',
    as HashRef[HeaderSet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ProducerMetadataEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::ProducerMetadataEntry'];

coerce 'ProducerMetadataEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::ProducerMetadataEntry'->new($_) };

declare 'RepeatedProducerMetadataEntry',
    as ArrayRef[ProducerMetadataEntry()];

coerce 'RepeatedProducerMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ExtensionBinding::ProducerMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringProducerMetadataEntry',
    as HashRef[ProducerMetadataEntry()];

declare 'ListExtensionBindingsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ListExtensionBindingsRequest'];

coerce 'ListExtensionBindingsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ListExtensionBindingsRequest'->new($_) };

declare 'RepeatedListExtensionBindingsRequest',
    as ArrayRef[ListExtensionBindingsRequest()];

coerce 'RepeatedListExtensionBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ListExtensionBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListExtensionBindingsRequest',
    as HashRef[ListExtensionBindingsRequest()];

declare 'ListExtensionBindingsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::ListExtensionBindingsResponse'];

coerce 'ListExtensionBindingsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::ListExtensionBindingsResponse'->new($_) };

declare 'RepeatedListExtensionBindingsResponse',
    as ArrayRef[ListExtensionBindingsResponse()];

coerce 'RepeatedListExtensionBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::ListExtensionBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListExtensionBindingsResponse',
    as HashRef[ListExtensionBindingsResponse()];

declare 'GetExtensionBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::GetExtensionBindingRequest'];

coerce 'GetExtensionBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::GetExtensionBindingRequest'->new($_) };

declare 'RepeatedGetExtensionBindingRequest',
    as ArrayRef[GetExtensionBindingRequest()];

coerce 'RepeatedGetExtensionBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::GetExtensionBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetExtensionBindingRequest',
    as HashRef[GetExtensionBindingRequest()];

declare 'CreateExtensionBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::CreateExtensionBindingRequest'];

coerce 'CreateExtensionBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::CreateExtensionBindingRequest'->new($_) };

declare 'RepeatedCreateExtensionBindingRequest',
    as ArrayRef[CreateExtensionBindingRequest()];

coerce 'RepeatedCreateExtensionBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::CreateExtensionBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExtensionBindingRequest',
    as HashRef[CreateExtensionBindingRequest()];

declare 'UpdateExtensionBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::UpdateExtensionBindingRequest'];

coerce 'UpdateExtensionBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::UpdateExtensionBindingRequest'->new($_) };

declare 'RepeatedUpdateExtensionBindingRequest',
    as ArrayRef[UpdateExtensionBindingRequest()];

coerce 'RepeatedUpdateExtensionBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::UpdateExtensionBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExtensionBindingRequest',
    as HashRef[UpdateExtensionBindingRequest()];

declare 'DeleteExtensionBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1beta1::Dep::DeleteExtensionBindingRequest'];

coerce 'DeleteExtensionBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1beta1::Dep::DeleteExtensionBindingRequest'->new($_) };

declare 'RepeatedDeleteExtensionBindingRequest',
    as ArrayRef[DeleteExtensionBindingRequest()];

coerce 'RepeatedDeleteExtensionBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1beta1::Dep::DeleteExtensionBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExtensionBindingRequest',
    as HashRef[DeleteExtensionBindingRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1beta1::Dep::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
