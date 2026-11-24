package Google::Cloud::Discoveryengine::V1::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Project',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project'];

coerce 'Project',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project'->new($_) };

declare 'RepeatedProject',
    as ArrayRef[Project()];

coerce 'RepeatedProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project'->new($_) } @$_ ] };

declare 'MapStringProject',
    as HashRef[Project()];

declare 'ServiceTerms',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::ServiceTerms'];

coerce 'ServiceTerms',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::ServiceTerms'->new($_) };

declare 'RepeatedServiceTerms',
    as ArrayRef[ServiceTerms()];

coerce 'RepeatedServiceTerms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::ServiceTerms'->new($_) } @$_ ] };

declare 'MapStringServiceTerms',
    as HashRef[ServiceTerms()];

declare 'State',
    as (Int | Str);

declare 'CustomerProvidedConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig'];

coerce 'CustomerProvidedConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig'->new($_) };

declare 'RepeatedCustomerProvidedConfig',
    as ArrayRef[CustomerProvidedConfig()];

coerce 'RepeatedCustomerProvidedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig'->new($_) } @$_ ] };

declare 'MapStringCustomerProvidedConfig',
    as HashRef[CustomerProvidedConfig()];

declare 'NotebooklmConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig'];

coerce 'NotebooklmConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig'->new($_) };

declare 'RepeatedNotebooklmConfig',
    as ArrayRef[NotebooklmConfig()];

coerce 'RepeatedNotebooklmConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig'->new($_) } @$_ ] };

declare 'MapStringNotebooklmConfig',
    as HashRef[NotebooklmConfig()];

declare 'ModelArmorConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::ModelArmorConfig'];

coerce 'ModelArmorConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::ModelArmorConfig'->new($_) };

declare 'RepeatedModelArmorConfig',
    as ArrayRef[ModelArmorConfig()];

coerce 'RepeatedModelArmorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::ModelArmorConfig'->new($_) } @$_ ] };

declare 'MapStringModelArmorConfig',
    as HashRef[ModelArmorConfig()];

declare 'DataProtectionPolicy',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::DataProtectionPolicy'];

coerce 'DataProtectionPolicy',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::DataProtectionPolicy'->new($_) };

declare 'RepeatedDataProtectionPolicy',
    as ArrayRef[DataProtectionPolicy()];

coerce 'RepeatedDataProtectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::DataProtectionPolicy'->new($_) } @$_ ] };

declare 'MapStringDataProtectionPolicy',
    as HashRef[DataProtectionPolicy()];

declare 'SensitiveDataProtectionPolicy',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::DataProtectionPolicy::SensitiveDataProtectionPolicy'];

coerce 'SensitiveDataProtectionPolicy',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::DataProtectionPolicy::SensitiveDataProtectionPolicy'->new($_) };

declare 'RepeatedSensitiveDataProtectionPolicy',
    as ArrayRef[SensitiveDataProtectionPolicy()];

coerce 'RepeatedSensitiveDataProtectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::NotebooklmConfig::DataProtectionPolicy::SensitiveDataProtectionPolicy'->new($_) } @$_ ] };

declare 'MapStringSensitiveDataProtectionPolicy',
    as HashRef[SensitiveDataProtectionPolicy()];

declare 'ResourceAccessControlConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::ResourceAccessControlConfig'];

coerce 'ResourceAccessControlConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::ResourceAccessControlConfig'->new($_) };

declare 'RepeatedResourceAccessControlConfig',
    as ArrayRef[ResourceAccessControlConfig()];

coerce 'RepeatedResourceAccessControlConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::CustomerProvidedConfig::ResourceAccessControlConfig'->new($_) } @$_ ] };

declare 'MapStringResourceAccessControlConfig',
    as HashRef[ResourceAccessControlConfig()];

declare 'ConfigurableBillingStatus',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::ConfigurableBillingStatus'];

coerce 'ConfigurableBillingStatus',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::ConfigurableBillingStatus'->new($_) };

declare 'RepeatedConfigurableBillingStatus',
    as ArrayRef[ConfigurableBillingStatus()];

coerce 'RepeatedConfigurableBillingStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::ConfigurableBillingStatus'->new($_) } @$_ ] };

declare 'MapStringConfigurableBillingStatus',
    as HashRef[ConfigurableBillingStatus()];

declare 'UpdateType',
    as (Int | Str);

declare 'AgentSearchTokenSubscriptionStatus',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::ConfigurableBillingStatus::AgentSearchTokenSubscriptionStatus'];

coerce 'AgentSearchTokenSubscriptionStatus',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::ConfigurableBillingStatus::AgentSearchTokenSubscriptionStatus'->new($_) };

declare 'RepeatedAgentSearchTokenSubscriptionStatus',
    as ArrayRef[AgentSearchTokenSubscriptionStatus()];

coerce 'RepeatedAgentSearchTokenSubscriptionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::ConfigurableBillingStatus::AgentSearchTokenSubscriptionStatus'->new($_) } @$_ ] };

declare 'MapStringAgentSearchTokenSubscriptionStatus',
    as HashRef[AgentSearchTokenSubscriptionStatus()];

declare 'ServiceTermsMapEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Project::Project::ServiceTermsMapEntry'];

coerce 'ServiceTermsMapEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Project::Project::ServiceTermsMapEntry'->new($_) };

declare 'RepeatedServiceTermsMapEntry',
    as ArrayRef[ServiceTermsMapEntry()];

coerce 'RepeatedServiceTermsMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Project::Project::ServiceTermsMapEntry'->new($_) } @$_ ] };

declare 'MapStringServiceTermsMapEntry',
    as HashRef[ServiceTermsMapEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Project::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
