package Google::Cloud::Designcenter::V1::Metadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TFBlueprintMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TFBlueprintMetadata'];

coerce 'TFBlueprintMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TFBlueprintMetadata'->new($_) };

declare 'RepeatedTFBlueprintMetadata',
    as ArrayRef[TFBlueprintMetadata()];

coerce 'RepeatedTFBlueprintMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TFBlueprintMetadata'->new($_) } @$_ ] };

declare 'MapStringTFBlueprintMetadata',
    as HashRef[TFBlueprintMetadata()];

declare 'ProviderVersion',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ProviderVersion'];

coerce 'ProviderVersion',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ProviderVersion'->new($_) };

declare 'RepeatedProviderVersion',
    as ArrayRef[ProviderVersion()];

coerce 'RepeatedProviderVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ProviderVersion'->new($_) } @$_ ] };

declare 'MapStringProviderVersion',
    as HashRef[ProviderVersion()];

declare 'TerraformInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformInput'];

coerce 'TerraformInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformInput'->new($_) };

declare 'RepeatedTerraformInput',
    as ArrayRef[TerraformInput()];

coerce 'RepeatedTerraformInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformInput'->new($_) } @$_ ] };

declare 'MapStringTerraformInput',
    as HashRef[TerraformInput()];

declare 'TerraformVariableValidation',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformVariableValidation'];

coerce 'TerraformVariableValidation',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformVariableValidation'->new($_) };

declare 'RepeatedTerraformVariableValidation',
    as ArrayRef[TerraformVariableValidation()];

coerce 'RepeatedTerraformVariableValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformVariableValidation'->new($_) } @$_ ] };

declare 'MapStringTerraformVariableValidation',
    as HashRef[TerraformVariableValidation()];

declare 'TerraformInputConnections',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformInputConnections'];

coerce 'TerraformInputConnections',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformInputConnections'->new($_) };

declare 'RepeatedTerraformInputConnections',
    as ArrayRef[TerraformInputConnections()];

coerce 'RepeatedTerraformInputConnections',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformInputConnections'->new($_) } @$_ ] };

declare 'MapStringTerraformInputConnections',
    as HashRef[TerraformInputConnections()];

declare 'TerraformOutput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformOutput'];

coerce 'TerraformOutput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformOutput'->new($_) };

declare 'RepeatedTerraformOutput',
    as ArrayRef[TerraformOutput()];

coerce 'RepeatedTerraformOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformOutput'->new($_) } @$_ ] };

declare 'MapStringTerraformOutput',
    as HashRef[TerraformOutput()];

declare 'TerraformBlueprintUiMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformBlueprintUiMetadata'];

coerce 'TerraformBlueprintUiMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformBlueprintUiMetadata'->new($_) };

declare 'RepeatedTerraformBlueprintUiMetadata',
    as ArrayRef[TerraformBlueprintUiMetadata()];

coerce 'RepeatedTerraformBlueprintUiMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformBlueprintUiMetadata'->new($_) } @$_ ] };

declare 'MapStringTerraformBlueprintUiMetadata',
    as HashRef[TerraformBlueprintUiMetadata()];

declare 'AlternateDefault',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::AlternateDefault'];

coerce 'AlternateDefault',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::AlternateDefault'->new($_) };

declare 'RepeatedAlternateDefault',
    as ArrayRef[AlternateDefault()];

coerce 'RepeatedAlternateDefault',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::AlternateDefault'->new($_) } @$_ ] };

declare 'MapStringAlternateDefault',
    as HashRef[AlternateDefault()];

declare 'ValueLabel',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ValueLabel'];

coerce 'ValueLabel',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ValueLabel'->new($_) };

declare 'RepeatedValueLabel',
    as ArrayRef[ValueLabel()];

coerce 'RepeatedValueLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ValueLabel'->new($_) } @$_ ] };

declare 'MapStringValueLabel',
    as HashRef[ValueLabel()];

declare 'DisplayVariableToggle',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::DisplayVariableToggle'];

coerce 'DisplayVariableToggle',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::DisplayVariableToggle'->new($_) };

declare 'RepeatedDisplayVariableToggle',
    as ArrayRef[DisplayVariableToggle()];

coerce 'RepeatedDisplayVariableToggle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::DisplayVariableToggle'->new($_) } @$_ ] };

declare 'MapStringDisplayVariableToggle',
    as HashRef[DisplayVariableToggle()];

declare 'ToggleVariableType',
    as (Int | Str);

declare 'TerraformUiInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiInput'];

coerce 'TerraformUiInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInput'->new($_) };

