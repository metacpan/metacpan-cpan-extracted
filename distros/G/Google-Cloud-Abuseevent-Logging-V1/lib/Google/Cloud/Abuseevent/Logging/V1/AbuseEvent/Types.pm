package Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AbuseEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent'];

coerce 'AbuseEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent'->new($_) };

declare 'RepeatedAbuseEvent',
    as ArrayRef[AbuseEvent()];

coerce 'RepeatedAbuseEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::AbuseEvent'->new($_) } @$_ ] };

declare 'MapStringAbuseEvent',
    as HashRef[AbuseEvent()];

declare 'DetectionType',
    as (Int | Str);

declare 'ActionType',
    as (Int | Str);

declare 'CryptoMiningEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::CryptoMiningEvent'];

coerce 'CryptoMiningEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::CryptoMiningEvent'->new($_) };

declare 'RepeatedCryptoMiningEvent',
    as ArrayRef[CryptoMiningEvent()];

coerce 'RepeatedCryptoMiningEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::CryptoMiningEvent'->new($_) } @$_ ] };

declare 'MapStringCryptoMiningEvent',
    as HashRef[CryptoMiningEvent()];

declare 'LeakedCredentialEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::LeakedCredentialEvent'];

coerce 'LeakedCredentialEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::LeakedCredentialEvent'->new($_) };

declare 'RepeatedLeakedCredentialEvent',
    as ArrayRef[LeakedCredentialEvent()];

coerce 'RepeatedLeakedCredentialEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::LeakedCredentialEvent'->new($_) } @$_ ] };

declare 'MapStringLeakedCredentialEvent',
    as HashRef[LeakedCredentialEvent()];

declare 'IntrusionAttemptEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::IntrusionAttemptEvent'];

coerce 'IntrusionAttemptEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::IntrusionAttemptEvent'->new($_) };

declare 'RepeatedIntrusionAttemptEvent',
    as ArrayRef[IntrusionAttemptEvent()];

coerce 'RepeatedIntrusionAttemptEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::IntrusionAttemptEvent'->new($_) } @$_ ] };

declare 'MapStringIntrusionAttemptEvent',
    as HashRef[IntrusionAttemptEvent()];

declare 'ServiceAccountCredential',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ServiceAccountCredential'];

coerce 'ServiceAccountCredential',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ServiceAccountCredential'->new($_) };

declare 'RepeatedServiceAccountCredential',
    as ArrayRef[ServiceAccountCredential()];

coerce 'RepeatedServiceAccountCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ServiceAccountCredential'->new($_) } @$_ ] };

declare 'MapStringServiceAccountCredential',
    as HashRef[ServiceAccountCredential()];

declare 'ApiKeyCredential',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ApiKeyCredential'];

coerce 'ApiKeyCredential',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ApiKeyCredential'->new($_) };

declare 'RepeatedApiKeyCredential',
    as ArrayRef[ApiKeyCredential()];

coerce 'RepeatedApiKeyCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ApiKeyCredential'->new($_) } @$_ ] };

declare 'MapStringApiKeyCredential',
    as HashRef[ApiKeyCredential()];

declare 'HarmfulContentEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::HarmfulContentEvent'];

coerce 'HarmfulContentEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::HarmfulContentEvent'->new($_) };

declare 'RepeatedHarmfulContentEvent',
    as ArrayRef[HarmfulContentEvent()];

coerce 'RepeatedHarmfulContentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::HarmfulContentEvent'->new($_) } @$_ ] };

declare 'MapStringHarmfulContentEvent',
    as HashRef[HarmfulContentEvent()];

declare 'ReinstatementEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ReinstatementEvent'];

coerce 'ReinstatementEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ReinstatementEvent'->new($_) };

declare 'RepeatedReinstatementEvent',
    as ArrayRef[ReinstatementEvent()];

coerce 'RepeatedReinstatementEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::ReinstatementEvent'->new($_) } @$_ ] };

declare 'MapStringReinstatementEvent',
    as HashRef[ReinstatementEvent()];

declare 'DecisionEscalationEvent',
    as InstanceOf['Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DecisionEscalationEvent'];

coerce 'DecisionEscalationEvent',
    from HashRef, via { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DecisionEscalationEvent'->new($_) };

declare 'RepeatedDecisionEscalationEvent',
    as ArrayRef[DecisionEscalationEvent()];

coerce 'RepeatedDecisionEscalationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::DecisionEscalationEvent'->new($_) } @$_ ] };

declare 'MapStringDecisionEscalationEvent',
    as HashRef[DecisionEscalationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Abuseevent::Logging::V1::AbuseEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
