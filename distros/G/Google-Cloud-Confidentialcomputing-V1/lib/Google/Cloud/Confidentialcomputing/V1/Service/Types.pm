package Google::Cloud::Confidentialcomputing::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SigningAlgorithm',
    as (Int | Str);

declare 'TokenType',
    as (Int | Str);

declare 'SignatureType',
    as (Int | Str);

declare 'TokenProfile',
    as (Int | Str);

declare 'Challenge',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::Challenge'];

coerce 'Challenge',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::Challenge'->new($_) };

declare 'RepeatedChallenge',
    as ArrayRef[Challenge()];

coerce 'RepeatedChallenge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::Challenge'->new($_) } @$_ ] };

declare 'MapStringChallenge',
    as HashRef[Challenge()];

declare 'CreateChallengeRequest',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::CreateChallengeRequest'];

coerce 'CreateChallengeRequest',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::CreateChallengeRequest'->new($_) };

declare 'RepeatedCreateChallengeRequest',
    as ArrayRef[CreateChallengeRequest()];

coerce 'RepeatedCreateChallengeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::CreateChallengeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChallengeRequest',
    as HashRef[CreateChallengeRequest()];

declare 'VerifyAttestationRequest',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyAttestationRequest'];

coerce 'VerifyAttestationRequest',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyAttestationRequest'->new($_) };

declare 'RepeatedVerifyAttestationRequest',
    as ArrayRef[VerifyAttestationRequest()];

coerce 'RepeatedVerifyAttestationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyAttestationRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyAttestationRequest',
    as HashRef[VerifyAttestationRequest()];

declare 'NvidiaAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation'];

coerce 'NvidiaAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation'->new($_) };

declare 'RepeatedNvidiaAttestation',
    as ArrayRef[NvidiaAttestation()];

coerce 'RepeatedNvidiaAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation'->new($_) } @$_ ] };

declare 'MapStringNvidiaAttestation',
    as HashRef[NvidiaAttestation()];

declare 'GpuArchitectureType',
    as (Int | Str);

declare 'GpuInfo',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::GpuInfo'];

coerce 'GpuInfo',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::GpuInfo'->new($_) };

declare 'RepeatedGpuInfo',
    as ArrayRef[GpuInfo()];

coerce 'RepeatedGpuInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::GpuInfo'->new($_) } @$_ ] };

declare 'MapStringGpuInfo',
    as HashRef[GpuInfo()];

declare 'SwitchInfo',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::SwitchInfo'];

coerce 'SwitchInfo',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::SwitchInfo'->new($_) };

declare 'RepeatedSwitchInfo',
    as ArrayRef[SwitchInfo()];

coerce 'RepeatedSwitchInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::SwitchInfo'->new($_) } @$_ ] };

declare 'MapStringSwitchInfo',
    as HashRef[SwitchInfo()];

declare 'SinglePassthroughAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::SinglePassthroughAttestation'];

coerce 'SinglePassthroughAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::SinglePassthroughAttestation'->new($_) };

declare 'RepeatedSinglePassthroughAttestation',
    as ArrayRef[SinglePassthroughAttestation()];

coerce 'RepeatedSinglePassthroughAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::SinglePassthroughAttestation'->new($_) } @$_ ] };

declare 'MapStringSinglePassthroughAttestation',
    as HashRef[SinglePassthroughAttestation()];

declare 'ProtectedPcieAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::ProtectedPcieAttestation'];

coerce 'ProtectedPcieAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::ProtectedPcieAttestation'->new($_) };

declare 'RepeatedProtectedPcieAttestation',
    as ArrayRef[ProtectedPcieAttestation()];

coerce 'RepeatedProtectedPcieAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::ProtectedPcieAttestation'->new($_) } @$_ ] };

declare 'MapStringProtectedPcieAttestation',
    as HashRef[ProtectedPcieAttestation()];

declare 'MultiGpuSecurePassthroughAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::MultiGpuSecurePassthroughAttestation'];

coerce 'MultiGpuSecurePassthroughAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::MultiGpuSecurePassthroughAttestation'->new($_) };

declare 'RepeatedMultiGpuSecurePassthroughAttestation',
    as ArrayRef[MultiGpuSecurePassthroughAttestation()];

coerce 'RepeatedMultiGpuSecurePassthroughAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::NvidiaAttestation::MultiGpuSecurePassthroughAttestation'->new($_) } @$_ ] };

declare 'MapStringMultiGpuSecurePassthroughAttestation',
    as HashRef[MultiGpuSecurePassthroughAttestation()];

declare 'TdxCcelAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::TdxCcelAttestation'];

coerce 'TdxCcelAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::TdxCcelAttestation'->new($_) };

declare 'RepeatedTdxCcelAttestation',
    as ArrayRef[TdxCcelAttestation()];

coerce 'RepeatedTdxCcelAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::TdxCcelAttestation'->new($_) } @$_ ] };

declare 'MapStringTdxCcelAttestation',
    as HashRef[TdxCcelAttestation()];

declare 'SevSnpAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::SevSnpAttestation'];

coerce 'SevSnpAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::SevSnpAttestation'->new($_) };

declare 'RepeatedSevSnpAttestation',
    as ArrayRef[SevSnpAttestation()];

coerce 'RepeatedSevSnpAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::SevSnpAttestation'->new($_) } @$_ ] };

declare 'MapStringSevSnpAttestation',
    as HashRef[SevSnpAttestation()];

declare 'VerifyAttestationResponse',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyAttestationResponse'];

coerce 'VerifyAttestationResponse',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyAttestationResponse'->new($_) };

declare 'RepeatedVerifyAttestationResponse',
    as ArrayRef[VerifyAttestationResponse()];

coerce 'RepeatedVerifyAttestationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyAttestationResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyAttestationResponse',
    as HashRef[VerifyAttestationResponse()];

declare 'GcpCredentials',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::GcpCredentials'];

coerce 'GcpCredentials',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::GcpCredentials'->new($_) };

declare 'RepeatedGcpCredentials',
    as ArrayRef[GcpCredentials()];

coerce 'RepeatedGcpCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::GcpCredentials'->new($_) } @$_ ] };

declare 'MapStringGcpCredentials',
    as HashRef[GcpCredentials()];

declare 'TokenOptions',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::TokenOptions'];

coerce 'TokenOptions',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::TokenOptions'->new($_) };

declare 'RepeatedTokenOptions',
    as ArrayRef[TokenOptions()];

coerce 'RepeatedTokenOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::TokenOptions'->new($_) } @$_ ] };

declare 'MapStringTokenOptions',
    as HashRef[TokenOptions()];

declare 'AwsPrincipalTagsOptions',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions'];

coerce 'AwsPrincipalTagsOptions',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions'->new($_) };

declare 'RepeatedAwsPrincipalTagsOptions',
    as ArrayRef[AwsPrincipalTagsOptions()];

coerce 'RepeatedAwsPrincipalTagsOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions'->new($_) } @$_ ] };

declare 'MapStringAwsPrincipalTagsOptions',
    as HashRef[AwsPrincipalTagsOptions()];

declare 'AllowedPrincipalTags',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions::AllowedPrincipalTags'];

coerce 'AllowedPrincipalTags',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions::AllowedPrincipalTags'->new($_) };

declare 'RepeatedAllowedPrincipalTags',
    as ArrayRef[AllowedPrincipalTags()];

coerce 'RepeatedAllowedPrincipalTags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions::AllowedPrincipalTags'->new($_) } @$_ ] };

declare 'MapStringAllowedPrincipalTags',
    as HashRef[AllowedPrincipalTags()];

declare 'ContainerImageSignatures',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions::AllowedPrincipalTags::ContainerImageSignatures'];

coerce 'ContainerImageSignatures',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions::AllowedPrincipalTags::ContainerImageSignatures'->new($_) };

declare 'RepeatedContainerImageSignatures',
    as ArrayRef[ContainerImageSignatures()];

coerce 'RepeatedContainerImageSignatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::AwsPrincipalTagsOptions::AllowedPrincipalTags::ContainerImageSignatures'->new($_) } @$_ ] };

declare 'MapStringContainerImageSignatures',
    as HashRef[ContainerImageSignatures()];

declare 'TpmAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation'];

coerce 'TpmAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation'->new($_) };

declare 'RepeatedTpmAttestation',
    as ArrayRef[TpmAttestation()];

coerce 'RepeatedTpmAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation'->new($_) } @$_ ] };

declare 'MapStringTpmAttestation',
    as HashRef[TpmAttestation()];

declare 'Quote',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation::Quote'];

coerce 'Quote',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation::Quote'->new($_) };

declare 'RepeatedQuote',
    as ArrayRef[Quote()];

coerce 'RepeatedQuote',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation::Quote'->new($_) } @$_ ] };

declare 'MapStringQuote',
    as HashRef[Quote()];

declare 'PcrValuesEntry',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation::Quote::PcrValuesEntry'];

coerce 'PcrValuesEntry',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation::Quote::PcrValuesEntry'->new($_) };

declare 'RepeatedPcrValuesEntry',
    as ArrayRef[PcrValuesEntry()];

coerce 'RepeatedPcrValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::TpmAttestation::Quote::PcrValuesEntry'->new($_) } @$_ ] };

declare 'MapStringPcrValuesEntry',
    as HashRef[PcrValuesEntry()];

declare 'ConfidentialSpaceInfo',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::ConfidentialSpaceInfo'];

coerce 'ConfidentialSpaceInfo',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::ConfidentialSpaceInfo'->new($_) };