declare 'RepeatedTerraformUiInput',
    as ArrayRef[TerraformUiInput()];

coerce 'RepeatedTerraformUiInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInput'->new($_) } @$_ ] };

declare 'MapStringTerraformUiInput',
    as HashRef[TerraformUiInput()];

declare 'TerraformUiInputsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiInput::TerraformUiInputsEntry'];

coerce 'TerraformUiInputsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInput::TerraformUiInputsEntry'->new($_) };

declare 'RepeatedTerraformUiInputsEntry',
    as ArrayRef[TerraformUiInputsEntry()];

coerce 'RepeatedTerraformUiInputsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInput::TerraformUiInputsEntry'->new($_) } @$_ ] };

declare 'MapStringTerraformUiInputsEntry',
    as HashRef[TerraformUiInputsEntry()];

declare 'TerraformUiInputDisplayVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiInputDisplayVariable'];

coerce 'TerraformUiInputDisplayVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInputDisplayVariable'->new($_) };

declare 'RepeatedTerraformUiInputDisplayVariable',
    as ArrayRef[TerraformUiInputDisplayVariable()];

coerce 'RepeatedTerraformUiInputDisplayVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInputDisplayVariable'->new($_) } @$_ ] };

declare 'MapStringTerraformUiInputDisplayVariable',
    as HashRef[TerraformUiInputDisplayVariable()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiInputDisplayVariable::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInputDisplayVariable::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiInputDisplayVariable::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'TerraformUiOutput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutput'];

coerce 'TerraformUiOutput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutput'->new($_) };

declare 'RepeatedTerraformUiOutput',
    as ArrayRef[TerraformUiOutput()];

coerce 'RepeatedTerraformUiOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutput'->new($_) } @$_ ] };

declare 'MapStringTerraformUiOutput',
    as HashRef[TerraformUiOutput()];

declare 'TerraformUiOutputsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutput::TerraformUiOutputsEntry'];

coerce 'TerraformUiOutputsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutput::TerraformUiOutputsEntry'->new($_) };

declare 'RepeatedTerraformUiOutputsEntry',
    as ArrayRef[TerraformUiOutputsEntry()];

coerce 'RepeatedTerraformUiOutputsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutput::TerraformUiOutputsEntry'->new($_) } @$_ ] };

declare 'MapStringTerraformUiOutputsEntry',
    as HashRef[TerraformUiOutputsEntry()];

declare 'TerraformUiOutputDisplay',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutputDisplay'];

coerce 'TerraformUiOutputDisplay',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutputDisplay'->new($_) };

declare 'RepeatedTerraformUiOutputDisplay',
    as ArrayRef[TerraformUiOutputDisplay()];

coerce 'RepeatedTerraformUiOutputDisplay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformUiOutputDisplay'->new($_) } @$_ ] };

declare 'MapStringTerraformUiOutputDisplay',
    as HashRef[TerraformUiOutputDisplay()];

declare 'HelmChartMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::HelmChartMetadata'];

coerce 'HelmChartMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartMetadata'->new($_) };

declare 'RepeatedHelmChartMetadata',
    as ArrayRef[HelmChartMetadata()];

coerce 'RepeatedHelmChartMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartMetadata'->new($_) } @$_ ] };

declare 'MapStringHelmChartMetadata',
    as HashRef[HelmChartMetadata()];

declare 'HelmChartInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::HelmChartInput'];

coerce 'HelmChartInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartInput'->new($_) };

declare 'RepeatedHelmChartInput',
    as ArrayRef[HelmChartInput()];

coerce 'RepeatedHelmChartInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartInput'->new($_) } @$_ ] };

declare 'MapStringHelmChartInput',
    as HashRef[HelmChartInput()];

declare 'NestedInputsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::HelmChartInput::NestedInputsEntry'];

coerce 'NestedInputsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartInput::NestedInputsEntry'->new($_) };

declare 'RepeatedNestedInputsEntry',
    as ArrayRef[NestedInputsEntry()];

coerce 'RepeatedNestedInputsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartInput::NestedInputsEntry'->new($_) } @$_ ] };

declare 'MapStringNestedInputsEntry',
    as HashRef[NestedInputsEntry()];

declare 'HelmChartOutput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::HelmChartOutput'];

coerce 'HelmChartOutput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartOutput'->new($_) };

declare 'RepeatedHelmChartOutput',
    as ArrayRef[HelmChartOutput()];

coerce 'RepeatedHelmChartOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::HelmChartOutput'->new($_) } @$_ ] };

declare 'MapStringHelmChartOutput',
    as HashRef[HelmChartOutput()];

