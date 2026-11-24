package Google::Cloud::Confidentialcomputing::V1alpha1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Challenge',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge'];

coerce 'Challenge',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge'->new($_) };

declare 'RepeatedChallenge',
    as ArrayRef[Challenge()];

coerce 'RepeatedChallenge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::Challenge'->new($_) } @$_ ] };

declare 'MapStringChallenge',
    as HashRef[Challenge()];

declare 'CreateChallengeRequest',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::CreateChallengeRequest'];

coerce 'CreateChallengeRequest',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::CreateChallengeRequest'->new($_) };

declare 'RepeatedCreateChallengeRequest',
    as ArrayRef[CreateChallengeRequest()];

coerce 'RepeatedCreateChallengeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::CreateChallengeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChallengeRequest',
    as HashRef[CreateChallengeRequest()];

declare 'VerifyAttestationRequest',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationRequest'];

coerce 'VerifyAttestationRequest',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationRequest'->new($_) };

declare 'RepeatedVerifyAttestationRequest',
    as ArrayRef[VerifyAttestationRequest()];

coerce 'RepeatedVerifyAttestationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyAttestationRequest',
    as HashRef[VerifyAttestationRequest()];

declare 'VerifyAttestationResponse',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationResponse'];

coerce 'VerifyAttestationResponse',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationResponse'->new($_) };

declare 'RepeatedVerifyAttestationResponse',
    as ArrayRef[VerifyAttestationResponse()];

coerce 'RepeatedVerifyAttestationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::VerifyAttestationResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyAttestationResponse',
    as HashRef[VerifyAttestationResponse()];

declare 'GcpCredentials',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::GcpCredentials'];

coerce 'GcpCredentials',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::GcpCredentials'->new($_) };

declare 'RepeatedGcpCredentials',
    as ArrayRef[GcpCredentials()];

coerce 'RepeatedGcpCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::GcpCredentials'->new($_) } @$_ ] };

declare 'MapStringGcpCredentials',
    as HashRef[GcpCredentials()];

declare 'TpmAttestation',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation'];

coerce 'TpmAttestation',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation'->new($_) };

declare 'RepeatedTpmAttestation',
    as ArrayRef[TpmAttestation()];

coerce 'RepeatedTpmAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation'->new($_) } @$_ ] };

declare 'MapStringTpmAttestation',
    as HashRef[TpmAttestation()];

declare 'Quote',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote'];

coerce 'Quote',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote'->new($_) };

declare 'RepeatedQuote',
    as ArrayRef[Quote()];

coerce 'RepeatedQuote',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote'->new($_) } @$_ ] };

declare 'MapStringQuote',
    as HashRef[Quote()];

declare 'PcrValuesEntry',
    as InstanceOf['Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote::PcrValuesEntry'];

coerce 'PcrValuesEntry',
    from HashRef, via { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote::PcrValuesEntry'->new($_) };

declare 'RepeatedPcrValuesEntry',
    as ArrayRef[PcrValuesEntry()];

coerce 'RepeatedPcrValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Confidentialcomputing::V1alpha1::Service::TpmAttestation::Quote::PcrValuesEntry'->new($_) } @$_ ] };

declare 'MapStringPcrValuesEntry',
    as HashRef[PcrValuesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Confidentialcomputing::V1alpha1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
