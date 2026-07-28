package Google::Dataflow::V1beta3::Templates::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ParameterType',
    as (Int | Str);

declare 'LaunchFlexTemplateResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateResponse'];

coerce 'LaunchFlexTemplateResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateResponse'->new($_) };

declare 'RepeatedLaunchFlexTemplateResponse',
    as ArrayRef[LaunchFlexTemplateResponse()];

coerce 'RepeatedLaunchFlexTemplateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateResponse'->new($_) } @$_ ] };

declare 'MapStringLaunchFlexTemplateResponse',
    as HashRef[LaunchFlexTemplateResponse()];

declare 'ContainerSpec',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::ContainerSpec'];

coerce 'ContainerSpec',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::ContainerSpec'->new($_) };

declare 'RepeatedContainerSpec',
    as ArrayRef[ContainerSpec()];

coerce 'RepeatedContainerSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::ContainerSpec'->new($_) } @$_ ] };

declare 'MapStringContainerSpec',
    as HashRef[ContainerSpec()];

declare 'LaunchFlexTemplateParameter',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter'];

coerce 'LaunchFlexTemplateParameter',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter'->new($_) };

declare 'RepeatedLaunchFlexTemplateParameter',
    as ArrayRef[LaunchFlexTemplateParameter()];

coerce 'RepeatedLaunchFlexTemplateParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter'->new($_) } @$_ ] };

declare 'MapStringLaunchFlexTemplateParameter',
    as HashRef[LaunchFlexTemplateParameter()];

declare 'ParametersEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'LaunchOptionsEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::LaunchOptionsEntry'];

coerce 'LaunchOptionsEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::LaunchOptionsEntry'->new($_) };

declare 'RepeatedLaunchOptionsEntry',
    as ArrayRef[LaunchOptionsEntry()];

coerce 'RepeatedLaunchOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::LaunchOptionsEntry'->new($_) } @$_ ] };

declare 'MapStringLaunchOptionsEntry',
    as HashRef[LaunchOptionsEntry()];

declare 'TransformNameMappingsEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::TransformNameMappingsEntry'];

coerce 'TransformNameMappingsEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::TransformNameMappingsEntry'->new($_) };

declare 'RepeatedTransformNameMappingsEntry',
    as ArrayRef[TransformNameMappingsEntry()];

coerce 'RepeatedTransformNameMappingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateParameter::TransformNameMappingsEntry'->new($_) } @$_ ] };

declare 'MapStringTransformNameMappingsEntry',
    as HashRef[TransformNameMappingsEntry()];

declare 'FlexTemplateRuntimeEnvironment',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::FlexTemplateRuntimeEnvironment'];

coerce 'FlexTemplateRuntimeEnvironment',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::FlexTemplateRuntimeEnvironment'->new($_) };

declare 'RepeatedFlexTemplateRuntimeEnvironment',
    as ArrayRef[FlexTemplateRuntimeEnvironment()];

coerce 'RepeatedFlexTemplateRuntimeEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::FlexTemplateRuntimeEnvironment'->new($_) } @$_ ] };

declare 'MapStringFlexTemplateRuntimeEnvironment',
    as HashRef[FlexTemplateRuntimeEnvironment()];

declare 'AdditionalUserLabelsEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::FlexTemplateRuntimeEnvironment::AdditionalUserLabelsEntry'];

coerce 'AdditionalUserLabelsEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::FlexTemplateRuntimeEnvironment::AdditionalUserLabelsEntry'->new($_) };

declare 'RepeatedAdditionalUserLabelsEntry',
    as ArrayRef[AdditionalUserLabelsEntry()];

coerce 'RepeatedAdditionalUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::FlexTemplateRuntimeEnvironment::AdditionalUserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalUserLabelsEntry',
    as HashRef[AdditionalUserLabelsEntry()];

declare 'LaunchFlexTemplateRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateRequest'];

coerce 'LaunchFlexTemplateRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateRequest'->new($_) };

declare 'RepeatedLaunchFlexTemplateRequest',
    as ArrayRef[LaunchFlexTemplateRequest()];

coerce 'RepeatedLaunchFlexTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchFlexTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringLaunchFlexTemplateRequest',
    as HashRef[LaunchFlexTemplateRequest()];

declare 'RuntimeEnvironment',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::RuntimeEnvironment'];