declare 'MetadataInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::MetadataInput'];

coerce 'MetadataInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::MetadataInput'->new($_) };

declare 'RepeatedMetadataInput',
    as ArrayRef[MetadataInput()];

coerce 'RepeatedMetadataInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::MetadataInput'->new($_) } @$_ ] };

declare 'MapStringMetadataInput',
    as HashRef[MetadataInput()];

declare 'MetadataInputSpec',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::MetadataInputSpec'];

coerce 'MetadataInputSpec',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::MetadataInputSpec'->new($_) };

declare 'RepeatedMetadataInputSpec',
    as ArrayRef[MetadataInputSpec()];

coerce 'RepeatedMetadataInputSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::MetadataInputSpec'->new($_) } @$_ ] };

declare 'MapStringMetadataInputSpec',
    as HashRef[MetadataInputSpec()];

declare 'TemplateInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateInfo'];

coerce 'TemplateInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateInfo'->new($_) };

declare 'RepeatedTemplateInfo',
    as ArrayRef[TemplateInfo()];

coerce 'RepeatedTemplateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateInfo'->new($_) } @$_ ] };

declare 'MapStringTemplateInfo',
    as HashRef[TemplateInfo()];

declare 'IacFormatInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::IacFormatInfo'];

coerce 'IacFormatInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::IacFormatInfo'->new($_) };

declare 'RepeatedIacFormatInfo',
    as ArrayRef[IacFormatInfo()];

coerce 'RepeatedIacFormatInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::IacFormatInfo'->new($_) } @$_ ] };

declare 'MapStringIacFormatInfo',
    as HashRef[IacFormatInfo()];

declare 'TemplateSchema',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateSchema'];

coerce 'TemplateSchema',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateSchema'->new($_) };

declare 'RepeatedTemplateSchema',
    as ArrayRef[TemplateSchema()];

coerce 'RepeatedTemplateSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateSchema'->new($_) } @$_ ] };

declare 'MapStringTemplateSchema',
    as HashRef[TemplateSchema()];

declare 'TemplateVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateVariable'];

coerce 'TemplateVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateVariable'->new($_) };

declare 'RepeatedTemplateVariable',
    as ArrayRef[TemplateVariable()];

coerce 'RepeatedTemplateVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateVariable'->new($_) } @$_ ] };

declare 'MapStringTemplateVariable',
    as HashRef[TemplateVariable()];

declare 'TemplateConnections',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateConnections'];

coerce 'TemplateConnections',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateConnections'->new($_) };

declare 'RepeatedTemplateConnections',
    as ArrayRef[TemplateConnections()];

coerce 'RepeatedTemplateConnections',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateConnections'->new($_) } @$_ ] };

declare 'MapStringTemplateConnections',
    as HashRef[TemplateConnections()];

declare 'ConnectionSource',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ConnectionSource'];

coerce 'ConnectionSource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ConnectionSource'->new($_) };

declare 'RepeatedConnectionSource',
    as ArrayRef[ConnectionSource()];

coerce 'RepeatedConnectionSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ConnectionSource'->new($_) } @$_ ] };

declare 'MapStringConnectionSource',
    as HashRef[ConnectionSource()];

declare 'ConnectionSpec',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ConnectionSpec'];

coerce 'ConnectionSpec',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ConnectionSpec'->new($_) };

declare 'RepeatedConnectionSpec',
    as ArrayRef[ConnectionSpec()];

coerce 'RepeatedConnectionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ConnectionSpec'->new($_) } @$_ ] };

declare 'MapStringConnectionSpec',
    as HashRef[ConnectionSpec()];

declare 'TemplateRequirements',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateRequirements'];

coerce 'TemplateRequirements',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateRequirements'->new($_) };

declare 'RepeatedTemplateRequirements',
    as ArrayRef[TemplateRequirements()];

coerce 'RepeatedTemplateRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateRequirements'->new($_) } @$_ ] };

declare 'MapStringTemplateRequirements',
    as HashRef[TemplateRequirements()];

declare 'TemplateRoles',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateRoles'];

coerce 'TemplateRoles',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateRoles'->new($_) };

declare 'RepeatedTemplateRoles',
    as ArrayRef[TemplateRoles()];

coerce 'RepeatedTemplateRoles',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateRoles'->new($_) } @$_ ] };

declare 'MapStringTemplateRoles',
    as HashRef[TemplateRoles()];

declare 'TemplateUi',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateUi'];

coerce 'TemplateUi',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUi'->new($_) };

