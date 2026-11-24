package Google::Cloud::Discoveryengine::V1beta::DataStore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataStore',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore'];

coerce 'DataStore',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore'->new($_) };

declare 'RepeatedDataStore',
    as ArrayRef[DataStore()];

coerce 'RepeatedDataStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore'->new($_) } @$_ ] };

declare 'MapStringDataStore',
    as HashRef[DataStore()];

declare 'ContentConfig',
    as (Int | Str);

declare 'ConfigurableBillingApproach',
    as (Int | Str);

declare 'BillingEstimation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::BillingEstimation'];

coerce 'BillingEstimation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::BillingEstimation'->new($_) };

declare 'RepeatedBillingEstimation',
    as ArrayRef[BillingEstimation()];

coerce 'RepeatedBillingEstimation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::BillingEstimation'->new($_) } @$_ ] };

declare 'MapStringBillingEstimation',
    as HashRef[BillingEstimation()];

declare 'ServingConfigDataStore',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::ServingConfigDataStore'];

coerce 'ServingConfigDataStore',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::ServingConfigDataStore'->new($_) };

declare 'RepeatedServingConfigDataStore',
    as ArrayRef[ServingConfigDataStore()];

coerce 'RepeatedServingConfigDataStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::ServingConfigDataStore'->new($_) } @$_ ] };

declare 'MapStringServingConfigDataStore',
    as HashRef[ServingConfigDataStore()];

declare 'FederatedSearchConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig'];

coerce 'FederatedSearchConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig'->new($_) };

declare 'RepeatedFederatedSearchConfig',
    as ArrayRef[FederatedSearchConfig()];

coerce 'RepeatedFederatedSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig'->new($_) } @$_ ] };

declare 'MapStringFederatedSearchConfig',
    as HashRef[FederatedSearchConfig()];

declare 'AlloyDbConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig'];

coerce 'AlloyDbConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig'->new($_) };

declare 'RepeatedAlloyDbConfig',
    as ArrayRef[AlloyDbConfig()];

coerce 'RepeatedAlloyDbConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig'->new($_) } @$_ ] };

declare 'MapStringAlloyDbConfig',
    as HashRef[AlloyDbConfig()];

declare 'AlloyDbConnectionConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig::AlloyDbConnectionConfig'];

coerce 'AlloyDbConnectionConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig::AlloyDbConnectionConfig'->new($_) };

declare 'RepeatedAlloyDbConnectionConfig',
    as ArrayRef[AlloyDbConnectionConfig()];

coerce 'RepeatedAlloyDbConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig::AlloyDbConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringAlloyDbConnectionConfig',
    as HashRef[AlloyDbConnectionConfig()];

declare 'AuthMode',
    as (Int | Str);

declare 'AlloyDbAiNaturalLanguageConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig::AlloyDbAiNaturalLanguageConfig'];

coerce 'AlloyDbAiNaturalLanguageConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig::AlloyDbAiNaturalLanguageConfig'->new($_) };

declare 'RepeatedAlloyDbAiNaturalLanguageConfig',
    as ArrayRef[AlloyDbAiNaturalLanguageConfig()];

coerce 'RepeatedAlloyDbAiNaturalLanguageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::AlloyDbConfig::AlloyDbAiNaturalLanguageConfig'->new($_) } @$_ ] };

declare 'MapStringAlloyDbAiNaturalLanguageConfig',
    as HashRef[AlloyDbAiNaturalLanguageConfig()];

declare 'ThirdPartyOauthConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::ThirdPartyOauthConfig'];

coerce 'ThirdPartyOauthConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::ThirdPartyOauthConfig'->new($_) };

declare 'RepeatedThirdPartyOauthConfig',
    as ArrayRef[ThirdPartyOauthConfig()];

coerce 'RepeatedThirdPartyOauthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::ThirdPartyOauthConfig'->new($_) } @$_ ] };

declare 'MapStringThirdPartyOauthConfig',
    as HashRef[ThirdPartyOauthConfig()];

declare 'NotebooklmConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::NotebooklmConfig'];

coerce 'NotebooklmConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::NotebooklmConfig'->new($_) };

declare 'RepeatedNotebooklmConfig',
    as ArrayRef[NotebooklmConfig()];

coerce 'RepeatedNotebooklmConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore::FederatedSearchConfig::NotebooklmConfig'->new($_) } @$_ ] };

declare 'MapStringNotebooklmConfig',
    as HashRef[NotebooklmConfig()];

declare 'AdvancedSiteSearchConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::AdvancedSiteSearchConfig'];

coerce 'AdvancedSiteSearchConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::AdvancedSiteSearchConfig'->new($_) };

declare 'RepeatedAdvancedSiteSearchConfig',
    as ArrayRef[AdvancedSiteSearchConfig()];

coerce 'RepeatedAdvancedSiteSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::AdvancedSiteSearchConfig'->new($_) } @$_ ] };

declare 'MapStringAdvancedSiteSearchConfig',
    as HashRef[AdvancedSiteSearchConfig()];

declare 'LanguageInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::LanguageInfo'];

coerce 'LanguageInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::LanguageInfo'->new($_) };

declare 'RepeatedLanguageInfo',
    as ArrayRef[LanguageInfo()];

coerce 'RepeatedLanguageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::LanguageInfo'->new($_) } @$_ ] };

declare 'MapStringLanguageInfo',
    as HashRef[LanguageInfo()];

declare 'NaturalLanguageQueryUnderstandingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::NaturalLanguageQueryUnderstandingConfig'];

coerce 'NaturalLanguageQueryUnderstandingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::NaturalLanguageQueryUnderstandingConfig'->new($_) };

declare 'RepeatedNaturalLanguageQueryUnderstandingConfig',
    as ArrayRef[NaturalLanguageQueryUnderstandingConfig()];

coerce 'RepeatedNaturalLanguageQueryUnderstandingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::NaturalLanguageQueryUnderstandingConfig'->new($_) } @$_ ] };

declare 'MapStringNaturalLanguageQueryUnderstandingConfig',
    as HashRef[NaturalLanguageQueryUnderstandingConfig()];

declare 'Mode',
    as (Int | Str);

declare 'WorkspaceConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::DataStore::WorkspaceConfig'];

coerce 'WorkspaceConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::DataStore::WorkspaceConfig'->new($_) };

declare 'RepeatedWorkspaceConfig',
    as ArrayRef[WorkspaceConfig()];

coerce 'RepeatedWorkspaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::DataStore::WorkspaceConfig'->new($_) } @$_ ] };

declare 'MapStringWorkspaceConfig',
    as HashRef[WorkspaceConfig()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::DataStore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
