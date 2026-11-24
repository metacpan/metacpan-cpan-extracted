package Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChallengeType',
    as (Int | Str);

declare 'CreateAssessmentRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateAssessmentRequest'];

coerce 'CreateAssessmentRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateAssessmentRequest'->new($_) };

declare 'RepeatedCreateAssessmentRequest',
    as ArrayRef[CreateAssessmentRequest()];

coerce 'RepeatedCreateAssessmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateAssessmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssessmentRequest',
    as HashRef[CreateAssessmentRequest()];

declare 'TransactionEvent',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionEvent'];

coerce 'TransactionEvent',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionEvent'->new($_) };

declare 'RepeatedTransactionEvent',
    as ArrayRef[TransactionEvent()];

coerce 'RepeatedTransactionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionEvent'->new($_) } @$_ ] };

declare 'MapStringTransactionEvent',
    as HashRef[TransactionEvent()];

declare 'TransactionEventType',
    as (Int | Str);

declare 'PhoneAuthenticationEvent',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PhoneAuthenticationEvent'];

coerce 'PhoneAuthenticationEvent',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PhoneAuthenticationEvent'->new($_) };

declare 'RepeatedPhoneAuthenticationEvent',
    as ArrayRef[PhoneAuthenticationEvent()];

coerce 'RepeatedPhoneAuthenticationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PhoneAuthenticationEvent'->new($_) } @$_ ] };

declare 'MapStringPhoneAuthenticationEvent',
    as HashRef[PhoneAuthenticationEvent()];

declare 'AnnotateAssessmentRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AnnotateAssessmentRequest'];

coerce 'AnnotateAssessmentRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AnnotateAssessmentRequest'->new($_) };

declare 'RepeatedAnnotateAssessmentRequest',
    as ArrayRef[AnnotateAssessmentRequest()];

coerce 'RepeatedAnnotateAssessmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AnnotateAssessmentRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateAssessmentRequest',
    as HashRef[AnnotateAssessmentRequest()];

declare 'Annotation',
    as (Int | Str);

declare 'Reason',
    as (Int | Str);

declare 'AnnotateAssessmentResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AnnotateAssessmentResponse'];

coerce 'AnnotateAssessmentResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AnnotateAssessmentResponse'->new($_) };

declare 'RepeatedAnnotateAssessmentResponse',
    as ArrayRef[AnnotateAssessmentResponse()];

coerce 'RepeatedAnnotateAssessmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AnnotateAssessmentResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateAssessmentResponse',
    as HashRef[AnnotateAssessmentResponse()];

declare 'EndpointVerificationInfo',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::EndpointVerificationInfo'];

coerce 'EndpointVerificationInfo',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::EndpointVerificationInfo'->new($_) };

declare 'RepeatedEndpointVerificationInfo',
    as ArrayRef[EndpointVerificationInfo()];

coerce 'RepeatedEndpointVerificationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::EndpointVerificationInfo'->new($_) } @$_ ] };

declare 'MapStringEndpointVerificationInfo',
    as HashRef[EndpointVerificationInfo()];

declare 'AccountVerificationInfo',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountVerificationInfo'];

coerce 'AccountVerificationInfo',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountVerificationInfo'->new($_) };

declare 'RepeatedAccountVerificationInfo',
    as ArrayRef[AccountVerificationInfo()];

coerce 'RepeatedAccountVerificationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountVerificationInfo'->new($_) } @$_ ] };

declare 'MapStringAccountVerificationInfo',
    as HashRef[AccountVerificationInfo()];

declare 'Result',
    as (Int | Str);

declare 'PrivatePasswordLeakVerification',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PrivatePasswordLeakVerification'];

coerce 'PrivatePasswordLeakVerification',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PrivatePasswordLeakVerification'->new($_) };

declare 'RepeatedPrivatePasswordLeakVerification',
    as ArrayRef[PrivatePasswordLeakVerification()];

coerce 'RepeatedPrivatePasswordLeakVerification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PrivatePasswordLeakVerification'->new($_) } @$_ ] };

declare 'MapStringPrivatePasswordLeakVerification',
    as HashRef[PrivatePasswordLeakVerification()];

declare 'Assessment',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Assessment'];

coerce 'Assessment',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Assessment'->new($_) };

declare 'RepeatedAssessment',
    as ArrayRef[Assessment()];

coerce 'RepeatedAssessment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Assessment'->new($_) } @$_ ] };

declare 'MapStringAssessment',
    as HashRef[Assessment()];

declare 'Event',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'FraudPrevention',
    as (Int | Str);

declare 'TransactionData',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData'];

coerce 'TransactionData',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData'->new($_) };

declare 'RepeatedTransactionData',
    as ArrayRef[TransactionData()];

coerce 'RepeatedTransactionData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData'->new($_) } @$_ ] };

declare 'MapStringTransactionData',
    as HashRef[TransactionData()];

declare 'Address',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::Address'];

coerce 'Address',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::Address'->new($_) };

declare 'RepeatedAddress',
    as ArrayRef[Address()];

coerce 'RepeatedAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::Address'->new($_) } @$_ ] };

declare 'MapStringAddress',
    as HashRef[Address()];

declare 'User',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::User'];

coerce 'User',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'Item',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::Item'];

coerce 'Item',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::Item'->new($_) };

declare 'RepeatedItem',
    as ArrayRef[Item()];

coerce 'RepeatedItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::Item'->new($_) } @$_ ] };

declare 'MapStringItem',
    as HashRef[Item()];

declare 'GatewayInfo',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::GatewayInfo'];

coerce 'GatewayInfo',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::GatewayInfo'->new($_) };

declare 'RepeatedGatewayInfo',
    as ArrayRef[GatewayInfo()];

coerce 'RepeatedGatewayInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TransactionData::GatewayInfo'->new($_) } @$_ ] };

