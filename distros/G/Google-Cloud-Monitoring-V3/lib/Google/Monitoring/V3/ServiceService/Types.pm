package Google::Monitoring::V3::ServiceService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateServiceRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::CreateServiceRequest'];

coerce 'CreateServiceRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::CreateServiceRequest'->new($_) };

declare 'RepeatedCreateServiceRequest',
    as ArrayRef[CreateServiceRequest()];

coerce 'RepeatedCreateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::CreateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceRequest',
    as HashRef[CreateServiceRequest()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Monitoring::V3::ServiceService::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'CreateServiceLevelObjectiveRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::CreateServiceLevelObjectiveRequest'];

coerce 'CreateServiceLevelObjectiveRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::CreateServiceLevelObjectiveRequest'->new($_) };

declare 'RepeatedCreateServiceLevelObjectiveRequest',
    as ArrayRef[CreateServiceLevelObjectiveRequest()];

coerce 'RepeatedCreateServiceLevelObjectiveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::CreateServiceLevelObjectiveRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceLevelObjectiveRequest',
    as HashRef[CreateServiceLevelObjectiveRequest()];

declare 'GetServiceLevelObjectiveRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::GetServiceLevelObjectiveRequest'];

coerce 'GetServiceLevelObjectiveRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::GetServiceLevelObjectiveRequest'->new($_) };

declare 'RepeatedGetServiceLevelObjectiveRequest',
    as ArrayRef[GetServiceLevelObjectiveRequest()];

coerce 'RepeatedGetServiceLevelObjectiveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::GetServiceLevelObjectiveRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceLevelObjectiveRequest',
    as HashRef[GetServiceLevelObjectiveRequest()];

declare 'ListServiceLevelObjectivesRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesRequest'];

coerce 'ListServiceLevelObjectivesRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesRequest'->new($_) };

declare 'RepeatedListServiceLevelObjectivesRequest',
    as ArrayRef[ListServiceLevelObjectivesRequest()];

coerce 'RepeatedListServiceLevelObjectivesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceLevelObjectivesRequest',
    as HashRef[ListServiceLevelObjectivesRequest()];

declare 'ListServiceLevelObjectivesResponse',
    as InstanceOf['Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesResponse'];

coerce 'ListServiceLevelObjectivesResponse',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesResponse'->new($_) };

declare 'RepeatedListServiceLevelObjectivesResponse',
    as ArrayRef[ListServiceLevelObjectivesResponse()];

coerce 'RepeatedListServiceLevelObjectivesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::ListServiceLevelObjectivesResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceLevelObjectivesResponse',
    as HashRef[ListServiceLevelObjectivesResponse()];

declare 'UpdateServiceLevelObjectiveRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::UpdateServiceLevelObjectiveRequest'];

coerce 'UpdateServiceLevelObjectiveRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::UpdateServiceLevelObjectiveRequest'->new($_) };

declare 'RepeatedUpdateServiceLevelObjectiveRequest',
    as ArrayRef[UpdateServiceLevelObjectiveRequest()];

coerce 'RepeatedUpdateServiceLevelObjectiveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::UpdateServiceLevelObjectiveRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceLevelObjectiveRequest',
    as HashRef[UpdateServiceLevelObjectiveRequest()];

declare 'DeleteServiceLevelObjectiveRequest',
    as InstanceOf['Google::Monitoring::V3::ServiceService::DeleteServiceLevelObjectiveRequest'];

coerce 'DeleteServiceLevelObjectiveRequest',
    from HashRef, via { 'Google::Monitoring::V3::ServiceService::DeleteServiceLevelObjectiveRequest'->new($_) };

declare 'RepeatedDeleteServiceLevelObjectiveRequest',
    as ArrayRef[DeleteServiceLevelObjectiveRequest()];

coerce 'RepeatedDeleteServiceLevelObjectiveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::ServiceService::DeleteServiceLevelObjectiveRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceLevelObjectiveRequest',
    as HashRef[DeleteServiceLevelObjectiveRequest()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::ServiceService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
