package Google::Cloud::Kms::V1::EkmService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListEkmConnectionsRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsRequest'];

coerce 'ListEkmConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsRequest'->new($_) };

declare 'RepeatedListEkmConnectionsRequest',
    as ArrayRef[ListEkmConnectionsRequest()];

coerce 'RepeatedListEkmConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListEkmConnectionsRequest',
    as HashRef[ListEkmConnectionsRequest()];

declare 'ListEkmConnectionsResponse',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsResponse'];

coerce 'ListEkmConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsResponse'->new($_) };

declare 'RepeatedListEkmConnectionsResponse',
    as ArrayRef[ListEkmConnectionsResponse()];

coerce 'RepeatedListEkmConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::ListEkmConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListEkmConnectionsResponse',
    as HashRef[ListEkmConnectionsResponse()];

declare 'GetEkmConnectionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::GetEkmConnectionRequest'];

coerce 'GetEkmConnectionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::GetEkmConnectionRequest'->new($_) };

declare 'RepeatedGetEkmConnectionRequest',
    as ArrayRef[GetEkmConnectionRequest()];

coerce 'RepeatedGetEkmConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::GetEkmConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetEkmConnectionRequest',
    as HashRef[GetEkmConnectionRequest()];

declare 'CreateEkmConnectionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::CreateEkmConnectionRequest'];

coerce 'CreateEkmConnectionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::CreateEkmConnectionRequest'->new($_) };

declare 'RepeatedCreateEkmConnectionRequest',
    as ArrayRef[CreateEkmConnectionRequest()];

coerce 'RepeatedCreateEkmConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::CreateEkmConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEkmConnectionRequest',
    as HashRef[CreateEkmConnectionRequest()];

declare 'UpdateEkmConnectionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::UpdateEkmConnectionRequest'];

coerce 'UpdateEkmConnectionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::UpdateEkmConnectionRequest'->new($_) };

declare 'RepeatedUpdateEkmConnectionRequest',
    as ArrayRef[UpdateEkmConnectionRequest()];

coerce 'RepeatedUpdateEkmConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::UpdateEkmConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEkmConnectionRequest',
    as HashRef[UpdateEkmConnectionRequest()];

declare 'GetEkmConfigRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::GetEkmConfigRequest'];

coerce 'GetEkmConfigRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::GetEkmConfigRequest'->new($_) };

declare 'RepeatedGetEkmConfigRequest',
    as ArrayRef[GetEkmConfigRequest()];

coerce 'RepeatedGetEkmConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::GetEkmConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetEkmConfigRequest',
    as HashRef[GetEkmConfigRequest()];

declare 'UpdateEkmConfigRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::UpdateEkmConfigRequest'];

coerce 'UpdateEkmConfigRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::UpdateEkmConfigRequest'->new($_) };

declare 'RepeatedUpdateEkmConfigRequest',
    as ArrayRef[UpdateEkmConfigRequest()];

coerce 'RepeatedUpdateEkmConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::UpdateEkmConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEkmConfigRequest',
    as HashRef[UpdateEkmConfigRequest()];

declare 'Certificate',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::Certificate'];

coerce 'Certificate',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::Certificate'->new($_) };

declare 'RepeatedCertificate',
    as ArrayRef[Certificate()];

coerce 'RepeatedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::Certificate'->new($_) } @$_ ] };

declare 'MapStringCertificate',
    as HashRef[Certificate()];

declare 'EkmConnection',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::EkmConnection'];

coerce 'EkmConnection',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::EkmConnection'->new($_) };

declare 'RepeatedEkmConnection',
    as ArrayRef[EkmConnection()];

coerce 'RepeatedEkmConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::EkmConnection'->new($_) } @$_ ] };

declare 'MapStringEkmConnection',
    as HashRef[EkmConnection()];

declare 'KeyManagementMode',
    as (Int | Str);

declare 'ServiceResolver',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::EkmConnection::ServiceResolver'];

coerce 'ServiceResolver',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::EkmConnection::ServiceResolver'->new($_) };

declare 'RepeatedServiceResolver',
    as ArrayRef[ServiceResolver()];

coerce 'RepeatedServiceResolver',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::EkmConnection::ServiceResolver'->new($_) } @$_ ] };

declare 'MapStringServiceResolver',
    as HashRef[ServiceResolver()];

declare 'EkmConfig',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::EkmConfig'];

coerce 'EkmConfig',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::EkmConfig'->new($_) };

declare 'RepeatedEkmConfig',
    as ArrayRef[EkmConfig()];

coerce 'RepeatedEkmConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::EkmConfig'->new($_) } @$_ ] };

declare 'MapStringEkmConfig',
    as HashRef[EkmConfig()];

declare 'VerifyConnectivityRequest',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::VerifyConnectivityRequest'];

coerce 'VerifyConnectivityRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::VerifyConnectivityRequest'->new($_) };

declare 'RepeatedVerifyConnectivityRequest',
    as ArrayRef[VerifyConnectivityRequest()];

coerce 'RepeatedVerifyConnectivityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::VerifyConnectivityRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyConnectivityRequest',
    as HashRef[VerifyConnectivityRequest()];

declare 'VerifyConnectivityResponse',
    as InstanceOf['Google::Cloud::Kms::V1::EkmService::VerifyConnectivityResponse'];

coerce 'VerifyConnectivityResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::EkmService::VerifyConnectivityResponse'->new($_) };

declare 'RepeatedVerifyConnectivityResponse',
    as ArrayRef[VerifyConnectivityResponse()];

coerce 'RepeatedVerifyConnectivityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::EkmService::VerifyConnectivityResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyConnectivityResponse',
    as HashRef[VerifyConnectivityResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::EkmService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
