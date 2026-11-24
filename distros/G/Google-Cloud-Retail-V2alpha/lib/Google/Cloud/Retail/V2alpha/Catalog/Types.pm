package Google::Cloud::Retail::V2alpha::Catalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProductLevelConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::ProductLevelConfig'];

coerce 'ProductLevelConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::ProductLevelConfig'->new($_) };

declare 'RepeatedProductLevelConfig',
    as ArrayRef[ProductLevelConfig()];

coerce 'RepeatedProductLevelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::ProductLevelConfig'->new($_) } @$_ ] };

declare 'MapStringProductLevelConfig',
    as HashRef[ProductLevelConfig()];

declare 'CatalogAttribute',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute'];

coerce 'CatalogAttribute',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute'->new($_) };

declare 'RepeatedCatalogAttribute',
    as ArrayRef[CatalogAttribute()];

coerce 'RepeatedCatalogAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute'->new($_) } @$_ ] };

declare 'MapStringCatalogAttribute',
    as HashRef[CatalogAttribute()];

declare 'AttributeType',
    as (Int | Str);

declare 'IndexableOption',
    as (Int | Str);

declare 'DynamicFacetableOption',
    as (Int | Str);

declare 'SearchableOption',
    as (Int | Str);

declare 'ExactSearchableOption',
    as (Int | Str);

declare 'RetrievableOption',
    as (Int | Str);

declare 'FacetConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig'];

coerce 'FacetConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig'->new($_) };

declare 'RepeatedFacetConfig',
    as ArrayRef[FacetConfig()];

coerce 'RepeatedFacetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig'->new($_) } @$_ ] };

declare 'MapStringFacetConfig',
    as HashRef[FacetConfig()];

declare 'IgnoredFacetValues',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::IgnoredFacetValues'];

coerce 'IgnoredFacetValues',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::IgnoredFacetValues'->new($_) };

declare 'RepeatedIgnoredFacetValues',
    as ArrayRef[IgnoredFacetValues()];

coerce 'RepeatedIgnoredFacetValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::IgnoredFacetValues'->new($_) } @$_ ] };

declare 'MapStringIgnoredFacetValues',
    as HashRef[IgnoredFacetValues()];

declare 'MergedFacetValue',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::MergedFacetValue'];

coerce 'MergedFacetValue',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::MergedFacetValue'->new($_) };

declare 'RepeatedMergedFacetValue',
    as ArrayRef[MergedFacetValue()];

coerce 'RepeatedMergedFacetValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::MergedFacetValue'->new($_) } @$_ ] };

declare 'MapStringMergedFacetValue',
    as HashRef[MergedFacetValue()];

declare 'MergedFacet',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::MergedFacet'];

coerce 'MergedFacet',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::MergedFacet'->new($_) };

declare 'RepeatedMergedFacet',
    as ArrayRef[MergedFacet()];

coerce 'RepeatedMergedFacet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::MergedFacet'->new($_) } @$_ ] };

declare 'MapStringMergedFacet',
    as HashRef[MergedFacet()];

declare 'RerankConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::RerankConfig'];

coerce 'RerankConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::RerankConfig'->new($_) };

declare 'RepeatedRerankConfig',
    as ArrayRef[RerankConfig()];

coerce 'RepeatedRerankConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CatalogAttribute::FacetConfig::RerankConfig'->new($_) } @$_ ] };

declare 'MapStringRerankConfig',
    as HashRef[RerankConfig()];

declare 'AttributesConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig'];

coerce 'AttributesConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig'->new($_) };

declare 'RepeatedAttributesConfig',
    as ArrayRef[AttributesConfig()];

coerce 'RepeatedAttributesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig'->new($_) } @$_ ] };

declare 'MapStringAttributesConfig',
    as HashRef[AttributesConfig()];

declare 'CatalogAttributesEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig::CatalogAttributesEntry'];

coerce 'CatalogAttributesEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig::CatalogAttributesEntry'->new($_) };

declare 'RepeatedCatalogAttributesEntry',
    as ArrayRef[CatalogAttributesEntry()];

coerce 'RepeatedCatalogAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig::CatalogAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringCatalogAttributesEntry',
    as HashRef[CatalogAttributesEntry()];

declare 'CompletionConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::CompletionConfig'];

coerce 'CompletionConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::CompletionConfig'->new($_) };

declare 'RepeatedCompletionConfig',
    as ArrayRef[CompletionConfig()];

coerce 'RepeatedCompletionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::CompletionConfig'->new($_) } @$_ ] };

declare 'MapStringCompletionConfig',
    as HashRef[CompletionConfig()];

declare 'MerchantCenterLink',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterLink'];

coerce 'MerchantCenterLink',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterLink'->new($_) };

declare 'RepeatedMerchantCenterLink',
    as ArrayRef[MerchantCenterLink()];

coerce 'RepeatedMerchantCenterLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterLink'->new($_) } @$_ ] };

declare 'MapStringMerchantCenterLink',
    as HashRef[MerchantCenterLink()];

declare 'MerchantCenterFeedFilter',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterFeedFilter'];

coerce 'MerchantCenterFeedFilter',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterFeedFilter'->new($_) };

declare 'RepeatedMerchantCenterFeedFilter',
    as ArrayRef[MerchantCenterFeedFilter()];

coerce 'RepeatedMerchantCenterFeedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterFeedFilter'->new($_) } @$_ ] };

declare 'MapStringMerchantCenterFeedFilter',
    as HashRef[MerchantCenterFeedFilter()];

declare 'MerchantCenterLinkingConfig',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterLinkingConfig'];

coerce 'MerchantCenterLinkingConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterLinkingConfig'->new($_) };

declare 'RepeatedMerchantCenterLinkingConfig',
    as ArrayRef[MerchantCenterLinkingConfig()];

coerce 'RepeatedMerchantCenterLinkingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::MerchantCenterLinkingConfig'->new($_) } @$_ ] };

declare 'MapStringMerchantCenterLinkingConfig',
    as HashRef[MerchantCenterLinkingConfig()];

declare 'Catalog',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Catalog::Catalog'];

coerce 'Catalog',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Catalog::Catalog'->new($_) };

declare 'RepeatedCatalog',
    as ArrayRef[Catalog()];

coerce 'RepeatedCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Catalog::Catalog'->new($_) } @$_ ] };

declare 'MapStringCatalog',
    as HashRef[Catalog()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::Catalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
