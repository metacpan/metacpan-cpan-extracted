package Google::Cloud::Run::V2::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateServiceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Service::CreateServiceRequest'];

coerce 'CreateServiceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::CreateServiceRequest'->new($_) };

declare 'RepeatedCreateServiceRequest',
    as ArrayRef[CreateServiceRequest()];

coerce 'RepeatedCreateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::CreateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceRequest',
    as HashRef[CreateServiceRequest()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Service::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Run::V2::Service::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Run::V2::Service::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Service::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Cloud::Run::V2::Service::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'Service',
    as InstanceOf['Google::Cloud::Run::V2::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'MultiRegionSettings',
    as InstanceOf['Google::Cloud::Run::V2::Service::Service::MultiRegionSettings'];

coerce 'MultiRegionSettings',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::Service::MultiRegionSettings'->new($_) };

declare 'RepeatedMultiRegionSettings',
    as ArrayRef[MultiRegionSettings()];

coerce 'RepeatedMultiRegionSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::Service::MultiRegionSettings'->new($_) } @$_ ] };

declare 'MapStringMultiRegionSettings',
    as HashRef[MultiRegionSettings()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Service::Service::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::Service::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::Service::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Service::Service::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Service::Service::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Service::Service::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