declare 'MapStringGatewayInfo',
    as HashRef[GatewayInfo()];

declare 'UserInfo',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UserInfo'];

coerce 'UserInfo',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UserInfo'->new($_) };

declare 'RepeatedUserInfo',
    as ArrayRef[UserInfo()];

coerce 'RepeatedUserInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UserInfo'->new($_) } @$_ ] };

declare 'MapStringUserInfo',
    as HashRef[UserInfo()];

declare 'UserId',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UserId'];

coerce 'UserId',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UserId'->new($_) };

declare 'RepeatedUserId',
    as ArrayRef[UserId()];

coerce 'RepeatedUserId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UserId'->new($_) } @$_ ] };

declare 'MapStringUserId',
    as HashRef[UserId()];

declare 'RiskAnalysis',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RiskAnalysis'];

coerce 'RiskAnalysis',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RiskAnalysis'->new($_) };

declare 'RepeatedRiskAnalysis',
    as ArrayRef[RiskAnalysis()];

coerce 'RepeatedRiskAnalysis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RiskAnalysis'->new($_) } @$_ ] };

declare 'MapStringRiskAnalysis',
    as HashRef[RiskAnalysis()];

declare 'ClassificationReason',
    as (Int | Str);

declare 'Challenge',
    as (Int | Str);

declare 'Bot',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Bot'];

coerce 'Bot',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Bot'->new($_) };

declare 'RepeatedBot',
    as ArrayRef[Bot()];

coerce 'RepeatedBot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Bot'->new($_) } @$_ ] };

declare 'MapStringBot',
    as HashRef[Bot()];

declare 'BotType',
    as (Int | Str);

declare 'TokenProperties',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TokenProperties'];

coerce 'TokenProperties',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TokenProperties'->new($_) };

declare 'RepeatedTokenProperties',
    as ArrayRef[TokenProperties()];

coerce 'RepeatedTokenProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TokenProperties'->new($_) } @$_ ] };

declare 'MapStringTokenProperties',
    as HashRef[TokenProperties()];

declare 'InvalidReason',
    as (Int | Str);

declare 'FraudPreventionAssessment',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment'];

coerce 'FraudPreventionAssessment',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment'->new($_) };

declare 'RepeatedFraudPreventionAssessment',
    as ArrayRef[FraudPreventionAssessment()];

coerce 'RepeatedFraudPreventionAssessment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment'->new($_) } @$_ ] };

declare 'MapStringFraudPreventionAssessment',
    as HashRef[FraudPreventionAssessment()];

declare 'RiskReason',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::RiskReason'];

coerce 'RiskReason',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::RiskReason'->new($_) };

declare 'RepeatedRiskReason',
    as ArrayRef[RiskReason()];

coerce 'RepeatedRiskReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::RiskReason'->new($_) } @$_ ] };

declare 'MapStringRiskReason',
    as HashRef[RiskReason()];

declare 'Reason',
    as (Int | Str);

declare 'StolenInstrumentVerdict',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::StolenInstrumentVerdict'];

coerce 'StolenInstrumentVerdict',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::StolenInstrumentVerdict'->new($_) };

declare 'RepeatedStolenInstrumentVerdict',
    as ArrayRef[StolenInstrumentVerdict()];

coerce 'RepeatedStolenInstrumentVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::StolenInstrumentVerdict'->new($_) } @$_ ] };

declare 'MapStringStolenInstrumentVerdict',
    as HashRef[StolenInstrumentVerdict()];

declare 'CardTestingVerdict',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::CardTestingVerdict'];

coerce 'CardTestingVerdict',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::CardTestingVerdict'->new($_) };

declare 'RepeatedCardTestingVerdict',
    as ArrayRef[CardTestingVerdict()];

coerce 'RepeatedCardTestingVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::CardTestingVerdict'->new($_) } @$_ ] };

declare 'MapStringCardTestingVerdict',
    as HashRef[CardTestingVerdict()];

declare 'BehavioralTrustVerdict',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::BehavioralTrustVerdict'];

coerce 'BehavioralTrustVerdict',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::BehavioralTrustVerdict'->new($_) };

declare 'RepeatedBehavioralTrustVerdict',
    as ArrayRef[BehavioralTrustVerdict()];

coerce 'RepeatedBehavioralTrustVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudPreventionAssessment::BehavioralTrustVerdict'->new($_) } @$_ ] };

declare 'MapStringBehavioralTrustVerdict',
    as HashRef[BehavioralTrustVerdict()];

declare 'FraudSignals',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals'];

coerce 'FraudSignals',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals'->new($_) };

declare 'RepeatedFraudSignals',
    as ArrayRef[FraudSignals()];

coerce 'RepeatedFraudSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals'->new($_) } @$_ ] };

declare 'MapStringFraudSignals',
    as HashRef[FraudSignals()];

declare 'UserSignals',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals::UserSignals'];

coerce 'UserSignals',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals::UserSignals'->new($_) };

declare 'RepeatedUserSignals',
    as ArrayRef[UserSignals()];

coerce 'RepeatedUserSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals::UserSignals'->new($_) } @$_ ] };

declare 'MapStringUserSignals',
    as HashRef[UserSignals()];

declare 'CardSignals',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals::CardSignals'];

coerce 'CardSignals',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals::CardSignals'->new($_) };

declare 'RepeatedCardSignals',
    as ArrayRef[CardSignals()];

coerce 'RepeatedCardSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FraudSignals::CardSignals'->new($_) } @$_ ] };

declare 'MapStringCardSignals',
    as HashRef[CardSignals()];

declare 'CardLabel',
    as (Int | Str);

declare 'SmsTollFraudVerdict',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SmsTollFraudVerdict'];

coerce 'SmsTollFraudVerdict',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SmsTollFraudVerdict'->new($_) };

declare 'RepeatedSmsTollFraudVerdict',
    as ArrayRef[SmsTollFraudVerdict()];

coerce 'RepeatedSmsTollFraudVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SmsTollFraudVerdict'->new($_) } @$_ ] };

declare 'MapStringSmsTollFraudVerdict',
    as HashRef[SmsTollFraudVerdict()];

declare 'SmsTollFraudReason',
    as (Int | Str);

declare 'PhoneFraudAssessment',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PhoneFraudAssessment'];

coerce 'PhoneFraudAssessment',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PhoneFraudAssessment'->new($_) };

declare 'RepeatedPhoneFraudAssessment',
    as ArrayRef[PhoneFraudAssessment()];

coerce 'RepeatedPhoneFraudAssessment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PhoneFraudAssessment'->new($_) } @$_ ] };

declare 'MapStringPhoneFraudAssessment',
    as HashRef[PhoneFraudAssessment()];

declare 'AccountDefenderAssessment',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment'];

coerce 'AccountDefenderAssessment',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment'->new($_) };

declare 'RepeatedAccountDefenderAssessment',
    as ArrayRef[AccountDefenderAssessment()];

coerce 'RepeatedAccountDefenderAssessment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment'->new($_) } @$_ ] };

declare 'MapStringAccountDefenderAssessment',
    as HashRef[AccountDefenderAssessment()];

declare 'AccountDefenderLabel',
    as (Int | Str);

declare 'AccountTakeoverVerdict',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountTakeoverVerdict'];

coerce 'AccountTakeoverVerdict',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountTakeoverVerdict'->new($_) };

declare 'RepeatedAccountTakeoverVerdict',
    as ArrayRef[AccountTakeoverVerdict()];

coerce 'RepeatedAccountTakeoverVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountTakeoverVerdict'->new($_) } @$_ ] };

declare 'MapStringAccountTakeoverVerdict',
    as HashRef[AccountTakeoverVerdict()];

declare 'AccountRiskReason',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountRiskReason'];

coerce 'AccountRiskReason',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountRiskReason'->new($_) };

declare 'RepeatedAccountRiskReason',
    as ArrayRef[AccountRiskReason()];

coerce 'RepeatedAccountRiskReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountRiskReason'->new($_) } @$_ ] };

declare 'MapStringAccountRiskReason',
    as HashRef[AccountRiskReason()];

declare 'RiskReason',
    as (Int | Str);

declare 'AccountTrustReason',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountTrustReason'];

coerce 'AccountTrustReason',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountTrustReason'->new($_) };

declare 'RepeatedAccountTrustReason',
    as ArrayRef[AccountTrustReason()];

coerce 'RepeatedAccountTrustReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AccountDefenderAssessment::AccountTrustReason'->new($_) } @$_ ] };

declare 'MapStringAccountTrustReason',
    as HashRef[AccountTrustReason()];

declare 'TrustReason',
    as (Int | Str);

declare 'CreateKeyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateKeyRequest'];

coerce 'CreateKeyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateKeyRequest'->new($_) };

declare 'RepeatedCreateKeyRequest',
    as ArrayRef[CreateKeyRequest()];

coerce 'RepeatedCreateKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateKeyRequest',
    as HashRef[CreateKeyRequest()];

declare 'ListKeysRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListKeysRequest'];

coerce 'ListKeysRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListKeysRequest'->new($_) };

declare 'RepeatedListKeysRequest',
    as ArrayRef[ListKeysRequest()];

coerce 'RepeatedListKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListKeysRequest',
    as HashRef[ListKeysRequest()];

declare 'ListKeysResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListKeysResponse'];

coerce 'ListKeysResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListKeysResponse'->new($_) };

declare 'RepeatedListKeysResponse',
    as ArrayRef[ListKeysResponse()];

coerce 'RepeatedListKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListKeysResponse',
    as HashRef[ListKeysResponse()];

declare 'RetrieveLegacySecretKeyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RetrieveLegacySecretKeyRequest'];

coerce 'RetrieveLegacySecretKeyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RetrieveLegacySecretKeyRequest'->new($_) };

declare 'RepeatedRetrieveLegacySecretKeyRequest',
    as ArrayRef[RetrieveLegacySecretKeyRequest()];

coerce 'RepeatedRetrieveLegacySecretKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RetrieveLegacySecretKeyRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveLegacySecretKeyRequest',
    as HashRef[RetrieveLegacySecretKeyRequest()];

declare 'GetKeyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetKeyRequest'];

coerce 'GetKeyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetKeyRequest'->new($_) };

declare 'RepeatedGetKeyRequest',
    as ArrayRef[GetKeyRequest()];

coerce 'RepeatedGetKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetKeyRequest',
    as HashRef[GetKeyRequest()];

declare 'UpdateKeyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdateKeyRequest'];

coerce 'UpdateKeyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdateKeyRequest'->new($_) };

declare 'RepeatedUpdateKeyRequest',
    as ArrayRef[UpdateKeyRequest()];

coerce 'RepeatedUpdateKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdateKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateKeyRequest',
    as HashRef[UpdateKeyRequest()];

declare 'DeleteKeyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::DeleteKeyRequest'];

coerce 'DeleteKeyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::DeleteKeyRequest'->new($_) };

declare 'RepeatedDeleteKeyRequest',
    as ArrayRef[DeleteKeyRequest()];

coerce 'RepeatedDeleteKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::DeleteKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteKeyRequest',
    as HashRef[DeleteKeyRequest()];

declare 'CreateFirewallPolicyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateFirewallPolicyRequest'];

coerce 'CreateFirewallPolicyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateFirewallPolicyRequest'->new($_) };

declare 'RepeatedCreateFirewallPolicyRequest',
    as ArrayRef[CreateFirewallPolicyRequest()];

coerce 'RepeatedCreateFirewallPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::CreateFirewallPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFirewallPolicyRequest',
    as HashRef[CreateFirewallPolicyRequest()];

declare 'ListFirewallPoliciesRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListFirewallPoliciesRequest'];

coerce 'ListFirewallPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListFirewallPoliciesRequest'->new($_) };

declare 'RepeatedListFirewallPoliciesRequest',
    as ArrayRef[ListFirewallPoliciesRequest()];

coerce 'RepeatedListFirewallPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListFirewallPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListFirewallPoliciesRequest',
    as HashRef[ListFirewallPoliciesRequest()];

declare 'ListFirewallPoliciesResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListFirewallPoliciesResponse'];

coerce 'ListFirewallPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListFirewallPoliciesResponse'->new($_) };

declare 'RepeatedListFirewallPoliciesResponse',
    as ArrayRef[ListFirewallPoliciesResponse()];

coerce 'RepeatedListFirewallPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListFirewallPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListFirewallPoliciesResponse',
    as HashRef[ListFirewallPoliciesResponse()];

declare 'GetFirewallPolicyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetFirewallPolicyRequest'];

coerce 'GetFirewallPolicyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetFirewallPolicyRequest'->new($_) };

declare 'RepeatedGetFirewallPolicyRequest',
    as ArrayRef[GetFirewallPolicyRequest()];

coerce 'RepeatedGetFirewallPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetFirewallPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetFirewallPolicyRequest',
    as HashRef[GetFirewallPolicyRequest()];

declare 'UpdateFirewallPolicyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdateFirewallPolicyRequest'];

coerce 'UpdateFirewallPolicyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdateFirewallPolicyRequest'->new($_) };

declare 'RepeatedUpdateFirewallPolicyRequest',
    as ArrayRef[UpdateFirewallPolicyRequest()];

coerce 'RepeatedUpdateFirewallPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdateFirewallPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFirewallPolicyRequest',
    as HashRef[UpdateFirewallPolicyRequest()];

declare 'DeleteFirewallPolicyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::DeleteFirewallPolicyRequest'];

coerce 'DeleteFirewallPolicyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::DeleteFirewallPolicyRequest'->new($_) };

declare 'RepeatedDeleteFirewallPolicyRequest',
    as ArrayRef[DeleteFirewallPolicyRequest()];

coerce 'RepeatedDeleteFirewallPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::DeleteFirewallPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFirewallPolicyRequest',
    as HashRef[DeleteFirewallPolicyRequest()];

declare 'ReorderFirewallPoliciesRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ReorderFirewallPoliciesRequest'];

coerce 'ReorderFirewallPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ReorderFirewallPoliciesRequest'->new($_) };

declare 'RepeatedReorderFirewallPoliciesRequest',
    as ArrayRef[ReorderFirewallPoliciesRequest()];

coerce 'RepeatedReorderFirewallPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ReorderFirewallPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringReorderFirewallPoliciesRequest',
    as HashRef[ReorderFirewallPoliciesRequest()];

declare 'ReorderFirewallPoliciesResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ReorderFirewallPoliciesResponse'];

coerce 'ReorderFirewallPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ReorderFirewallPoliciesResponse'->new($_) };

declare 'RepeatedReorderFirewallPoliciesResponse',
    as ArrayRef[ReorderFirewallPoliciesResponse()];

coerce 'RepeatedReorderFirewallPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ReorderFirewallPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringReorderFirewallPoliciesResponse',
    as HashRef[ReorderFirewallPoliciesResponse()];

declare 'MigrateKeyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::MigrateKeyRequest'];

coerce 'MigrateKeyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::MigrateKeyRequest'->new($_) };

declare 'RepeatedMigrateKeyRequest',
    as ArrayRef[MigrateKeyRequest()];

coerce 'RepeatedMigrateKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::MigrateKeyRequest'->new($_) } @$_ ] };

declare 'MapStringMigrateKeyRequest',
    as HashRef[MigrateKeyRequest()];

declare 'GetMetricsRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetMetricsRequest'];

coerce 'GetMetricsRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetMetricsRequest'->new($_) };

declare 'RepeatedGetMetricsRequest',
    as ArrayRef[GetMetricsRequest()];

coerce 'RepeatedGetMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringGetMetricsRequest',
    as HashRef[GetMetricsRequest()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'RetrieveLegacySecretKeyResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RetrieveLegacySecretKeyResponse'];

coerce 'RetrieveLegacySecretKeyResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RetrieveLegacySecretKeyResponse'->new($_) };

declare 'RepeatedRetrieveLegacySecretKeyResponse',
    as ArrayRef[RetrieveLegacySecretKeyResponse()];

coerce 'RepeatedRetrieveLegacySecretKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RetrieveLegacySecretKeyResponse'->new($_) } @$_ ] };

declare 'MapStringRetrieveLegacySecretKeyResponse',
    as HashRef[RetrieveLegacySecretKeyResponse()];

declare 'Key',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Key'];

coerce 'Key',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Key'->new($_) };

declare 'RepeatedKey',
    as ArrayRef[Key()];

coerce 'RepeatedKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Key'->new($_) } @$_ ] };

declare 'MapStringKey',
    as HashRef[Key()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Key::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Key::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Key::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TestingOptions',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TestingOptions'];

coerce 'TestingOptions',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TestingOptions'->new($_) };

declare 'RepeatedTestingOptions',
    as ArrayRef[TestingOptions()];

coerce 'RepeatedTestingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::TestingOptions'->new($_) } @$_ ] };

declare 'MapStringTestingOptions',
    as HashRef[TestingOptions()];

declare 'TestingChallenge',
    as (Int | Str);

declare 'WebKeySettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings'];

coerce 'WebKeySettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings'->new($_) };

declare 'RepeatedWebKeySettings',
    as ArrayRef[WebKeySettings()];

coerce 'RepeatedWebKeySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings'->new($_) } @$_ ] };

declare 'MapStringWebKeySettings',
    as HashRef[WebKeySettings()];

