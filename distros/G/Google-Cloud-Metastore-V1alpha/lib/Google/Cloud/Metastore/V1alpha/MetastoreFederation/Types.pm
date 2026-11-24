package Google::Cloud::Metastore::V1alpha::MetastoreFederation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Federation',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation'];

coerce 'Federation',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation'->new($_) };

declare 'RepeatedFederation',
    as ArrayRef[Federation()];

coerce 'RepeatedFederation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation'->new($_) } @$_ ] };

declare 'MapStringFederation',
    as HashRef[Federation()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BackendMetastoresEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::BackendMetastoresEntry'];

coerce 'BackendMetastoresEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::BackendMetastoresEntry'->new($_) };

declare 'RepeatedBackendMetastoresEntry',
    as ArrayRef[BackendMetastoresEntry()];

coerce 'RepeatedBackendMetastoresEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::Federation::BackendMetastoresEntry'->new($_) } @$_ ] };

declare 'MapStringBackendMetastoresEntry',
    as HashRef[BackendMetastoresEntry()];

declare 'BackendMetastore',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::BackendMetastore'];

coerce 'BackendMetastore',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::BackendMetastore'->new($_) };

declare 'RepeatedBackendMetastore',
    as ArrayRef[BackendMetastore()];

coerce 'RepeatedBackendMetastore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::BackendMetastore'->new($_) } @$_ ] };

declare 'MapStringBackendMetastore',
    as HashRef[BackendMetastore()];

declare 'MetastoreType',
    as (Int | Str);

declare 'ListFederationsRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsRequest'];

coerce 'ListFederationsRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsRequest'->new($_) };

declare 'RepeatedListFederationsRequest',
    as ArrayRef[ListFederationsRequest()];

coerce 'RepeatedListFederationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsRequest'->new($_) } @$_ ] };

declare 'MapStringListFederationsRequest',
    as HashRef[ListFederationsRequest()];

declare 'ListFederationsResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsResponse'];

coerce 'ListFederationsResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsResponse'->new($_) };

declare 'RepeatedListFederationsResponse',
    as ArrayRef[ListFederationsResponse()];

coerce 'RepeatedListFederationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::ListFederationsResponse'->new($_) } @$_ ] };

declare 'MapStringListFederationsResponse',
    as HashRef[ListFederationsResponse()];

declare 'GetFederationRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::GetFederationRequest'];

coerce 'GetFederationRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::GetFederationRequest'->new($_) };

declare 'RepeatedGetFederationRequest',
    as ArrayRef[GetFederationRequest()];

coerce 'RepeatedGetFederationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::GetFederationRequest'->new($_) } @$_ ] };

declare 'MapStringGetFederationRequest',
    as HashRef[GetFederationRequest()];

declare 'CreateFederationRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::CreateFederationRequest'];

coerce 'CreateFederationRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::CreateFederationRequest'->new($_) };

declare 'RepeatedCreateFederationRequest',
    as ArrayRef[CreateFederationRequest()];

coerce 'RepeatedCreateFederationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::CreateFederationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFederationRequest',
    as HashRef[CreateFederationRequest()];

declare 'UpdateFederationRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::UpdateFederationRequest'];

coerce 'UpdateFederationRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::UpdateFederationRequest'->new($_) };

declare 'RepeatedUpdateFederationRequest',
    as ArrayRef[UpdateFederationRequest()];

coerce 'RepeatedUpdateFederationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::UpdateFederationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFederationRequest',
    as HashRef[UpdateFederationRequest()];

declare 'DeleteFederationRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::MetastoreFederation::DeleteFederationRequest'];

coerce 'DeleteFederationRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::DeleteFederationRequest'->new($_) };

declare 'RepeatedDeleteFederationRequest',
    as ArrayRef[DeleteFederationRequest()];

coerce 'RepeatedDeleteFederationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::MetastoreFederation::DeleteFederationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFederationRequest',
    as HashRef[DeleteFederationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Metastore::V1alpha::MetastoreFederation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
