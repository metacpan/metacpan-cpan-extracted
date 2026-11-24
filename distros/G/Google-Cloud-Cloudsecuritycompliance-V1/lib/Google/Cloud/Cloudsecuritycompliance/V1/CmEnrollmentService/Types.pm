package Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpdateCmEnrollmentRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest'];

coerce 'UpdateCmEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest'->new($_) };

declare 'RepeatedUpdateCmEnrollmentRequest',
    as ArrayRef[UpdateCmEnrollmentRequest()];

coerce 'RepeatedUpdateCmEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::UpdateCmEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCmEnrollmentRequest',
    as HashRef[UpdateCmEnrollmentRequest()];

declare 'CalculateEffectiveCmEnrollmentRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest'];

coerce 'CalculateEffectiveCmEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest'->new($_) };

declare 'RepeatedCalculateEffectiveCmEnrollmentRequest',
    as ArrayRef[CalculateEffectiveCmEnrollmentRequest()];

coerce 'RepeatedCalculateEffectiveCmEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringCalculateEffectiveCmEnrollmentRequest',
    as HashRef[CalculateEffectiveCmEnrollmentRequest()];

declare 'CmEnrollment',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment'];

coerce 'CmEnrollment',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment'->new($_) };

declare 'RepeatedCmEnrollment',
    as ArrayRef[CmEnrollment()];

coerce 'RepeatedCmEnrollment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CmEnrollment'->new($_) } @$_ ] };

declare 'MapStringCmEnrollment',
    as HashRef[CmEnrollment()];

declare 'CalculateEffectiveCmEnrollmentResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse'];

coerce 'CalculateEffectiveCmEnrollmentResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse'->new($_) };

declare 'RepeatedCalculateEffectiveCmEnrollmentResponse',
    as ArrayRef[CalculateEffectiveCmEnrollmentResponse()];

coerce 'RepeatedCalculateEffectiveCmEnrollmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::CalculateEffectiveCmEnrollmentResponse'->new($_) } @$_ ] };

declare 'MapStringCalculateEffectiveCmEnrollmentResponse',
    as HashRef[CalculateEffectiveCmEnrollmentResponse()];

declare 'AuditConfig',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig'];

coerce 'AuditConfig',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig'->new($_) };

declare 'RepeatedAuditConfig',
    as ArrayRef[AuditConfig()];

coerce 'RepeatedAuditConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig'->new($_) } @$_ ] };

declare 'MapStringAuditConfig',
    as HashRef[AuditConfig()];

declare 'CmEligibleDestination',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig::CmEligibleDestination'];

coerce 'CmEligibleDestination',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig::CmEligibleDestination'->new($_) };

declare 'RepeatedCmEligibleDestination',
    as ArrayRef[CmEligibleDestination()];

coerce 'RepeatedCmEligibleDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::AuditConfig::CmEligibleDestination'->new($_) } @$_ ] };

declare 'MapStringCmEligibleDestination',
    as HashRef[CmEligibleDestination()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::CmEnrollmentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
