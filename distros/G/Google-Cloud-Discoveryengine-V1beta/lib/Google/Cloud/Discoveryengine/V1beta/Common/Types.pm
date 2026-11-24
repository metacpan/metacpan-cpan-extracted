package Google::Cloud::Discoveryengine::V1beta::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IndustryVertical',
    as (Int | Str);

declare 'SolutionType',
    as (Int | Str);

declare 'SearchUseCase',
    as (Int | Str);

declare 'SearchTier',
    as (Int | Str);

declare 'SearchAddOn',
    as (Int | Str);

declare 'SubscriptionTier',
    as (Int | Str);

declare 'SubscriptionTerm',
    as (Int | Str);

declare 'Interval',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::Interval'];

coerce 'Interval',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::Interval'->new($_) };

declare 'RepeatedInterval',
    as ArrayRef[Interval()];

coerce 'RepeatedInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::Interval'->new($_) } @$_ ] };

declare 'MapStringInterval',
    as HashRef[Interval()];

declare 'CustomAttribute',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::CustomAttribute'];

coerce 'CustomAttribute',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::CustomAttribute'->new($_) };

declare 'RepeatedCustomAttribute',
    as ArrayRef[CustomAttribute()];

coerce 'RepeatedCustomAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::CustomAttribute'->new($_) } @$_ ] };

declare 'MapStringCustomAttribute',
    as HashRef[CustomAttribute()];

declare 'UserInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::UserInfo'];

coerce 'UserInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::UserInfo'->new($_) };

declare 'RepeatedUserInfo',
    as ArrayRef[UserInfo()];

coerce 'RepeatedUserInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::UserInfo'->new($_) } @$_ ] };

declare 'MapStringUserInfo',
    as HashRef[UserInfo()];

declare 'PreciseLocation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::UserInfo::PreciseLocation'];

coerce 'PreciseLocation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::UserInfo::PreciseLocation'->new($_) };

declare 'RepeatedPreciseLocation',
    as ArrayRef[PreciseLocation()];

coerce 'RepeatedPreciseLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::UserInfo::PreciseLocation'->new($_) } @$_ ] };

declare 'MapStringPreciseLocation',
    as HashRef[PreciseLocation()];

declare 'EmbeddingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::EmbeddingConfig'];

coerce 'EmbeddingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::EmbeddingConfig'->new($_) };

declare 'RepeatedEmbeddingConfig',
    as ArrayRef[EmbeddingConfig()];

coerce 'RepeatedEmbeddingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::EmbeddingConfig'->new($_) } @$_ ] };

declare 'MapStringEmbeddingConfig',
    as HashRef[EmbeddingConfig()];

declare 'DoubleList',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::DoubleList'];

coerce 'DoubleList',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::DoubleList'->new($_) };

declare 'RepeatedDoubleList',
    as ArrayRef[DoubleList()];

coerce 'RepeatedDoubleList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::DoubleList'->new($_) } @$_ ] };

declare 'MapStringDoubleList',
    as HashRef[DoubleList()];

declare 'IdpConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig'];

coerce 'IdpConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig'->new($_) };

declare 'RepeatedIdpConfig',
    as ArrayRef[IdpConfig()];

coerce 'RepeatedIdpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig'->new($_) } @$_ ] };

declare 'MapStringIdpConfig',
    as HashRef[IdpConfig()];

declare 'IdpType',
    as (Int | Str);

declare 'ExternalIdpConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig::ExternalIdpConfig'];

coerce 'ExternalIdpConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig::ExternalIdpConfig'->new($_) };

declare 'RepeatedExternalIdpConfig',
    as ArrayRef[ExternalIdpConfig()];

coerce 'RepeatedExternalIdpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig::ExternalIdpConfig'->new($_) } @$_ ] };

declare 'MapStringExternalIdpConfig',
    as HashRef[ExternalIdpConfig()];

declare 'Principal',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::Principal'];

coerce 'Principal',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::Principal'->new($_) };

declare 'RepeatedPrincipal',
    as ArrayRef[Principal()];

coerce 'RepeatedPrincipal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::Principal'->new($_) } @$_ ] };

declare 'MapStringPrincipal',
    as HashRef[Principal()];

declare 'HealthcareFhirConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::HealthcareFhirConfig'];

coerce 'HealthcareFhirConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::HealthcareFhirConfig'->new($_) };

declare 'RepeatedHealthcareFhirConfig',
    as ArrayRef[HealthcareFhirConfig()];

coerce 'RepeatedHealthcareFhirConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::HealthcareFhirConfig'->new($_) } @$_ ] };

declare 'MapStringHealthcareFhirConfig',
    as HashRef[HealthcareFhirConfig()];

declare 'SearchLinkPromotion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Common::SearchLinkPromotion'];

coerce 'SearchLinkPromotion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Common::SearchLinkPromotion'->new($_) };

declare 'RepeatedSearchLinkPromotion',
    as ArrayRef[SearchLinkPromotion()];

coerce 'RepeatedSearchLinkPromotion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Common::SearchLinkPromotion'->new($_) } @$_ ] };

declare 'MapStringSearchLinkPromotion',
    as HashRef[SearchLinkPromotion()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