declare 'IntegrationType',
    as (Int | Str);

declare 'ChallengeSecurityPreference',
    as (Int | Str);

declare 'ActionSettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ActionSettings'];

coerce 'ActionSettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ActionSettings'->new($_) };

declare 'RepeatedActionSettings',
    as ArrayRef[ActionSettings()];

coerce 'RepeatedActionSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ActionSettings'->new($_) } @$_ ] };

declare 'MapStringActionSettings',
    as HashRef[ActionSettings()];

declare 'ChallengeSettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ChallengeSettings'];

coerce 'ChallengeSettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ChallengeSettings'->new($_) };

declare 'RepeatedChallengeSettings',
    as ArrayRef[ChallengeSettings()];

coerce 'RepeatedChallengeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ChallengeSettings'->new($_) } @$_ ] };

declare 'MapStringChallengeSettings',
    as HashRef[ChallengeSettings()];

declare 'ActionSettingsEntry',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ChallengeSettings::ActionSettingsEntry'];

coerce 'ActionSettingsEntry',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ChallengeSettings::ActionSettingsEntry'->new($_) };

declare 'RepeatedActionSettingsEntry',
    as ArrayRef[ActionSettingsEntry()];

coerce 'RepeatedActionSettingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WebKeySettings::ChallengeSettings::ActionSettingsEntry'->new($_) } @$_ ] };

declare 'MapStringActionSettingsEntry',
    as HashRef[ActionSettingsEntry()];

declare 'AndroidKeySettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AndroidKeySettings'];

coerce 'AndroidKeySettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AndroidKeySettings'->new($_) };

declare 'RepeatedAndroidKeySettings',
    as ArrayRef[AndroidKeySettings()];

coerce 'RepeatedAndroidKeySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AndroidKeySettings'->new($_) } @$_ ] };

declare 'MapStringAndroidKeySettings',
    as HashRef[AndroidKeySettings()];

declare 'IOSKeySettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::IOSKeySettings'];

coerce 'IOSKeySettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::IOSKeySettings'->new($_) };

declare 'RepeatedIOSKeySettings',
    as ArrayRef[IOSKeySettings()];

coerce 'RepeatedIOSKeySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::IOSKeySettings'->new($_) } @$_ ] };

declare 'MapStringIOSKeySettings',
    as HashRef[IOSKeySettings()];

declare 'ExpressKeySettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ExpressKeySettings'];

coerce 'ExpressKeySettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ExpressKeySettings'->new($_) };

declare 'RepeatedExpressKeySettings',
    as ArrayRef[ExpressKeySettings()];

coerce 'RepeatedExpressKeySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ExpressKeySettings'->new($_) } @$_ ] };

declare 'MapStringExpressKeySettings',
    as HashRef[ExpressKeySettings()];

declare 'UniversalKeySettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UniversalKeySettings'];

coerce 'UniversalKeySettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UniversalKeySettings'->new($_) };

declare 'RepeatedUniversalKeySettings',
    as ArrayRef[UniversalKeySettings()];

coerce 'RepeatedUniversalKeySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UniversalKeySettings'->new($_) } @$_ ] };

declare 'MapStringUniversalKeySettings',
    as HashRef[UniversalKeySettings()];

declare 'AppleDeveloperId',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AppleDeveloperId'];

coerce 'AppleDeveloperId',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AppleDeveloperId'->new($_) };

declare 'RepeatedAppleDeveloperId',
    as ArrayRef[AppleDeveloperId()];

coerce 'RepeatedAppleDeveloperId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AppleDeveloperId'->new($_) } @$_ ] };

declare 'MapStringAppleDeveloperId',
    as HashRef[AppleDeveloperId()];

declare 'ScoreDistribution',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreDistribution'];

coerce 'ScoreDistribution',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreDistribution'->new($_) };

declare 'RepeatedScoreDistribution',
    as ArrayRef[ScoreDistribution()];

coerce 'RepeatedScoreDistribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreDistribution'->new($_) } @$_ ] };

declare 'MapStringScoreDistribution',
    as HashRef[ScoreDistribution()];

declare 'ScoreBucketsEntry',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreDistribution::ScoreBucketsEntry'];

coerce 'ScoreBucketsEntry',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreDistribution::ScoreBucketsEntry'->new($_) };

declare 'RepeatedScoreBucketsEntry',
    as ArrayRef[ScoreBucketsEntry()];

coerce 'RepeatedScoreBucketsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreDistribution::ScoreBucketsEntry'->new($_) } @$_ ] };

declare 'MapStringScoreBucketsEntry',
    as HashRef[ScoreBucketsEntry()];

declare 'ScoreMetrics',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreMetrics'];

coerce 'ScoreMetrics',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreMetrics'->new($_) };

declare 'RepeatedScoreMetrics',
    as ArrayRef[ScoreMetrics()];

coerce 'RepeatedScoreMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreMetrics'->new($_) } @$_ ] };

declare 'MapStringScoreMetrics',
    as HashRef[ScoreMetrics()];

declare 'ActionMetricsEntry',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreMetrics::ActionMetricsEntry'];

coerce 'ActionMetricsEntry',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreMetrics::ActionMetricsEntry'->new($_) };

declare 'RepeatedActionMetricsEntry',
    as ArrayRef[ActionMetricsEntry()];

coerce 'RepeatedActionMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ScoreMetrics::ActionMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringActionMetricsEntry',
    as HashRef[ActionMetricsEntry()];

declare 'ChallengeMetrics',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeMetrics'];

coerce 'ChallengeMetrics',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeMetrics'->new($_) };

declare 'RepeatedChallengeMetrics',
    as ArrayRef[ChallengeMetrics()];

coerce 'RepeatedChallengeMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeMetrics'->new($_) } @$_ ] };

declare 'MapStringChallengeMetrics',
    as HashRef[ChallengeMetrics()];

