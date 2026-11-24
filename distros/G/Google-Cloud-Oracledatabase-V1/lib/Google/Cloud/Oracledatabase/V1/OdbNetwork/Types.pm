package Google::Cloud::Oracledatabase::V1::OdbNetwork::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OdbNetwork',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork'];

coerce 'OdbNetwork',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork'->new($_) };

declare 'RepeatedOdbNetwork',
    as ArrayRef[OdbNetwork()];

coerce 'RepeatedOdbNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork'->new($_) } @$_ ] };

declare 'MapStringOdbNetwork',
    as HashRef[OdbNetwork()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateOdbNetworkRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::CreateOdbNetworkRequest'];

coerce 'CreateOdbNetworkRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::CreateOdbNetworkRequest'->new($_) };

declare 'RepeatedCreateOdbNetworkRequest',
    as ArrayRef[CreateOdbNetworkRequest()];

coerce 'RepeatedCreateOdbNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::CreateOdbNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOdbNetworkRequest',
    as HashRef[CreateOdbNetworkRequest()];

declare 'DeleteOdbNetworkRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::DeleteOdbNetworkRequest'];

coerce 'DeleteOdbNetworkRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::DeleteOdbNetworkRequest'->new($_) };

declare 'RepeatedDeleteOdbNetworkRequest',
    as ArrayRef[DeleteOdbNetworkRequest()];

coerce 'RepeatedDeleteOdbNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::DeleteOdbNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOdbNetworkRequest',
    as HashRef[DeleteOdbNetworkRequest()];

declare 'UpdateOdbNetworkRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::UpdateOdbNetworkRequest'];

coerce 'UpdateOdbNetworkRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::UpdateOdbNetworkRequest'->new($_) };

declare 'RepeatedUpdateOdbNetworkRequest',
    as ArrayRef[UpdateOdbNetworkRequest()];

coerce 'RepeatedUpdateOdbNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::UpdateOdbNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOdbNetworkRequest',
    as HashRef[UpdateOdbNetworkRequest()];

declare 'ListOdbNetworksRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksRequest'];

coerce 'ListOdbNetworksRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksRequest'->new($_) };

declare 'RepeatedListOdbNetworksRequest',
    as ArrayRef[ListOdbNetworksRequest()];

coerce 'RepeatedListOdbNetworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksRequest'->new($_) } @$_ ] };

declare 'MapStringListOdbNetworksRequest',
    as HashRef[ListOdbNetworksRequest()];

declare 'ListOdbNetworksResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksResponse'];

coerce 'ListOdbNetworksResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksResponse'->new($_) };

declare 'RepeatedListOdbNetworksResponse',
    as ArrayRef[ListOdbNetworksResponse()];

coerce 'RepeatedListOdbNetworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksResponse'->new($_) } @$_ ] };

declare 'MapStringListOdbNetworksResponse',
    as HashRef[ListOdbNetworksResponse()];

declare 'GetOdbNetworkRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::GetOdbNetworkRequest'];

coerce 'GetOdbNetworkRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::GetOdbNetworkRequest'->new($_) };

declare 'RepeatedGetOdbNetworkRequest',
    as ArrayRef[GetOdbNetworkRequest()];

coerce 'RepeatedGetOdbNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::GetOdbNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringGetOdbNetworkRequest',
    as HashRef[GetOdbNetworkRequest()];

declare 'PscInterfaceConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::PscInterfaceConfig'];

coerce 'PscInterfaceConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::PscInterfaceConfig'->new($_) };

declare 'RepeatedPscInterfaceConfig',
    as ArrayRef[PscInterfaceConfig()];

coerce 'RepeatedPscInterfaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::PscInterfaceConfig'->new($_) } @$_ ] };

declare 'MapStringPscInterfaceConfig',
    as HashRef[PscInterfaceConfig()];

declare 'ServiceConnectivityConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbNetwork::ServiceConnectivityConfig'];

coerce 'ServiceConnectivityConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::ServiceConnectivityConfig'->new($_) };

declare 'RepeatedServiceConnectivityConfig',
    as ArrayRef[ServiceConnectivityConfig()];

coerce 'RepeatedServiceConnectivityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbNetwork::ServiceConnectivityConfig'->new($_) } @$_ ] };

declare 'MapStringServiceConnectivityConfig',
    as HashRef[ServiceConnectivityConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::OdbNetwork::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
