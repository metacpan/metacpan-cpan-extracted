package Google::Cloud::Discoveryengine::V1::WidgetConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ModelInfoView',
    as (Int | Str);

declare 'WidgetConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig'];

coerce 'WidgetConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig'->new($_) };

declare 'RepeatedWidgetConfig',
    as ArrayRef[WidgetConfig()];

coerce 'RepeatedWidgetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig'->new($_) } @$_ ] };

declare 'MapStringWidgetConfig',
    as HashRef[WidgetConfig()];

declare 'DataStoreType',
    as (Int | Str);

declare 'ResultDisplayType',
    as (Int | Str);

declare 'UIComponentField',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UIComponentField'];

coerce 'UIComponentField',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UIComponentField'->new($_) };

declare 'RepeatedUIComponentField',
    as ArrayRef[UIComponentField()];

coerce 'RepeatedUIComponentField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UIComponentField'->new($_) } @$_ ] };

declare 'MapStringUIComponentField',
    as HashRef[UIComponentField()];

declare 'DeviceVisibility',
    as (Int | Str);

declare 'FacetField',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::FacetField'];

coerce 'FacetField',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::FacetField'->new($_) };

declare 'RepeatedFacetField',
    as ArrayRef[FacetField()];

coerce 'RepeatedFacetField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::FacetField'->new($_) } @$_ ] };

declare 'MapStringFacetField',
    as HashRef[FacetField()];

declare 'DataStoreUiConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreUiConfig'];

coerce 'DataStoreUiConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreUiConfig'->new($_) };

declare 'RepeatedDataStoreUiConfig',
    as ArrayRef[DataStoreUiConfig()];

coerce 'RepeatedDataStoreUiConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreUiConfig'->new($_) } @$_ ] };

declare 'MapStringDataStoreUiConfig',
    as HashRef[DataStoreUiConfig()];

declare 'FieldsUiComponentsMapEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreUiConfig::FieldsUiComponentsMapEntry'];

coerce 'FieldsUiComponentsMapEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreUiConfig::FieldsUiComponentsMapEntry'->new($_) };

declare 'RepeatedFieldsUiComponentsMapEntry',
    as ArrayRef[FieldsUiComponentsMapEntry()];

coerce 'RepeatedFieldsUiComponentsMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreUiConfig::FieldsUiComponentsMapEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsUiComponentsMapEntry',
    as HashRef[FieldsUiComponentsMapEntry()];

declare 'DataStoreComponent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreComponent'];

coerce 'DataStoreComponent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreComponent'->new($_) };

declare 'RepeatedDataStoreComponent',
    as ArrayRef[DataStoreComponent()];

coerce 'RepeatedDataStoreComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::DataStoreComponent'->new($_) } @$_ ] };

declare 'MapStringDataStoreComponent',
    as HashRef[DataStoreComponent()];

declare 'DataStoreConfigType',
    as (Int | Str);

declare 'ConnectorAuthState',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::ConnectorAuthState'];

coerce 'ConnectorAuthState',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::ConnectorAuthState'->new($_) };

declare 'RepeatedConnectorAuthState',
    as ArrayRef[ConnectorAuthState()];

coerce 'RepeatedConnectorAuthState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::ConnectorAuthState'->new($_) } @$_ ] };

declare 'MapStringConnectorAuthState',
    as HashRef[ConnectorAuthState()];

declare 'AuthState',
    as (Int | Str);

declare 'BatchAuthStatus',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::BatchAuthStatus'];

coerce 'BatchAuthStatus',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::BatchAuthStatus'->new($_) };

declare 'RepeatedBatchAuthStatus',
    as ArrayRef[BatchAuthStatus()];

coerce 'RepeatedBatchAuthStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::BatchAuthStatus'->new($_) } @$_ ] };

declare 'MapStringBatchAuthStatus',
    as HashRef[BatchAuthStatus()];

declare 'CollectionComponent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::CollectionComponent'];

coerce 'CollectionComponent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::CollectionComponent'->new($_) };

declare 'RepeatedCollectionComponent',
    as ArrayRef[CollectionComponent()];

coerce 'RepeatedCollectionComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::CollectionComponent'->new($_) } @$_ ] };

declare 'MapStringCollectionComponent',
    as HashRef[CollectionComponent()];

declare 'UiSettings',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings'];

coerce 'UiSettings',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings'->new($_) };

declare 'RepeatedUiSettings',
    as ArrayRef[UiSettings()];

coerce 'RepeatedUiSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings'->new($_) } @$_ ] };

declare 'MapStringUiSettings',
    as HashRef[UiSettings()];

declare 'InteractionType',
    as (Int | Str);

declare 'FeatureState',
    as (Int | Str);

declare 'ModelState',
    as (Int | Str);

declare 'GenerativeAnswerConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::GenerativeAnswerConfig'];

coerce 'GenerativeAnswerConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::GenerativeAnswerConfig'->new($_) };

declare 'RepeatedGenerativeAnswerConfig',
    as ArrayRef[GenerativeAnswerConfig()];

coerce 'RepeatedGenerativeAnswerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::GenerativeAnswerConfig'->new($_) } @$_ ] };

declare 'MapStringGenerativeAnswerConfig',
    as HashRef[GenerativeAnswerConfig()];