coerce 'RuntimeEnvironment',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::RuntimeEnvironment'->new($_) };

declare 'RepeatedRuntimeEnvironment',
    as ArrayRef[RuntimeEnvironment()];

coerce 'RepeatedRuntimeEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::RuntimeEnvironment'->new($_) } @$_ ] };

declare 'MapStringRuntimeEnvironment',
    as HashRef[RuntimeEnvironment()];

declare 'AdditionalUserLabelsEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::RuntimeEnvironment::AdditionalUserLabelsEntry'];

coerce 'AdditionalUserLabelsEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::RuntimeEnvironment::AdditionalUserLabelsEntry'->new($_) };

declare 'RepeatedAdditionalUserLabelsEntry',
    as ArrayRef[AdditionalUserLabelsEntry()];

coerce 'RepeatedAdditionalUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::RuntimeEnvironment::AdditionalUserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalUserLabelsEntry',
    as HashRef[AdditionalUserLabelsEntry()];

declare 'ParameterMetadataEnumOption',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::ParameterMetadataEnumOption'];

coerce 'ParameterMetadataEnumOption',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::ParameterMetadataEnumOption'->new($_) };

declare 'RepeatedParameterMetadataEnumOption',
    as ArrayRef[ParameterMetadataEnumOption()];

coerce 'RepeatedParameterMetadataEnumOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::ParameterMetadataEnumOption'->new($_) } @$_ ] };

declare 'MapStringParameterMetadataEnumOption',
    as HashRef[ParameterMetadataEnumOption()];

declare 'ParameterMetadata',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::ParameterMetadata'];

coerce 'ParameterMetadata',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::ParameterMetadata'->new($_) };

declare 'RepeatedParameterMetadata',
    as ArrayRef[ParameterMetadata()];

coerce 'RepeatedParameterMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::ParameterMetadata'->new($_) } @$_ ] };

declare 'MapStringParameterMetadata',
    as HashRef[ParameterMetadata()];

declare 'CustomMetadataEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::ParameterMetadata::CustomMetadataEntry'];

coerce 'CustomMetadataEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::ParameterMetadata::CustomMetadataEntry'->new($_) };

declare 'RepeatedCustomMetadataEntry',
    as ArrayRef[CustomMetadataEntry()];

coerce 'RepeatedCustomMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::ParameterMetadata::CustomMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringCustomMetadataEntry',
    as HashRef[CustomMetadataEntry()];

declare 'TemplateMetadata',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::TemplateMetadata'];

coerce 'TemplateMetadata',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::TemplateMetadata'->new($_) };

declare 'RepeatedTemplateMetadata',
    as ArrayRef[TemplateMetadata()];

coerce 'RepeatedTemplateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::TemplateMetadata'->new($_) } @$_ ] };

declare 'MapStringTemplateMetadata',
    as HashRef[TemplateMetadata()];

declare 'SDKInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::SDKInfo'];

coerce 'SDKInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::SDKInfo'->new($_) };

declare 'RepeatedSDKInfo',
    as ArrayRef[SDKInfo()];

coerce 'RepeatedSDKInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::SDKInfo'->new($_) } @$_ ] };

declare 'MapStringSDKInfo',
    as HashRef[SDKInfo()];

declare 'Language',
    as (Int | Str);

declare 'RuntimeMetadata',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::RuntimeMetadata'];

coerce 'RuntimeMetadata',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::RuntimeMetadata'->new($_) };

declare 'RepeatedRuntimeMetadata',
    as ArrayRef[RuntimeMetadata()];

coerce 'RepeatedRuntimeMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::RuntimeMetadata'->new($_) } @$_ ] };

declare 'MapStringRuntimeMetadata',
    as HashRef[RuntimeMetadata()];

declare 'CreateJobFromTemplateRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest'];

coerce 'CreateJobFromTemplateRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest'->new($_) };

declare 'RepeatedCreateJobFromTemplateRequest',
    as ArrayRef[CreateJobFromTemplateRequest()];

coerce 'RepeatedCreateJobFromTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobFromTemplateRequest',
    as HashRef[CreateJobFromTemplateRequest()];

declare 'ParametersEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'GetTemplateRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::GetTemplateRequest'];

coerce 'GetTemplateRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::GetTemplateRequest'->new($_) };

