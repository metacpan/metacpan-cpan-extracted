package Google::Cloud::Gkehub::V1beta::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListFeaturesRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest'];

coerce 'ListFeaturesRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest'->new($_) };

declare 'RepeatedListFeaturesRequest',
    as ArrayRef[ListFeaturesRequest()];

coerce 'RepeatedListFeaturesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::ListFeaturesRequest'->new($_) } @$_ ] };

declare 'MapStringListFeaturesRequest',
    as HashRef[ListFeaturesRequest()];

declare 'ListFeaturesResponse',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::ListFeaturesResponse'];

coerce 'ListFeaturesResponse',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::ListFeaturesResponse'->new($_) };

declare 'RepeatedListFeaturesResponse',
    as ArrayRef[ListFeaturesResponse()];

coerce 'RepeatedListFeaturesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::ListFeaturesResponse'->new($_) } @$_ ] };

declare 'MapStringListFeaturesResponse',
    as HashRef[ListFeaturesResponse()];

declare 'GetFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::GetFeatureRequest'];

coerce 'GetFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::GetFeatureRequest'->new($_) };

declare 'RepeatedGetFeatureRequest',
    as ArrayRef[GetFeatureRequest()];

coerce 'RepeatedGetFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::GetFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeatureRequest',
    as HashRef[GetFeatureRequest()];

declare 'CreateFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::CreateFeatureRequest'];

coerce 'CreateFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::CreateFeatureRequest'->new($_) };

declare 'RepeatedCreateFeatureRequest',
    as ArrayRef[CreateFeatureRequest()];

coerce 'RepeatedCreateFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::CreateFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFeatureRequest',
    as HashRef[CreateFeatureRequest()];

declare 'DeleteFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::DeleteFeatureRequest'];

coerce 'DeleteFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::DeleteFeatureRequest'->new($_) };

declare 'RepeatedDeleteFeatureRequest',
    as ArrayRef[DeleteFeatureRequest()];

coerce 'RepeatedDeleteFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::DeleteFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFeatureRequest',
    as HashRef[DeleteFeatureRequest()];

declare 'UpdateFeatureRequest',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::UpdateFeatureRequest'];

coerce 'UpdateFeatureRequest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::UpdateFeatureRequest'->new($_) };

declare 'RepeatedUpdateFeatureRequest',
    as ArrayRef[UpdateFeatureRequest()];

coerce 'RepeatedUpdateFeatureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::UpdateFeatureRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFeatureRequest',
    as HashRef[UpdateFeatureRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Gkehub::V1beta::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Gkehub::V1beta::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1beta::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::V1beta::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