declare 'FirewallPolicyAssessment',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallPolicyAssessment'];

coerce 'FirewallPolicyAssessment',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallPolicyAssessment'->new($_) };

declare 'RepeatedFirewallPolicyAssessment',
    as ArrayRef[FirewallPolicyAssessment()];

coerce 'RepeatedFirewallPolicyAssessment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallPolicyAssessment'->new($_) } @$_ ] };

declare 'MapStringFirewallPolicyAssessment',
    as HashRef[FirewallPolicyAssessment()];

declare 'FirewallAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction'];

coerce 'FirewallAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction'->new($_) };

declare 'RepeatedFirewallAction',
    as ArrayRef[FirewallAction()];

coerce 'RepeatedFirewallAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction'->new($_) } @$_ ] };

declare 'MapStringFirewallAction',
    as HashRef[FirewallAction()];

declare 'AllowAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::AllowAction'];

coerce 'AllowAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::AllowAction'->new($_) };

declare 'RepeatedAllowAction',
    as ArrayRef[AllowAction()];

coerce 'RepeatedAllowAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::AllowAction'->new($_) } @$_ ] };

declare 'MapStringAllowAction',
    as HashRef[AllowAction()];

declare 'BlockAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::BlockAction'];

coerce 'BlockAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::BlockAction'->new($_) };

declare 'RepeatedBlockAction',
    as ArrayRef[BlockAction()];

coerce 'RepeatedBlockAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::BlockAction'->new($_) } @$_ ] };

declare 'MapStringBlockAction',
    as HashRef[BlockAction()];

declare 'IncludeRecaptchaScriptAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::IncludeRecaptchaScriptAction'];

coerce 'IncludeRecaptchaScriptAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::IncludeRecaptchaScriptAction'->new($_) };

declare 'RepeatedIncludeRecaptchaScriptAction',
    as ArrayRef[IncludeRecaptchaScriptAction()];

coerce 'RepeatedIncludeRecaptchaScriptAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::IncludeRecaptchaScriptAction'->new($_) } @$_ ] };

declare 'MapStringIncludeRecaptchaScriptAction',
    as HashRef[IncludeRecaptchaScriptAction()];

declare 'RedirectAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::RedirectAction'];

coerce 'RedirectAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::RedirectAction'->new($_) };

declare 'RepeatedRedirectAction',
    as ArrayRef[RedirectAction()];

coerce 'RepeatedRedirectAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::RedirectAction'->new($_) } @$_ ] };

declare 'MapStringRedirectAction',
    as HashRef[RedirectAction()];

declare 'SubstituteAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::SubstituteAction'];

coerce 'SubstituteAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::SubstituteAction'->new($_) };

declare 'RepeatedSubstituteAction',
    as ArrayRef[SubstituteAction()];

coerce 'RepeatedSubstituteAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::SubstituteAction'->new($_) } @$_ ] };

declare 'MapStringSubstituteAction',
    as HashRef[SubstituteAction()];

declare 'SetHeaderAction',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::SetHeaderAction'];

coerce 'SetHeaderAction',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::SetHeaderAction'->new($_) };

declare 'RepeatedSetHeaderAction',
    as ArrayRef[SetHeaderAction()];

coerce 'RepeatedSetHeaderAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallAction::SetHeaderAction'->new($_) } @$_ ] };

declare 'MapStringSetHeaderAction',
    as HashRef[SetHeaderAction()];

declare 'FirewallPolicy',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallPolicy'];

coerce 'FirewallPolicy',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallPolicy'->new($_) };

declare 'RepeatedFirewallPolicy',
    as ArrayRef[FirewallPolicy()];

coerce 'RepeatedFirewallPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::FirewallPolicy'->new($_) } @$_ ] };

declare 'MapStringFirewallPolicy',
    as HashRef[FirewallPolicy()];

declare 'ListRelatedAccountGroupMembershipsRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupMembershipsRequest'];

coerce 'ListRelatedAccountGroupMembershipsRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupMembershipsRequest'->new($_) };

declare 'RepeatedListRelatedAccountGroupMembershipsRequest',
    as ArrayRef[ListRelatedAccountGroupMembershipsRequest()];

coerce 'RepeatedListRelatedAccountGroupMembershipsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupMembershipsRequest'->new($_) } @$_ ] };

declare 'MapStringListRelatedAccountGroupMembershipsRequest',
    as HashRef[ListRelatedAccountGroupMembershipsRequest()];

declare 'ListRelatedAccountGroupMembershipsResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupMembershipsResponse'];

coerce 'ListRelatedAccountGroupMembershipsResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupMembershipsResponse'->new($_) };

declare 'RepeatedListRelatedAccountGroupMembershipsResponse',
    as ArrayRef[ListRelatedAccountGroupMembershipsResponse()];

coerce 'RepeatedListRelatedAccountGroupMembershipsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupMembershipsResponse'->new($_) } @$_ ] };

declare 'MapStringListRelatedAccountGroupMembershipsResponse',
    as HashRef[ListRelatedAccountGroupMembershipsResponse()];

declare 'ListRelatedAccountGroupsRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupsRequest'];

coerce 'ListRelatedAccountGroupsRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupsRequest'->new($_) };

declare 'RepeatedListRelatedAccountGroupsRequest',
    as ArrayRef[ListRelatedAccountGroupsRequest()];

coerce 'RepeatedListRelatedAccountGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListRelatedAccountGroupsRequest',
    as HashRef[ListRelatedAccountGroupsRequest()];

declare 'ListRelatedAccountGroupsResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupsResponse'];

coerce 'ListRelatedAccountGroupsResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupsResponse'->new($_) };

declare 'RepeatedListRelatedAccountGroupsResponse',
    as ArrayRef[ListRelatedAccountGroupsResponse()];

coerce 'RepeatedListRelatedAccountGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListRelatedAccountGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListRelatedAccountGroupsResponse',
    as HashRef[ListRelatedAccountGroupsResponse()];

