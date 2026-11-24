package Google::Cloud::Apihub::V1::ProvisioningService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateApiHubInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest'];

coerce 'CreateApiHubInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest'->new($_) };

declare 'RepeatedCreateApiHubInstanceRequest',
    as ArrayRef[CreateApiHubInstanceRequest()];

coerce 'RepeatedCreateApiHubInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ProvisioningService::CreateApiHubInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApiHubInstanceRequest',
    as HashRef[CreateApiHubInstanceRequest()];

declare 'DeleteApiHubInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ProvisioningService::DeleteApiHubInstanceRequest'];

coerce 'DeleteApiHubInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ProvisioningService::DeleteApiHubInstanceRequest'->new($_) };

declare 'RepeatedDeleteApiHubInstanceRequest',
    as ArrayRef[DeleteApiHubInstanceRequest()];

coerce 'RepeatedDeleteApiHubInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ProvisioningService::DeleteApiHubInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApiHubInstanceRequest',
    as HashRef[DeleteApiHubInstanceRequest()];

declare 'GetApiHubInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ProvisioningService::GetApiHubInstanceRequest'];

coerce 'GetApiHubInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ProvisioningService::GetApiHubInstanceRequest'->new($_) };

declare 'RepeatedGetApiHubInstanceRequest',
    as ArrayRef[GetApiHubInstanceRequest()];

coerce 'RepeatedGetApiHubInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ProvisioningService::GetApiHubInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetApiHubInstanceRequest',
    as HashRef[GetApiHubInstanceRequest()];

declare 'LookupApiHubInstanceRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceRequest'];

coerce 'LookupApiHubInstanceRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceRequest'->new($_) };

declare 'RepeatedLookupApiHubInstanceRequest',
    as ArrayRef[LookupApiHubInstanceRequest()];

coerce 'RepeatedLookupApiHubInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringLookupApiHubInstanceRequest',
    as HashRef[LookupApiHubInstanceRequest()];

declare 'LookupApiHubInstanceResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceResponse'];

coerce 'LookupApiHubInstanceResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceResponse'->new($_) };

declare 'RepeatedLookupApiHubInstanceResponse',
    as ArrayRef[LookupApiHubInstanceResponse()];

coerce 'RepeatedLookupApiHubInstanceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ProvisioningService::LookupApiHubInstanceResponse'->new($_) } @$_ ] };

declare 'MapStringLookupApiHubInstanceResponse',
    as HashRef[LookupApiHubInstanceResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::ProvisioningService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