declare 'RepeatedTemplateUi',
    as ArrayRef[TemplateUi()];

coerce 'RepeatedTemplateUi',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUi'->new($_) } @$_ ] };

declare 'MapStringTemplateUi',
    as HashRef[TemplateUi()];

declare 'TemplateUiInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateUiInput'];

coerce 'TemplateUiInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiInput'->new($_) };

declare 'RepeatedTemplateUiInput',
    as ArrayRef[TemplateUiInput()];

coerce 'RepeatedTemplateUiInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiInput'->new($_) } @$_ ] };

declare 'MapStringTemplateUiInput',
    as HashRef[TemplateUiInput()];

declare 'VariablesEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateUiInput::VariablesEntry'];

coerce 'VariablesEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiInput::VariablesEntry'->new($_) };

declare 'RepeatedVariablesEntry',
    as ArrayRef[VariablesEntry()];

coerce 'RepeatedVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiInput::VariablesEntry'->new($_) } @$_ ] };

declare 'MapStringVariablesEntry',
    as HashRef[VariablesEntry()];

declare 'TemplateUiOutput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutput'];

coerce 'TemplateUiOutput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutput'->new($_) };

declare 'RepeatedTemplateUiOutput',
    as ArrayRef[TemplateUiOutput()];

coerce 'RepeatedTemplateUiOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutput'->new($_) } @$_ ] };

declare 'MapStringTemplateUiOutput',
    as HashRef[TemplateUiOutput()];

declare 'OutputsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutput::OutputsEntry'];

coerce 'OutputsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutput::OutputsEntry'->new($_) };

declare 'RepeatedOutputsEntry',
    as ArrayRef[OutputsEntry()];

coerce 'RepeatedOutputsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutput::OutputsEntry'->new($_) } @$_ ] };

declare 'MapStringOutputsEntry',
    as HashRef[OutputsEntry()];

declare 'TemplateUiOutputDisplayVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutputDisplayVariable'];

coerce 'TemplateUiOutputDisplayVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutputDisplayVariable'->new($_) };

declare 'RepeatedTemplateUiOutputDisplayVariable',
    as ArrayRef[TemplateUiOutputDisplayVariable()];

coerce 'RepeatedTemplateUiOutputDisplayVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TemplateUiOutputDisplayVariable'->new($_) } @$_ ] };

declare 'MapStringTemplateUiOutputDisplayVariable',
    as HashRef[TemplateUiOutputDisplayVariable()];

declare 'DisplayVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::DisplayVariable'];

coerce 'DisplayVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::DisplayVariable'->new($_) };

declare 'RepeatedDisplayVariable',
    as ArrayRef[DisplayVariable()];

coerce 'RepeatedDisplayVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::DisplayVariable'->new($_) } @$_ ] };

declare 'MapStringDisplayVariable',
    as HashRef[DisplayVariable()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::DisplayVariable::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::DisplayVariable::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::DisplayVariable::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'ValueLabelInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ValueLabelInput'];

coerce 'ValueLabelInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ValueLabelInput'->new($_) };

declare 'RepeatedValueLabelInput',
    as ArrayRef[ValueLabelInput()];

coerce 'RepeatedValueLabelInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ValueLabelInput'->new($_) } @$_ ] };

declare 'MapStringValueLabelInput',
    as HashRef[ValueLabelInput()];

declare 'AlternateDefaultInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::AlternateDefaultInput'];

coerce 'AlternateDefaultInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::AlternateDefaultInput'->new($_) };

declare 'RepeatedAlternateDefaultInput',
    as ArrayRef[AlternateDefaultInput()];

coerce 'RepeatedAlternateDefaultInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::AlternateDefaultInput'->new($_) } @$_ ] };

declare 'MapStringAlternateDefaultInput',
    as HashRef[AlternateDefaultInput()];

declare 'LogicalProduct',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::LogicalProduct'];

coerce 'LogicalProduct',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::LogicalProduct'->new($_) };

declare 'RepeatedLogicalProduct',
    as ArrayRef[LogicalProduct()];

coerce 'RepeatedLogicalProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::LogicalProduct'->new($_) } @$_ ] };

declare 'MapStringLogicalProduct',
    as HashRef[LogicalProduct()];

declare 'InferredMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::InferredMetadata'];

coerce 'InferredMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::InferredMetadata'->new($_) };

declare 'RepeatedInferredMetadata',
    as ArrayRef[InferredMetadata()];

coerce 'RepeatedInferredMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::InferredMetadata'->new($_) } @$_ ] };