declare 'SearchRelatedAccountGroupMembershipsRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SearchRelatedAccountGroupMembershipsRequest'];

coerce 'SearchRelatedAccountGroupMembershipsRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SearchRelatedAccountGroupMembershipsRequest'->new($_) };

declare 'RepeatedSearchRelatedAccountGroupMembershipsRequest',
    as ArrayRef[SearchRelatedAccountGroupMembershipsRequest()];

coerce 'RepeatedSearchRelatedAccountGroupMembershipsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SearchRelatedAccountGroupMembershipsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchRelatedAccountGroupMembershipsRequest',
    as HashRef[SearchRelatedAccountGroupMembershipsRequest()];

declare 'SearchRelatedAccountGroupMembershipsResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SearchRelatedAccountGroupMembershipsResponse'];

coerce 'SearchRelatedAccountGroupMembershipsResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SearchRelatedAccountGroupMembershipsResponse'->new($_) };

declare 'RepeatedSearchRelatedAccountGroupMembershipsResponse',
    as ArrayRef[SearchRelatedAccountGroupMembershipsResponse()];

coerce 'RepeatedSearchRelatedAccountGroupMembershipsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::SearchRelatedAccountGroupMembershipsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchRelatedAccountGroupMembershipsResponse',
    as HashRef[SearchRelatedAccountGroupMembershipsResponse()];

declare 'AddIpOverrideRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AddIpOverrideRequest'];

coerce 'AddIpOverrideRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AddIpOverrideRequest'->new($_) };

declare 'RepeatedAddIpOverrideRequest',
    as ArrayRef[AddIpOverrideRequest()];

coerce 'RepeatedAddIpOverrideRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AddIpOverrideRequest'->new($_) } @$_ ] };

declare 'MapStringAddIpOverrideRequest',
    as HashRef[AddIpOverrideRequest()];

declare 'AddIpOverrideResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AddIpOverrideResponse'];

coerce 'AddIpOverrideResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AddIpOverrideResponse'->new($_) };

declare 'RepeatedAddIpOverrideResponse',
    as ArrayRef[AddIpOverrideResponse()];

coerce 'RepeatedAddIpOverrideResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AddIpOverrideResponse'->new($_) } @$_ ] };

declare 'MapStringAddIpOverrideResponse',
    as HashRef[AddIpOverrideResponse()];

declare 'RemoveIpOverrideRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RemoveIpOverrideRequest'];

coerce 'RemoveIpOverrideRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RemoveIpOverrideRequest'->new($_) };

declare 'RepeatedRemoveIpOverrideRequest',
    as ArrayRef[RemoveIpOverrideRequest()];

coerce 'RepeatedRemoveIpOverrideRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RemoveIpOverrideRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveIpOverrideRequest',
    as HashRef[RemoveIpOverrideRequest()];

declare 'RemoveIpOverrideResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RemoveIpOverrideResponse'];

coerce 'RemoveIpOverrideResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RemoveIpOverrideResponse'->new($_) };

declare 'RepeatedRemoveIpOverrideResponse',
    as ArrayRef[RemoveIpOverrideResponse()];

coerce 'RepeatedRemoveIpOverrideResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RemoveIpOverrideResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveIpOverrideResponse',
    as HashRef[RemoveIpOverrideResponse()];

declare 'ListIpOverridesRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListIpOverridesRequest'];

coerce 'ListIpOverridesRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListIpOverridesRequest'->new($_) };

declare 'RepeatedListIpOverridesRequest',
    as ArrayRef[ListIpOverridesRequest()];

coerce 'RepeatedListIpOverridesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListIpOverridesRequest'->new($_) } @$_ ] };

declare 'MapStringListIpOverridesRequest',
    as HashRef[ListIpOverridesRequest()];

declare 'ListIpOverridesResponse',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListIpOverridesResponse'];

coerce 'ListIpOverridesResponse',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListIpOverridesResponse'->new($_) };

declare 'RepeatedListIpOverridesResponse',
    as ArrayRef[ListIpOverridesResponse()];

coerce 'RepeatedListIpOverridesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ListIpOverridesResponse'->new($_) } @$_ ] };

declare 'MapStringListIpOverridesResponse',
    as HashRef[ListIpOverridesResponse()];

declare 'RelatedAccountGroupMembership',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RelatedAccountGroupMembership'];

coerce 'RelatedAccountGroupMembership',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RelatedAccountGroupMembership'->new($_) };

declare 'RepeatedRelatedAccountGroupMembership',
    as ArrayRef[RelatedAccountGroupMembership()];

coerce 'RepeatedRelatedAccountGroupMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RelatedAccountGroupMembership'->new($_) } @$_ ] };

declare 'MapStringRelatedAccountGroupMembership',
    as HashRef[RelatedAccountGroupMembership()];

declare 'RelatedAccountGroup',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RelatedAccountGroup'];

coerce 'RelatedAccountGroup',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RelatedAccountGroup'->new($_) };

declare 'RepeatedRelatedAccountGroup',
    as ArrayRef[RelatedAccountGroup()];

coerce 'RepeatedRelatedAccountGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::RelatedAccountGroup'->new($_) } @$_ ] };

declare 'MapStringRelatedAccountGroup',
    as HashRef[RelatedAccountGroup()];

declare 'WafSettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WafSettings'];

coerce 'WafSettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WafSettings'->new($_) };

declare 'RepeatedWafSettings',
    as ArrayRef[WafSettings()];

coerce 'RepeatedWafSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::WafSettings'->new($_) } @$_ ] };

declare 'MapStringWafSettings',
    as HashRef[WafSettings()];

declare 'WafFeature',
    as (Int | Str);

declare 'WafService',
    as (Int | Str);

declare 'AssessmentEnvironment',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AssessmentEnvironment'];