declare 'ImageSource',
    as (Int | Str);

declare 'ModelConfigInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo'];

coerce 'ModelConfigInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo'->new($_) };

declare 'RepeatedModelConfigInfo',
    as ArrayRef[ModelConfigInfo()];

coerce 'RepeatedModelConfigInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo'->new($_) } @$_ ] };

declare 'MapStringModelConfigInfo',
    as HashRef[ModelConfigInfo()];

declare 'ResolvedModel',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo::ResolvedModel'];

coerce 'ResolvedModel',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo::ResolvedModel'->new($_) };

declare 'RepeatedResolvedModel',
    as ArrayRef[ResolvedModel()];

coerce 'RepeatedResolvedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo::ResolvedModel'->new($_) } @$_ ] };

declare 'MapStringResolvedModel',
    as HashRef[ResolvedModel()];

declare 'AdminView',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo::ResolvedModel::AdminView'];

coerce 'AdminView',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo::ResolvedModel::AdminView'->new($_) };

declare 'RepeatedAdminView',
    as ArrayRef[AdminView()];

coerce 'RepeatedAdminView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigInfo::ResolvedModel::AdminView'->new($_) } @$_ ] };

declare 'MapStringAdminView',
    as HashRef[AdminView()];

declare 'SearchAddonSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::SearchAddonSpec'];

coerce 'SearchAddonSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::SearchAddonSpec'->new($_) };

declare 'RepeatedSearchAddonSpec',
    as ArrayRef[SearchAddonSpec()];

coerce 'RepeatedSearchAddonSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::SearchAddonSpec'->new($_) } @$_ ] };

declare 'MapStringSearchAddonSpec',
    as HashRef[SearchAddonSpec()];

declare 'FeaturesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::FeaturesEntry'];

coerce 'FeaturesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::FeaturesEntry'->new($_) };

declare 'RepeatedFeaturesEntry',
    as ArrayRef[FeaturesEntry()];

coerce 'RepeatedFeaturesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::FeaturesEntry'->new($_) } @$_ ] };

declare 'MapStringFeaturesEntry',
    as HashRef[FeaturesEntry()];

declare 'ModelConfigsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigsEntry'];

coerce 'ModelConfigsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigsEntry'->new($_) };

declare 'RepeatedModelConfigsEntry',
    as ArrayRef[ModelConfigsEntry()];

coerce 'RepeatedModelConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiSettings::ModelConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringModelConfigsEntry',
    as HashRef[ModelConfigsEntry()];

declare 'AccessSettings',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::AccessSettings'];

coerce 'AccessSettings',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::AccessSettings'->new($_) };

declare 'RepeatedAccessSettings',
    as ArrayRef[AccessSettings()];

coerce 'RepeatedAccessSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::AccessSettings'->new($_) } @$_ ] };

declare 'MapStringAccessSettings',
    as HashRef[AccessSettings()];

declare 'Image',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'UiBrandingSettings',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiBrandingSettings'];

coerce 'UiBrandingSettings',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiBrandingSettings'->new($_) };

declare 'RepeatedUiBrandingSettings',
    as ArrayRef[UiBrandingSettings()];

coerce 'RepeatedUiBrandingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::UiBrandingSettings'->new($_) } @$_ ] };

declare 'MapStringUiBrandingSettings',
    as HashRef[UiBrandingSettings()];

declare 'HomepageSetting',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::HomepageSetting'];

coerce 'HomepageSetting',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::HomepageSetting'->new($_) };

declare 'RepeatedHomepageSetting',
    as ArrayRef[HomepageSetting()];

coerce 'RepeatedHomepageSetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::HomepageSetting'->new($_) } @$_ ] };

declare 'MapStringHomepageSetting',
    as HashRef[HomepageSetting()];

declare 'Shortcut',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::HomepageSetting::Shortcut'];

coerce 'Shortcut',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::HomepageSetting::Shortcut'->new($_) };

declare 'RepeatedShortcut',
    as ArrayRef[Shortcut()];

coerce 'RepeatedShortcut',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::HomepageSetting::Shortcut'->new($_) } @$_ ] };

declare 'MapStringShortcut',
    as HashRef[Shortcut()];

declare 'AssistantSettings',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::AssistantSettings'];

coerce 'AssistantSettings',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::AssistantSettings'->new($_) };

declare 'RepeatedAssistantSettings',
    as ArrayRef[AssistantSettings()];

coerce 'RepeatedAssistantSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::AssistantSettings'->new($_) } @$_ ] };

declare 'MapStringAssistantSettings',
    as HashRef[AssistantSettings()];

declare 'WebGroundingType',
    as (Int | Str);

declare 'CustomerProvidedConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::CustomerProvidedConfig'];

coerce 'CustomerProvidedConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::CustomerProvidedConfig'->new($_) };

declare 'RepeatedCustomerProvidedConfig',
    as ArrayRef[CustomerProvidedConfig()];

coerce 'RepeatedCustomerProvidedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::CustomerProvidedConfig'->new($_) } @$_ ] };

declare 'MapStringCustomerProvidedConfig',
    as HashRef[CustomerProvidedConfig()];

declare 'CustomerType',
    as (Int | Str);

declare 'ComplianceLevel',
    as (Int | Str);

declare 'Node',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::WidgetConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
