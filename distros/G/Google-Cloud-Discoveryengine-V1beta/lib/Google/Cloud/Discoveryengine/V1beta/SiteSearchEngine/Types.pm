package Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SiteSearchEngine',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine'];

coerce 'SiteSearchEngine',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine'->new($_) };

declare 'RepeatedSiteSearchEngine',
    as ArrayRef[SiteSearchEngine()];

coerce 'RepeatedSiteSearchEngine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine'->new($_) } @$_ ] };

declare 'MapStringSiteSearchEngine',
    as HashRef[SiteSearchEngine()];

declare 'TargetSite',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite'];

coerce 'TargetSite',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite'->new($_) };

declare 'RepeatedTargetSite',
    as ArrayRef[TargetSite()];

coerce 'RepeatedTargetSite',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite'->new($_) } @$_ ] };

declare 'MapStringTargetSite',
    as HashRef[TargetSite()];

declare 'Type',
    as (Int | Str);

declare 'IndexingStatus',
    as (Int | Str);

declare 'FailureReason',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason'];

coerce 'FailureReason',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason'->new($_) };

declare 'RepeatedFailureReason',
    as ArrayRef[FailureReason()];

coerce 'RepeatedFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason'->new($_) } @$_ ] };

declare 'MapStringFailureReason',
    as HashRef[FailureReason()];

declare 'QuotaFailure',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason::QuotaFailure'];

coerce 'QuotaFailure',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason::QuotaFailure'->new($_) };

declare 'RepeatedQuotaFailure',
    as ArrayRef[QuotaFailure()];

coerce 'RepeatedQuotaFailure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::TargetSite::FailureReason::QuotaFailure'->new($_) } @$_ ] };

declare 'MapStringQuotaFailure',
    as HashRef[QuotaFailure()];

declare 'SiteVerificationInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteVerificationInfo'];

coerce 'SiteVerificationInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteVerificationInfo'->new($_) };

declare 'RepeatedSiteVerificationInfo',
    as ArrayRef[SiteVerificationInfo()];

coerce 'RepeatedSiteVerificationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteVerificationInfo'->new($_) } @$_ ] };

declare 'MapStringSiteVerificationInfo',
    as HashRef[SiteVerificationInfo()];

declare 'SiteVerificationState',
    as (Int | Str);

declare 'Sitemap',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Sitemap'];

coerce 'Sitemap',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Sitemap'->new($_) };

declare 'RepeatedSitemap',
    as ArrayRef[Sitemap()];

coerce 'RepeatedSitemap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Sitemap'->new($_) } @$_ ] };

declare 'MapStringSitemap',
    as HashRef[Sitemap()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