declare 'MapStringInferredMetadata',
    as HashRef[InferredMetadata()];

declare 'ResourceType',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ResourceType'];

coerce 'ResourceType',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ResourceType'->new($_) };

declare 'RepeatedResourceType',
    as ArrayRef[ResourceType()];

coerce 'RepeatedResourceType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ResourceType'->new($_) } @$_ ] };

declare 'MapStringResourceType',
    as HashRef[ResourceType()];

declare 'TerraformModuleMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::TerraformModuleMetadata'];

coerce 'TerraformModuleMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::TerraformModuleMetadata'->new($_) };

declare 'RepeatedTerraformModuleMetadata',
    as ArrayRef[TerraformModuleMetadata()];

coerce 'RepeatedTerraformModuleMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::TerraformModuleMetadata'->new($_) } @$_ ] };

declare 'MapStringTerraformModuleMetadata',
    as HashRef[TerraformModuleMetadata()];

declare 'ModuleDetails',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ModuleDetails'];

coerce 'ModuleDetails',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ModuleDetails'->new($_) };

declare 'RepeatedModuleDetails',
    as ArrayRef[ModuleDetails()];

coerce 'RepeatedModuleDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ModuleDetails'->new($_) } @$_ ] };

declare 'MapStringModuleDetails',
    as HashRef[ModuleDetails()];

declare 'ModuleInput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ModuleInput'];

coerce 'ModuleInput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ModuleInput'->new($_) };

declare 'RepeatedModuleInput',
    as ArrayRef[ModuleInput()];

coerce 'RepeatedModuleInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ModuleInput'->new($_) } @$_ ] };

declare 'MapStringModuleInput',
    as HashRef[ModuleInput()];

declare 'ModuleOutput',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ModuleOutput'];

coerce 'ModuleOutput',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ModuleOutput'->new($_) };

declare 'RepeatedModuleOutput',
    as ArrayRef[ModuleOutput()];

coerce 'RepeatedModuleOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ModuleOutput'->new($_) } @$_ ] };

declare 'MapStringModuleOutput',
    as HashRef[ModuleOutput()];

declare 'ModuleDependency',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ModuleDependency'];

coerce 'ModuleDependency',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ModuleDependency'->new($_) };

declare 'RepeatedModuleDependency',
    as ArrayRef[ModuleDependency()];

coerce 'RepeatedModuleDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ModuleDependency'->new($_) } @$_ ] };

declare 'MapStringModuleDependency',
    as HashRef[ModuleDependency()];

declare 'ProviderDependency',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ProviderDependency'];

coerce 'ProviderDependency',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ProviderDependency'->new($_) };

declare 'RepeatedProviderDependency',
    as ArrayRef[ProviderDependency()];

coerce 'RepeatedProviderDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ProviderDependency'->new($_) } @$_ ] };

declare 'MapStringProviderDependency',
    as HashRef[ProviderDependency()];

declare 'ModuleResource',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ModuleResource'];

coerce 'ModuleResource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ModuleResource'->new($_) };

declare 'RepeatedModuleResource',
    as ArrayRef[ModuleResource()];

coerce 'RepeatedModuleResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ModuleResource'->new($_) } @$_ ] };

declare 'MapStringModuleResource',
    as HashRef[ModuleResource()];

declare 'ListCatalogTemplateRevisionMetadataResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::ListCatalogTemplateRevisionMetadataResponse'];

coerce 'ListCatalogTemplateRevisionMetadataResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::ListCatalogTemplateRevisionMetadataResponse'->new($_) };

declare 'RepeatedListCatalogTemplateRevisionMetadataResponse',
    as ArrayRef[ListCatalogTemplateRevisionMetadataResponse()];

coerce 'RepeatedListCatalogTemplateRevisionMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::ListCatalogTemplateRevisionMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringListCatalogTemplateRevisionMetadataResponse',
    as HashRef[ListCatalogTemplateRevisionMetadataResponse()];

declare 'CatalogTemplateRevisionMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Metadata::CatalogTemplateRevisionMetadata'];

coerce 'CatalogTemplateRevisionMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Metadata::CatalogTemplateRevisionMetadata'->new($_) };

declare 'RepeatedCatalogTemplateRevisionMetadata',
    as ArrayRef[CatalogTemplateRevisionMetadata()];

coerce 'RepeatedCatalogTemplateRevisionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Metadata::CatalogTemplateRevisionMetadata'->new($_) } @$_ ] };

declare 'MapStringCatalogTemplateRevisionMetadata',
    as HashRef[CatalogTemplateRevisionMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Metadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
