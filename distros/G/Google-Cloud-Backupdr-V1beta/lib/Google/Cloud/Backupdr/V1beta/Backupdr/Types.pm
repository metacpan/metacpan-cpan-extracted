package Google::Cloud::Backupdr::V1beta::Backupdr::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'PeeringMode',
    as (Int | Str);

declare 'ManagementURI',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::ManagementURI'];

coerce 'ManagementURI',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::ManagementURI'->new($_) };

declare 'RepeatedManagementURI',
    as ArrayRef[ManagementURI()];

coerce 'RepeatedManagementURI',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::ManagementURI'->new($_) } @$_ ] };

declare 'MapStringManagementURI',
    as HashRef[ManagementURI()];

declare 'WorkforceIdentityBasedManagementURI',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::WorkforceIdentityBasedManagementURI'];

coerce 'WorkforceIdentityBasedManagementURI',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::WorkforceIdentityBasedManagementURI'->new($_) };

declare 'RepeatedWorkforceIdentityBasedManagementURI',
    as ArrayRef[WorkforceIdentityBasedManagementURI()];

coerce 'RepeatedWorkforceIdentityBasedManagementURI',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::WorkforceIdentityBasedManagementURI'->new($_) } @$_ ] };

declare 'MapStringWorkforceIdentityBasedManagementURI',
    as HashRef[WorkforceIdentityBasedManagementURI()];

declare 'WorkforceIdentityBasedOAuth2ClientID',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::WorkforceIdentityBasedOAuth2ClientID'];

coerce 'WorkforceIdentityBasedOAuth2ClientID',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::WorkforceIdentityBasedOAuth2ClientID'->new($_) };

declare 'RepeatedWorkforceIdentityBasedOAuth2ClientID',
    as ArrayRef[WorkforceIdentityBasedOAuth2ClientID()];

coerce 'RepeatedWorkforceIdentityBasedOAuth2ClientID',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::WorkforceIdentityBasedOAuth2ClientID'->new($_) } @$_ ] };

declare 'MapStringWorkforceIdentityBasedOAuth2ClientID',
    as HashRef[WorkforceIdentityBasedOAuth2ClientID()];

declare 'ManagementServer',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::ManagementServer'];

coerce 'ManagementServer',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::ManagementServer'->new($_) };

declare 'RepeatedManagementServer',
    as ArrayRef[ManagementServer()];

coerce 'RepeatedManagementServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::ManagementServer'->new($_) } @$_ ] };

declare 'MapStringManagementServer',
    as HashRef[ManagementServer()];

declare 'InstanceType',
    as (Int | Str);

declare 'InstanceState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::ManagementServer::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::ManagementServer::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::ManagementServer::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListManagementServersRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersRequest'];

coerce 'ListManagementServersRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersRequest'->new($_) };

declare 'RepeatedListManagementServersRequest',
    as ArrayRef[ListManagementServersRequest()];

coerce 'RepeatedListManagementServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersRequest'->new($_) } @$_ ] };

declare 'MapStringListManagementServersRequest',
    as HashRef[ListManagementServersRequest()];

declare 'ListManagementServersResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersResponse'];

coerce 'ListManagementServersResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersResponse'->new($_) };

declare 'RepeatedListManagementServersResponse',
    as ArrayRef[ListManagementServersResponse()];

coerce 'RepeatedListManagementServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::ListManagementServersResponse'->new($_) } @$_ ] };

declare 'MapStringListManagementServersResponse',
    as HashRef[ListManagementServersResponse()];

declare 'GetManagementServerRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::GetManagementServerRequest'];

coerce 'GetManagementServerRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::GetManagementServerRequest'->new($_) };

declare 'RepeatedGetManagementServerRequest',
    as ArrayRef[GetManagementServerRequest()];

coerce 'RepeatedGetManagementServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::GetManagementServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetManagementServerRequest',
    as HashRef[GetManagementServerRequest()];

declare 'CreateManagementServerRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::CreateManagementServerRequest'];

coerce 'CreateManagementServerRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::CreateManagementServerRequest'->new($_) };

declare 'RepeatedCreateManagementServerRequest',
    as ArrayRef[CreateManagementServerRequest()];

coerce 'RepeatedCreateManagementServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::CreateManagementServerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateManagementServerRequest',
    as HashRef[CreateManagementServerRequest()];

declare 'DeleteManagementServerRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::DeleteManagementServerRequest'];

coerce 'DeleteManagementServerRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::DeleteManagementServerRequest'->new($_) };

declare 'RepeatedDeleteManagementServerRequest',
    as ArrayRef[DeleteManagementServerRequest()];

coerce 'RepeatedDeleteManagementServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::DeleteManagementServerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteManagementServerRequest',
    as HashRef[DeleteManagementServerRequest()];

declare 'InitializeServiceRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::InitializeServiceRequest'];

coerce 'InitializeServiceRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::InitializeServiceRequest'->new($_) };

declare 'RepeatedInitializeServiceRequest',
    as ArrayRef[InitializeServiceRequest()];

coerce 'RepeatedInitializeServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::InitializeServiceRequest'->new($_) } @$_ ] };

declare 'MapStringInitializeServiceRequest',
    as HashRef[InitializeServiceRequest()];

declare 'InitializeServiceResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::InitializeServiceResponse'];

coerce 'InitializeServiceResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::InitializeServiceResponse'->new($_) };

declare 'RepeatedInitializeServiceResponse',
    as ArrayRef[InitializeServiceResponse()];

coerce 'RepeatedInitializeServiceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::InitializeServiceResponse'->new($_) } @$_ ] };

declare 'MapStringInitializeServiceResponse',
    as HashRef[InitializeServiceResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'AdditionalInfoEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Backupdr::OperationMetadata::AdditionalInfoEntry'];

coerce 'AdditionalInfoEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Backupdr::OperationMetadata::AdditionalInfoEntry'->new($_) };

declare 'RepeatedAdditionalInfoEntry',
    as ArrayRef[AdditionalInfoEntry()];

coerce 'RepeatedAdditionalInfoEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Backupdr::OperationMetadata::AdditionalInfoEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalInfoEntry',
    as HashRef[AdditionalInfoEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::Backupdr::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
