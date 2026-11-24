package Google::Cloud::Discoveryengine::V1::LicenseConfigService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateLicenseConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest'];

coerce 'CreateLicenseConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest'->new($_) };

declare 'RepeatedCreateLicenseConfigRequest',
    as ArrayRef[CreateLicenseConfigRequest()];

coerce 'RepeatedCreateLicenseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLicenseConfigRequest',
    as HashRef[CreateLicenseConfigRequest()];

declare 'UpdateLicenseConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::UpdateLicenseConfigRequest'];

coerce 'UpdateLicenseConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::UpdateLicenseConfigRequest'->new($_) };

declare 'RepeatedUpdateLicenseConfigRequest',
    as ArrayRef[UpdateLicenseConfigRequest()];

coerce 'RepeatedUpdateLicenseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::UpdateLicenseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLicenseConfigRequest',
    as HashRef[UpdateLicenseConfigRequest()];

declare 'GetLicenseConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::GetLicenseConfigRequest'];

coerce 'GetLicenseConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::GetLicenseConfigRequest'->new($_) };

declare 'RepeatedGetLicenseConfigRequest',
    as ArrayRef[GetLicenseConfigRequest()];

coerce 'RepeatedGetLicenseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::GetLicenseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetLicenseConfigRequest',
    as HashRef[GetLicenseConfigRequest()];

declare 'ListLicenseConfigsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsRequest'];

coerce 'ListLicenseConfigsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsRequest'->new($_) };

declare 'RepeatedListLicenseConfigsRequest',
    as ArrayRef[ListLicenseConfigsRequest()];

coerce 'RepeatedListLicenseConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListLicenseConfigsRequest',
    as HashRef[ListLicenseConfigsRequest()];

declare 'ListLicenseConfigsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsResponse'];

coerce 'ListLicenseConfigsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsResponse'->new($_) };

declare 'RepeatedListLicenseConfigsResponse',
    as ArrayRef[ListLicenseConfigsResponse()];

coerce 'RepeatedListLicenseConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListLicenseConfigsResponse',
    as HashRef[ListLicenseConfigsResponse()];

declare 'DistributeLicenseConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigRequest'];

coerce 'DistributeLicenseConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigRequest'->new($_) };

declare 'RepeatedDistributeLicenseConfigRequest',
    as ArrayRef[DistributeLicenseConfigRequest()];

coerce 'RepeatedDistributeLicenseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDistributeLicenseConfigRequest',
    as HashRef[DistributeLicenseConfigRequest()];

declare 'DistributeLicenseConfigResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigResponse'];

coerce 'DistributeLicenseConfigResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigResponse'->new($_) };

declare 'RepeatedDistributeLicenseConfigResponse',
    as ArrayRef[DistributeLicenseConfigResponse()];

coerce 'RepeatedDistributeLicenseConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigResponse'->new($_) } @$_ ] };

declare 'MapStringDistributeLicenseConfigResponse',
    as HashRef[DistributeLicenseConfigResponse()];

declare 'RetractLicenseConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigRequest'];

coerce 'RetractLicenseConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigRequest'->new($_) };

declare 'RepeatedRetractLicenseConfigRequest',
    as ArrayRef[RetractLicenseConfigRequest()];

coerce 'RepeatedRetractLicenseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringRetractLicenseConfigRequest',
    as HashRef[RetractLicenseConfigRequest()];

declare 'RetractLicenseConfigResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigResponse'];

coerce 'RetractLicenseConfigResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigResponse'->new($_) };

declare 'RepeatedRetractLicenseConfigResponse',
    as ArrayRef[RetractLicenseConfigResponse()];

coerce 'RepeatedRetractLicenseConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigResponse'->new($_) } @$_ ] };

declare 'MapStringRetractLicenseConfigResponse',
    as HashRef[RetractLicenseConfigResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::LicenseConfigService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