declare 'RepeatedConfidentialSpaceInfo',
    as ArrayRef[ConfidentialSpaceInfo()];

coerce 'RepeatedConfidentialSpaceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::ConfidentialSpaceInfo'->new($_) } @$_ ] };

declare 'MapStringConfidentialSpaceInfo',
    as HashRef[ConfidentialSpaceInfo()];

declare 'SignedEntity',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::SignedEntity'];

coerce 'SignedEntity',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::SignedEntity'->new($_) };

declare 'RepeatedSignedEntity',
    as ArrayRef[SignedEntity()];

coerce 'RepeatedSignedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::SignedEntity'->new($_) } @$_ ] };

declare 'MapStringSignedEntity',
    as HashRef[SignedEntity()];

declare 'ContainerImageSignature',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::ContainerImageSignature'];

coerce 'ContainerImageSignature',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::ContainerImageSignature'->new($_) };

declare 'RepeatedContainerImageSignature',
    as ArrayRef[ContainerImageSignature()];

coerce 'RepeatedContainerImageSignature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::ContainerImageSignature'->new($_) } @$_ ] };

declare 'MapStringContainerImageSignature',
    as HashRef[ContainerImageSignature()];

declare 'VerifyConfidentialSpaceRequest',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceRequest'];

coerce 'VerifyConfidentialSpaceRequest',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceRequest'->new($_) };

declare 'RepeatedVerifyConfidentialSpaceRequest',
    as ArrayRef[VerifyConfidentialSpaceRequest()];

coerce 'RepeatedVerifyConfidentialSpaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyConfidentialSpaceRequest',
    as HashRef[VerifyConfidentialSpaceRequest()];

declare 'ConfidentialSpaceOptions',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceRequest::ConfidentialSpaceOptions'];

coerce 'ConfidentialSpaceOptions',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceRequest::ConfidentialSpaceOptions'->new($_) };

declare 'RepeatedConfidentialSpaceOptions',
    as ArrayRef[ConfidentialSpaceOptions()];

coerce 'RepeatedConfidentialSpaceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceRequest::ConfidentialSpaceOptions'->new($_) } @$_ ] };

declare 'MapStringConfidentialSpaceOptions',
    as HashRef[ConfidentialSpaceOptions()];

declare 'GceShieldedIdentity',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::GceShieldedIdentity'];

coerce 'GceShieldedIdentity',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::GceShieldedIdentity'->new($_) };

declare 'RepeatedGceShieldedIdentity',
    as ArrayRef[GceShieldedIdentity()];

coerce 'RepeatedGceShieldedIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::GceShieldedIdentity'->new($_) } @$_ ] };

declare 'MapStringGceShieldedIdentity',
    as HashRef[GceShieldedIdentity()];

declare 'VerifyConfidentialSpaceResponse',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceResponse'];

coerce 'VerifyConfidentialSpaceResponse',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceResponse'->new($_) };

declare 'RepeatedVerifyConfidentialSpaceResponse',
    as ArrayRef[VerifyConfidentialSpaceResponse()];

coerce 'RepeatedVerifyConfidentialSpaceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialSpaceResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyConfidentialSpaceResponse',
    as HashRef[VerifyConfidentialSpaceResponse()];

declare 'VerifyConfidentialGkeRequest',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeRequest'];

coerce 'VerifyConfidentialGkeRequest',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeRequest'->new($_) };

declare 'RepeatedVerifyConfidentialGkeRequest',
    as ArrayRef[VerifyConfidentialGkeRequest()];

coerce 'RepeatedVerifyConfidentialGkeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyConfidentialGkeRequest',
    as HashRef[VerifyConfidentialGkeRequest()];

declare 'PlatformType',
    as (Int | Str);

declare 'ConfidentialGkeOptions',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeRequest::ConfidentialGkeOptions'];

coerce 'ConfidentialGkeOptions',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeRequest::ConfidentialGkeOptions'->new($_) };

declare 'RepeatedConfidentialGkeOptions',
    as ArrayRef[ConfidentialGkeOptions()];

coerce 'RepeatedConfidentialGkeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeRequest::ConfidentialGkeOptions'->new($_) } @$_ ] };

declare 'MapStringConfidentialGkeOptions',
    as HashRef[ConfidentialGkeOptions()];

declare 'VerifyConfidentialGkeResponse',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeResponse'];

coerce 'VerifyConfidentialGkeResponse',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeResponse'->new($_) };

declare 'RepeatedVerifyConfidentialGkeResponse',
    as ArrayRef[VerifyConfidentialGkeResponse()];

coerce 'RepeatedVerifyConfidentialGkeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1::Service::VerifyConfidentialGkeResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyConfidentialGkeResponse',
    as HashRef[VerifyConfidentialGkeResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Confidentialcomputing::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
