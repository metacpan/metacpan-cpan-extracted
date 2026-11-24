package Google::Cloud::Networkconnectivity::V1alpha1::Hub::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'State',
    as (Int | Str);

declare 'Hub',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::Hub'];

coerce 'Hub',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Hub'->new($_) };

declare 'RepeatedHub',
    as ArrayRef[Hub()];

coerce 'RepeatedHub',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Hub'->new($_) } @$_ ] };

declare 'MapStringHub',
    as HashRef[Hub()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::Hub::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Hub::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Hub::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Spoke',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::Spoke'];

coerce 'Spoke',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Spoke'->new($_) };

declare 'RepeatedSpoke',
    as ArrayRef[Spoke()];

coerce 'RepeatedSpoke',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Spoke'->new($_) } @$_ ] };

declare 'MapStringSpoke',
    as HashRef[Spoke()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::Spoke::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Spoke::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::Spoke::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListHubsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListHubsRequest'];

coerce 'ListHubsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListHubsRequest'->new($_) };

declare 'RepeatedListHubsRequest',
    as ArrayRef[ListHubsRequest()];

coerce 'RepeatedListHubsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListHubsRequest'->new($_) } @$_ ] };

declare 'MapStringListHubsRequest',
    as HashRef[ListHubsRequest()];

declare 'ListHubsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListHubsResponse'];

coerce 'ListHubsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListHubsResponse'->new($_) };

declare 'RepeatedListHubsResponse',
    as ArrayRef[ListHubsResponse()];

coerce 'RepeatedListHubsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListHubsResponse'->new($_) } @$_ ] };

declare 'MapStringListHubsResponse',
    as HashRef[ListHubsResponse()];

declare 'GetHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::GetHubRequest'];

coerce 'GetHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::GetHubRequest'->new($_) };

declare 'RepeatedGetHubRequest',
    as ArrayRef[GetHubRequest()];

coerce 'RepeatedGetHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::GetHubRequest'->new($_) } @$_ ] };

declare 'MapStringGetHubRequest',
    as HashRef[GetHubRequest()];

declare 'CreateHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::CreateHubRequest'];

coerce 'CreateHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::CreateHubRequest'->new($_) };

declare 'RepeatedCreateHubRequest',
    as ArrayRef[CreateHubRequest()];

coerce 'RepeatedCreateHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::CreateHubRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHubRequest',
    as HashRef[CreateHubRequest()];

declare 'UpdateHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::UpdateHubRequest'];

coerce 'UpdateHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::UpdateHubRequest'->new($_) };

declare 'RepeatedUpdateHubRequest',
    as ArrayRef[UpdateHubRequest()];

coerce 'RepeatedUpdateHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::UpdateHubRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHubRequest',
    as HashRef[UpdateHubRequest()];

declare 'DeleteHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::DeleteHubRequest'];

coerce 'DeleteHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::DeleteHubRequest'->new($_) };

declare 'RepeatedDeleteHubRequest',
    as ArrayRef[DeleteHubRequest()];

coerce 'RepeatedDeleteHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::DeleteHubRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHubRequest',
    as HashRef[DeleteHubRequest()];

declare 'ListSpokesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListSpokesRequest'];

coerce 'ListSpokesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListSpokesRequest'->new($_) };

declare 'RepeatedListSpokesRequest',
    as ArrayRef[ListSpokesRequest()];

coerce 'RepeatedListSpokesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListSpokesRequest'->new($_) } @$_ ] };

declare 'MapStringListSpokesRequest',
    as HashRef[ListSpokesRequest()];

declare 'ListSpokesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListSpokesResponse'];

coerce 'ListSpokesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListSpokesResponse'->new($_) };

declare 'RepeatedListSpokesResponse',
    as ArrayRef[ListSpokesResponse()];

coerce 'RepeatedListSpokesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::ListSpokesResponse'->new($_) } @$_ ] };

declare 'MapStringListSpokesResponse',
    as HashRef[ListSpokesResponse()];

declare 'GetSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::GetSpokeRequest'];

coerce 'GetSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::GetSpokeRequest'->new($_) };

declare 'RepeatedGetSpokeRequest',
    as ArrayRef[GetSpokeRequest()];

coerce 'RepeatedGetSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::GetSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringGetSpokeRequest',
    as HashRef[GetSpokeRequest()];

declare 'CreateSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::CreateSpokeRequest'];

coerce 'CreateSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::CreateSpokeRequest'->new($_) };

declare 'RepeatedCreateSpokeRequest',
    as ArrayRef[CreateSpokeRequest()];

coerce 'RepeatedCreateSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::CreateSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSpokeRequest',
    as HashRef[CreateSpokeRequest()];

declare 'UpdateSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::UpdateSpokeRequest'];

coerce 'UpdateSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::UpdateSpokeRequest'->new($_) };

declare 'RepeatedUpdateSpokeRequest',
    as ArrayRef[UpdateSpokeRequest()];

coerce 'RepeatedUpdateSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::UpdateSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSpokeRequest',
    as HashRef[UpdateSpokeRequest()];

declare 'DeleteSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::DeleteSpokeRequest'];

coerce 'DeleteSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::DeleteSpokeRequest'->new($_) };

declare 'RepeatedDeleteSpokeRequest',
    as ArrayRef[DeleteSpokeRequest()];

coerce 'RepeatedDeleteSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::DeleteSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSpokeRequest',
    as HashRef[DeleteSpokeRequest()];

declare 'RouterApplianceInstance',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1alpha1::Hub::RouterApplianceInstance'];

coerce 'RouterApplianceInstance',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::RouterApplianceInstance'->new($_) };

declare 'RepeatedRouterApplianceInstance',
    as ArrayRef[RouterApplianceInstance()];

coerce 'RepeatedRouterApplianceInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1alpha1::Hub::RouterApplianceInstance'->new($_) } @$_ ] };

declare 'MapStringRouterApplianceInstance',
    as HashRef[RouterApplianceInstance()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1alpha1::Hub::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