declare 'RepeatedGetTemplateRequest',
    as ArrayRef[GetTemplateRequest()];

coerce 'RepeatedGetTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::GetTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetTemplateRequest',
    as HashRef[GetTemplateRequest()];

declare 'TemplateView',
    as (Int | Str);

declare 'GetTemplateResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::GetTemplateResponse'];

coerce 'GetTemplateResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::GetTemplateResponse'->new($_) };

declare 'RepeatedGetTemplateResponse',
    as ArrayRef[GetTemplateResponse()];

coerce 'RepeatedGetTemplateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::GetTemplateResponse'->new($_) } @$_ ] };

declare 'MapStringGetTemplateResponse',
    as HashRef[GetTemplateResponse()];

declare 'TemplateType',
    as (Int | Str);

declare 'LaunchTemplateParameters',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters'];

coerce 'LaunchTemplateParameters',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters'->new($_) };

declare 'RepeatedLaunchTemplateParameters',
    as ArrayRef[LaunchTemplateParameters()];

coerce 'RepeatedLaunchTemplateParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters'->new($_) } @$_ ] };

declare 'MapStringLaunchTemplateParameters',
    as HashRef[LaunchTemplateParameters()];

declare 'ParametersEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'TransformNameMappingEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters::TransformNameMappingEntry'];

coerce 'TransformNameMappingEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters::TransformNameMappingEntry'->new($_) };

declare 'RepeatedTransformNameMappingEntry',
    as ArrayRef[TransformNameMappingEntry()];

coerce 'RepeatedTransformNameMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateParameters::TransformNameMappingEntry'->new($_) } @$_ ] };

declare 'MapStringTransformNameMappingEntry',
    as HashRef[TransformNameMappingEntry()];

declare 'LaunchTemplateRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchTemplateRequest'];

coerce 'LaunchTemplateRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateRequest'->new($_) };

declare 'RepeatedLaunchTemplateRequest',
    as ArrayRef[LaunchTemplateRequest()];

coerce 'RepeatedLaunchTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringLaunchTemplateRequest',
    as HashRef[LaunchTemplateRequest()];

declare 'LaunchTemplateResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse'];

coerce 'LaunchTemplateResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse'->new($_) };

declare 'RepeatedLaunchTemplateResponse',
    as ArrayRef[LaunchTemplateResponse()];

coerce 'RepeatedLaunchTemplateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse'->new($_) } @$_ ] };

declare 'MapStringLaunchTemplateResponse',
    as HashRef[LaunchTemplateResponse()];

declare 'InvalidTemplateParameters',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::InvalidTemplateParameters'];

coerce 'InvalidTemplateParameters',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::InvalidTemplateParameters'->new($_) };

declare 'RepeatedInvalidTemplateParameters',
    as ArrayRef[InvalidTemplateParameters()];

coerce 'RepeatedInvalidTemplateParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::InvalidTemplateParameters'->new($_) } @$_ ] };

declare 'MapStringInvalidTemplateParameters',
    as HashRef[InvalidTemplateParameters()];

declare 'ParameterViolation',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::InvalidTemplateParameters::ParameterViolation'];

coerce 'ParameterViolation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::InvalidTemplateParameters::ParameterViolation'->new($_) };

declare 'RepeatedParameterViolation',
    as ArrayRef[ParameterViolation()];

coerce 'RepeatedParameterViolation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::InvalidTemplateParameters::ParameterViolation'->new($_) } @$_ ] };

declare 'MapStringParameterViolation',
    as HashRef[ParameterViolation()];

declare 'DynamicTemplateLaunchParams',
    as InstanceOf['Google::Dataflow::V1beta3::Templates::DynamicTemplateLaunchParams'];

coerce 'DynamicTemplateLaunchParams',
    from HashRef, via { 'Google::Dataflow::V1beta3::Templates::DynamicTemplateLaunchParams'->new($_) };

declare 'RepeatedDynamicTemplateLaunchParams',
    as ArrayRef[DynamicTemplateLaunchParams()];

coerce 'RepeatedDynamicTemplateLaunchParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Templates::DynamicTemplateLaunchParams'->new($_) } @$_ ] };

declare 'MapStringDynamicTemplateLaunchParams',
    as HashRef[DynamicTemplateLaunchParams()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Templates::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
