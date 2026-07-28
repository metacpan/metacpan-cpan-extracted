package Google::Cloud::Networkservices::V1::ServiceBinding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServiceBinding',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding'];

coerce 'ServiceBinding',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding'->new($_) };

declare 'RepeatedServiceBinding',
    as ArrayRef[ServiceBinding()];

coerce 'RepeatedServiceBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding'->new($_) } @$_ ] };

declare 'MapStringServiceBinding',
    as HashRef[ServiceBinding()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::ServiceBinding::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServiceBindingsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsRequest'];

coerce 'ListServiceBindingsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsRequest'->new($_) };

declare 'RepeatedListServiceBindingsRequest',
    as ArrayRef[ListServiceBindingsRequest()];

coerce 'RepeatedListServiceBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceBindingsRequest',
    as HashRef[ListServiceBindingsRequest()];

declare 'ListServiceBindingsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsResponse'];

coerce 'ListServiceBindingsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsResponse'->new($_) };

declare 'RepeatedListServiceBindingsResponse',
    as ArrayRef[ListServiceBindingsResponse()];

coerce 'RepeatedListServiceBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::ListServiceBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceBindingsResponse',
    as HashRef[ListServiceBindingsResponse()];

declare 'GetServiceBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::GetServiceBindingRequest'];

coerce 'GetServiceBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::GetServiceBindingRequest'->new($_) };

declare 'RepeatedGetServiceBindingRequest',
    as ArrayRef[GetServiceBindingRequest()];

coerce 'RepeatedGetServiceBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::GetServiceBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceBindingRequest',
    as HashRef[GetServiceBindingRequest()];

declare 'CreateServiceBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::CreateServiceBindingRequest'];

coerce 'CreateServiceBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::CreateServiceBindingRequest'->new($_) };

declare 'RepeatedCreateServiceBindingRequest',
    as ArrayRef[CreateServiceBindingRequest()];

coerce 'RepeatedCreateServiceBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::CreateServiceBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceBindingRequest',
    as HashRef[CreateServiceBindingRequest()];

declare 'UpdateServiceBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::UpdateServiceBindingRequest'];

coerce 'UpdateServiceBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::UpdateServiceBindingRequest'->new($_) };

declare 'RepeatedUpdateServiceBindingRequest',
    as ArrayRef[UpdateServiceBindingRequest()];

coerce 'RepeatedUpdateServiceBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::UpdateServiceBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceBindingRequest',
    as HashRef[UpdateServiceBindingRequest()];

declare 'DeleteServiceBindingRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceBinding::DeleteServiceBindingRequest'];

coerce 'DeleteServiceBindingRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceBinding::DeleteServiceBindingRequest'->new($_) };

declare 'RepeatedDeleteServiceBindingRequest',
    as ArrayRef[DeleteServiceBindingRequest()];

coerce 'RepeatedDeleteServiceBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceBinding::DeleteServiceBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceBindingRequest',
    as HashRef[DeleteServiceBindingRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceBinding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