coerce 'AssessmentEnvironment',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AssessmentEnvironment'->new($_) };

declare 'RepeatedAssessmentEnvironment',
    as ArrayRef[AssessmentEnvironment()];

coerce 'RepeatedAssessmentEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::AssessmentEnvironment'->new($_) } @$_ ] };

declare 'MapStringAssessmentEnvironment',
    as HashRef[AssessmentEnvironment()];

declare 'PolicyEvaluation',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PolicyEvaluation'];

coerce 'PolicyEvaluation',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PolicyEvaluation'->new($_) };

declare 'RepeatedPolicyEvaluation',
    as ArrayRef[PolicyEvaluation()];

coerce 'RepeatedPolicyEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::PolicyEvaluation'->new($_) } @$_ ] };

declare 'MapStringPolicyEvaluation',
    as HashRef[PolicyEvaluation()];

declare 'ChallengeRuleEvaluation',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRuleEvaluation'];

coerce 'ChallengeRuleEvaluation',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRuleEvaluation'->new($_) };

declare 'RepeatedChallengeRuleEvaluation',
    as ArrayRef[ChallengeRuleEvaluation()];

coerce 'RepeatedChallengeRuleEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRuleEvaluation'->new($_) } @$_ ] };

declare 'MapStringChallengeRuleEvaluation',
    as HashRef[ChallengeRuleEvaluation()];

declare 'IpOverrideData',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::IpOverrideData'];

coerce 'IpOverrideData',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::IpOverrideData'->new($_) };

declare 'RepeatedIpOverrideData',
    as ArrayRef[IpOverrideData()];

coerce 'RepeatedIpOverrideData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::IpOverrideData'->new($_) } @$_ ] };

declare 'MapStringIpOverrideData',
    as HashRef[IpOverrideData()];

declare 'OverrideType',
    as (Int | Str);

declare 'GetPolicyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetPolicyRequest'];

coerce 'GetPolicyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetPolicyRequest'->new($_) };

declare 'RepeatedGetPolicyRequest',
    as ArrayRef[GetPolicyRequest()];

coerce 'RepeatedGetPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::GetPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyRequest',
    as HashRef[GetPolicyRequest()];

declare 'UpdatePolicyRequest',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdatePolicyRequest'];

coerce 'UpdatePolicyRequest',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdatePolicyRequest'->new($_) };

declare 'RepeatedUpdatePolicyRequest',
    as ArrayRef[UpdatePolicyRequest()];

coerce 'RepeatedUpdatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::UpdatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyRequest',
    as HashRef[UpdatePolicyRequest()];

declare 'Policy',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'ChallengeRuleGroup',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRuleGroup'];

coerce 'ChallengeRuleGroup',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRuleGroup'->new($_) };

declare 'RepeatedChallengeRuleGroup',
    as ArrayRef[ChallengeRuleGroup()];

coerce 'RepeatedChallengeRuleGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRuleGroup'->new($_) } @$_ ] };

declare 'MapStringChallengeRuleGroup',
    as HashRef[ChallengeRuleGroup()];

declare 'ChallengeRule',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule'];

coerce 'ChallengeRule',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule'->new($_) };

declare 'RepeatedChallengeRule',
    as ArrayRef[ChallengeRule()];

coerce 'RepeatedChallengeRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule'->new($_) } @$_ ] };

declare 'MapStringChallengeRule',
    as HashRef[ChallengeRule()];

declare 'NoChallengeOutcome',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule::NoChallengeOutcome'];

coerce 'NoChallengeOutcome',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule::NoChallengeOutcome'->new($_) };

declare 'RepeatedNoChallengeOutcome',
    as ArrayRef[NoChallengeOutcome()];

coerce 'RepeatedNoChallengeOutcome',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule::NoChallengeOutcome'->new($_) } @$_ ] };

declare 'MapStringNoChallengeOutcome',
    as HashRef[NoChallengeOutcome()];

declare 'ChallengeOutcome',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule::ChallengeOutcome'];

coerce 'ChallengeOutcome',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule::ChallengeOutcome'->new($_) };

declare 'RepeatedChallengeOutcome',
    as ArrayRef[ChallengeOutcome()];

coerce 'RepeatedChallengeOutcome',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ChallengeRule::ChallengeOutcome'->new($_) } @$_ ] };

declare 'MapStringChallengeOutcome',
    as HashRef[ChallengeOutcome()];

declare 'ClientSettings',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ClientSettings'];

coerce 'ClientSettings',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ClientSettings'->new($_) };

declare 'RepeatedClientSettings',
    as ArrayRef[ClientSettings()];

coerce 'RepeatedClientSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ClientSettings'->new($_) } @$_ ] };

declare 'MapStringClientSettings',
    as HashRef[ClientSettings()];

declare 'ProtectedEndpointGroup',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ProtectedEndpointGroup'];

coerce 'ProtectedEndpointGroup',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ProtectedEndpointGroup'->new($_) };

declare 'RepeatedProtectedEndpointGroup',
    as ArrayRef[ProtectedEndpointGroup()];

coerce 'RepeatedProtectedEndpointGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ProtectedEndpointGroup'->new($_) } @$_ ] };

declare 'MapStringProtectedEndpointGroup',
    as HashRef[ProtectedEndpointGroup()];

declare 'ProtectedEndpoint',
    as InstanceOf['Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ProtectedEndpoint'];

coerce 'ProtectedEndpoint',
    from HashRef, via { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ProtectedEndpoint'->new($_) };

declare 'RepeatedProtectedEndpoint',
    as ArrayRef[ProtectedEndpoint()];

coerce 'RepeatedProtectedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::ProtectedEndpoint'->new($_) } @$_ ] };

declare 'MapStringProtectedEndpoint',
    as HashRef[ProtectedEndpoint()];

1;

__END__

=head1 NAME

Google::Cloud::Recaptchaenterprise::V1::Recaptchaenterprise::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
