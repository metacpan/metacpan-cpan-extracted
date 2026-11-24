package Google::Cloud::Apihub::V1::CommonFields::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LintState',
    as (Int | Str);

declare 'Linter',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'AuthType',
    as (Int | Str);

declare 'PluginCategory',
    as (Int | Str);

declare 'Api',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Api'];

coerce 'Api',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Api'->new($_) };

declare 'RepeatedApi',
    as ArrayRef[Api()];

coerce 'RepeatedApi',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Api'->new($_) } @$_ ] };

declare 'MapStringApi',
    as HashRef[Api()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Api::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Api::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Api::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Version',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Version::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Version::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Version::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Spec',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Spec'];

coerce 'Spec',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Spec'->new($_) };

declare 'RepeatedSpec',
    as ArrayRef[Spec()];

coerce 'RepeatedSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Spec'->new($_) } @$_ ] };

declare 'MapStringSpec',
    as HashRef[Spec()];

declare 'ParsingMode',
    as (Int | Str);

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Spec::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Spec::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Spec::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Deployment',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Deployment::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Deployment::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Deployment::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'ApiOperation',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ApiOperation'];

coerce 'ApiOperation',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ApiOperation'->new($_) };

declare 'RepeatedApiOperation',
    as ArrayRef[ApiOperation()];

coerce 'RepeatedApiOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ApiOperation'->new($_) } @$_ ] };

declare 'MapStringApiOperation',
    as HashRef[ApiOperation()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ApiOperation::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ApiOperation::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ApiOperation::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Definition',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Definition'];

coerce 'Definition',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Definition'->new($_) };

declare 'RepeatedDefinition',
    as ArrayRef[Definition()];

coerce 'RepeatedDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Definition'->new($_) } @$_ ] };

declare 'MapStringDefinition',
    as HashRef[Definition()];

declare 'Type',
    as (Int | Str);

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Definition::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Definition::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Definition::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'Attribute',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Attribute'];

coerce 'Attribute',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Attribute'->new($_) };

declare 'RepeatedAttribute',
    as ArrayRef[Attribute()];

coerce 'RepeatedAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Attribute'->new($_) } @$_ ] };

declare 'MapStringAttribute',
    as HashRef[Attribute()];

declare 'DefinitionType',
    as (Int | Str);

declare 'Scope',
    as (Int | Str);

declare 'DataType',
    as (Int | Str);

declare 'AllowedValue',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Attribute::AllowedValue'];

coerce 'AllowedValue',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Attribute::AllowedValue'->new($_) };

declare 'RepeatedAllowedValue',
    as ArrayRef[AllowedValue()];

coerce 'RepeatedAllowedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Attribute::AllowedValue'->new($_) } @$_ ] };

declare 'MapStringAllowedValue',
    as HashRef[AllowedValue()];

declare 'SpecContents',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::SpecContents'];

coerce 'SpecContents',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::SpecContents'->new($_) };

declare 'RepeatedSpecContents',
    as ArrayRef[SpecContents()];

coerce 'RepeatedSpecContents',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::SpecContents'->new($_) } @$_ ] };

declare 'MapStringSpecContents',
    as HashRef[SpecContents()];

declare 'SpecDetails',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::SpecDetails'];

coerce 'SpecDetails',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::SpecDetails'->new($_) };

declare 'RepeatedSpecDetails',
    as ArrayRef[SpecDetails()];

coerce 'RepeatedSpecDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::SpecDetails'->new($_) } @$_ ] };

declare 'MapStringSpecDetails',
    as HashRef[SpecDetails()];

declare 'OpenApiSpecDetails',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::OpenApiSpecDetails'];

coerce 'OpenApiSpecDetails',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::OpenApiSpecDetails'->new($_) };

declare 'RepeatedOpenApiSpecDetails',
    as ArrayRef[OpenApiSpecDetails()];

coerce 'RepeatedOpenApiSpecDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::OpenApiSpecDetails'->new($_) } @$_ ] };

declare 'MapStringOpenApiSpecDetails',
    as HashRef[OpenApiSpecDetails()];

declare 'Format',
    as (Int | Str);

declare 'OperationDetails',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::OperationDetails'];

coerce 'OperationDetails',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::OperationDetails'->new($_) };

declare 'RepeatedOperationDetails',
    as ArrayRef[OperationDetails()];

coerce 'RepeatedOperationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::OperationDetails'->new($_) } @$_ ] };

declare 'MapStringOperationDetails',
    as HashRef[OperationDetails()];

declare 'HttpOperation',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperation'];

coerce 'HttpOperation',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperation'->new($_) };

declare 'RepeatedHttpOperation',
    as ArrayRef[HttpOperation()];

coerce 'RepeatedHttpOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperation'->new($_) } @$_ ] };

declare 'MapStringHttpOperation',
    as HashRef[HttpOperation()];

declare 'Method',
    as (Int | Str);

declare 'Path',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Path'];

coerce 'Path',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Path'->new($_) };

declare 'RepeatedPath',
    as ArrayRef[Path()];

coerce 'RepeatedPath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Path'->new($_) } @$_ ] };

declare 'MapStringPath',
    as HashRef[Path()];

declare 'Schema',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'Owner',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Owner'];

coerce 'Owner',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Owner'->new($_) };

declare 'RepeatedOwner',
    as ArrayRef[Owner()];

coerce 'RepeatedOwner',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Owner'->new($_) } @$_ ] };

declare 'MapStringOwner',
    as HashRef[Owner()];

declare 'Documentation',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Documentation'];

coerce 'Documentation',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Documentation'->new($_) };

declare 'RepeatedDocumentation',
    as ArrayRef[Documentation()];

coerce 'RepeatedDocumentation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Documentation'->new($_) } @$_ ] };

declare 'MapStringDocumentation',
    as HashRef[Documentation()];

declare 'AttributeValues',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AttributeValues'];

coerce 'AttributeValues',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AttributeValues'->new($_) };

declare 'RepeatedAttributeValues',
    as ArrayRef[AttributeValues()];

coerce 'RepeatedAttributeValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AttributeValues'->new($_) } @$_ ] };

declare 'MapStringAttributeValues',
    as HashRef[AttributeValues()];

declare 'EnumAttributeValues',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AttributeValues::EnumAttributeValues'];

coerce 'EnumAttributeValues',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AttributeValues::EnumAttributeValues'->new($_) };

declare 'RepeatedEnumAttributeValues',
    as ArrayRef[EnumAttributeValues()];

coerce 'RepeatedEnumAttributeValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AttributeValues::EnumAttributeValues'->new($_) } @$_ ] };

declare 'MapStringEnumAttributeValues',
    as HashRef[EnumAttributeValues()];

declare 'StringAttributeValues',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AttributeValues::StringAttributeValues'];

coerce 'StringAttributeValues',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AttributeValues::StringAttributeValues'->new($_) };

declare 'RepeatedStringAttributeValues',
    as ArrayRef[StringAttributeValues()];

coerce 'RepeatedStringAttributeValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AttributeValues::StringAttributeValues'->new($_) } @$_ ] };

declare 'MapStringStringAttributeValues',
    as HashRef[StringAttributeValues()];

declare 'Dependency',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Dependency'];

coerce 'Dependency',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Dependency'->new($_) };

declare 'RepeatedDependency',
    as ArrayRef[Dependency()];

coerce 'RepeatedDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Dependency'->new($_) } @$_ ] };

declare 'MapStringDependency',
    as HashRef[Dependency()];

declare 'State',
    as (Int | Str);

declare 'DiscoveryMode',
    as (Int | Str);

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Dependency::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Dependency::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Dependency::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'DependencyEntityReference',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::DependencyEntityReference'];

coerce 'DependencyEntityReference',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::DependencyEntityReference'->new($_) };

declare 'RepeatedDependencyEntityReference',
    as ArrayRef[DependencyEntityReference()];

coerce 'RepeatedDependencyEntityReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::DependencyEntityReference'->new($_) } @$_ ] };

declare 'MapStringDependencyEntityReference',
    as HashRef[DependencyEntityReference()];

declare 'DependencyErrorDetail',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::DependencyErrorDetail'];

coerce 'DependencyErrorDetail',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::DependencyErrorDetail'->new($_) };

declare 'RepeatedDependencyErrorDetail',
    as ArrayRef[DependencyErrorDetail()];

coerce 'RepeatedDependencyErrorDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::DependencyErrorDetail'->new($_) } @$_ ] };

declare 'MapStringDependencyErrorDetail',
    as HashRef[DependencyErrorDetail()];

declare 'Error',
    as (Int | Str);

declare 'LintResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::LintResponse'];

coerce 'LintResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::LintResponse'->new($_) };

declare 'RepeatedLintResponse',
    as ArrayRef[LintResponse()];

coerce 'RepeatedLintResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::LintResponse'->new($_) } @$_ ] };

declare 'MapStringLintResponse',
    as HashRef[LintResponse()];

declare 'SummaryEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::LintResponse::SummaryEntry'];

coerce 'SummaryEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::LintResponse::SummaryEntry'->new($_) };

declare 'RepeatedSummaryEntry',
    as ArrayRef[SummaryEntry()];

coerce 'RepeatedSummaryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::LintResponse::SummaryEntry'->new($_) } @$_ ] };

declare 'MapStringSummaryEntry',
    as HashRef[SummaryEntry()];

declare 'Issue',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Issue'];

coerce 'Issue',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Issue'->new($_) };

declare 'RepeatedIssue',
    as ArrayRef[Issue()];

coerce 'RepeatedIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Issue'->new($_) } @$_ ] };

declare 'MapStringIssue',
    as HashRef[Issue()];

declare 'Range',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'Point',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Point'];

coerce 'Point',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Point'->new($_) };

declare 'RepeatedPoint',
    as ArrayRef[Point()];

coerce 'RepeatedPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Point'->new($_) } @$_ ] };

declare 'MapStringPoint',
    as HashRef[Point()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ApiHubInstance',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance'];

coerce 'ApiHubInstance',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance'->new($_) };

declare 'RepeatedApiHubInstance',
    as ArrayRef[ApiHubInstance()];

coerce 'RepeatedApiHubInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance'->new($_) } @$_ ] };

declare 'MapStringApiHubInstance',
    as HashRef[ApiHubInstance()];

declare 'State',
    as (Int | Str);

declare 'Config',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'EncryptionType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ApiHubInstance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExternalApi',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ExternalApi'];

coerce 'ExternalApi',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ExternalApi'->new($_) };

declare 'RepeatedExternalApi',
    as ArrayRef[ExternalApi()];

coerce 'RepeatedExternalApi',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ExternalApi'->new($_) } @$_ ] };

declare 'MapStringExternalApi',
    as HashRef[ExternalApi()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ExternalApi::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ExternalApi::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ExternalApi::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'ConfigValueOption',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ConfigValueOption'];

coerce 'ConfigValueOption',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ConfigValueOption'->new($_) };

declare 'RepeatedConfigValueOption',
    as ArrayRef[ConfigValueOption()];

coerce 'RepeatedConfigValueOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ConfigValueOption'->new($_) } @$_ ] };

declare 'MapStringConfigValueOption',
    as HashRef[ConfigValueOption()];

declare 'Secret',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'ConfigVariableTemplate',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ConfigVariableTemplate'];

coerce 'ConfigVariableTemplate',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariableTemplate'->new($_) };

declare 'RepeatedConfigVariableTemplate',
    as ArrayRef[ConfigVariableTemplate()];

coerce 'RepeatedConfigVariableTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariableTemplate'->new($_) } @$_ ] };

declare 'MapStringConfigVariableTemplate',
    as HashRef[ConfigVariableTemplate()];

declare 'ValueType',
    as (Int | Str);

declare 'ConfigVariable',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ConfigVariable'];

coerce 'ConfigVariable',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable'->new($_) };

declare 'RepeatedConfigVariable',
    as ArrayRef[ConfigVariable()];

coerce 'RepeatedConfigVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable'->new($_) } @$_ ] };

declare 'MapStringConfigVariable',
    as HashRef[ConfigVariable()];

declare 'MultiSelectValues',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiSelectValues'];

coerce 'MultiSelectValues',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiSelectValues'->new($_) };

declare 'RepeatedMultiSelectValues',
    as ArrayRef[MultiSelectValues()];

coerce 'RepeatedMultiSelectValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiSelectValues'->new($_) } @$_ ] };

declare 'MapStringMultiSelectValues',
    as HashRef[MultiSelectValues()];

declare 'MultiStringValues',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiStringValues'];

coerce 'MultiStringValues',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiStringValues'->new($_) };

declare 'RepeatedMultiStringValues',
    as ArrayRef[MultiStringValues()];

coerce 'RepeatedMultiStringValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiStringValues'->new($_) } @$_ ] };

declare 'MapStringMultiStringValues',
    as HashRef[MultiStringValues()];

declare 'MultiIntValues',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiIntValues'];

coerce 'MultiIntValues',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiIntValues'->new($_) };

declare 'RepeatedMultiIntValues',
    as ArrayRef[MultiIntValues()];

coerce 'RepeatedMultiIntValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::ConfigVariable::MultiIntValues'->new($_) } @$_ ] };

declare 'MapStringMultiIntValues',
    as HashRef[MultiIntValues()];

declare 'GoogleServiceAccountConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::GoogleServiceAccountConfig'];

coerce 'GoogleServiceAccountConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::GoogleServiceAccountConfig'->new($_) };

declare 'RepeatedGoogleServiceAccountConfig',
    as ArrayRef[GoogleServiceAccountConfig()];

coerce 'RepeatedGoogleServiceAccountConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::GoogleServiceAccountConfig'->new($_) } @$_ ] };

declare 'MapStringGoogleServiceAccountConfig',
    as HashRef[GoogleServiceAccountConfig()];

declare 'AuthConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AuthConfig'];

coerce 'AuthConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig'->new($_) };

declare 'RepeatedAuthConfig',
    as ArrayRef[AuthConfig()];

coerce 'RepeatedAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig'->new($_) } @$_ ] };

declare 'MapStringAuthConfig',
    as HashRef[AuthConfig()];

declare 'UserPasswordConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AuthConfig::UserPasswordConfig'];

coerce 'UserPasswordConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig::UserPasswordConfig'->new($_) };

declare 'RepeatedUserPasswordConfig',
    as ArrayRef[UserPasswordConfig()];

coerce 'RepeatedUserPasswordConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig::UserPasswordConfig'->new($_) } @$_ ] };

declare 'MapStringUserPasswordConfig',
    as HashRef[UserPasswordConfig()];

declare 'Oauth2ClientCredentialsConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AuthConfig::Oauth2ClientCredentialsConfig'];

coerce 'Oauth2ClientCredentialsConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig::Oauth2ClientCredentialsConfig'->new($_) };

declare 'RepeatedOauth2ClientCredentialsConfig',
    as ArrayRef[Oauth2ClientCredentialsConfig()];

coerce 'RepeatedOauth2ClientCredentialsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig::Oauth2ClientCredentialsConfig'->new($_) } @$_ ] };

declare 'MapStringOauth2ClientCredentialsConfig',
    as HashRef[Oauth2ClientCredentialsConfig()];

declare 'ApiKeyConfig',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::AuthConfig::ApiKeyConfig'];

coerce 'ApiKeyConfig',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig::ApiKeyConfig'->new($_) };

declare 'RepeatedApiKeyConfig',
    as ArrayRef[ApiKeyConfig()];

coerce 'RepeatedApiKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::AuthConfig::ApiKeyConfig'->new($_) } @$_ ] };

declare 'MapStringApiKeyConfig',
    as HashRef[ApiKeyConfig()];

declare 'HttpElementLocation',
    as (Int | Str);

declare 'SourceMetadata',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::SourceMetadata'];

coerce 'SourceMetadata',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::SourceMetadata'->new($_) };

declare 'RepeatedSourceMetadata',
    as ArrayRef[SourceMetadata()];

coerce 'RepeatedSourceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::SourceMetadata'->new($_) } @$_ ] };

declare 'MapStringSourceMetadata',
    as HashRef[SourceMetadata()];

declare 'SourceType',
    as (Int | Str);

declare 'PluginInstanceActionSource',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::SourceMetadata::PluginInstanceActionSource'];

coerce 'PluginInstanceActionSource',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::SourceMetadata::PluginInstanceActionSource'->new($_) };

declare 'RepeatedPluginInstanceActionSource',
    as ArrayRef[PluginInstanceActionSource()];

coerce 'RepeatedPluginInstanceActionSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::SourceMetadata::PluginInstanceActionSource'->new($_) } @$_ ] };

declare 'MapStringPluginInstanceActionSource',
    as HashRef[PluginInstanceActionSource()];

declare 'DiscoveredApiObservation',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiObservation'];

coerce 'DiscoveredApiObservation',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiObservation'->new($_) };

declare 'RepeatedDiscoveredApiObservation',
    as ArrayRef[DiscoveredApiObservation()];

coerce 'RepeatedDiscoveredApiObservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiObservation'->new($_) } @$_ ] };

declare 'MapStringDiscoveredApiObservation',
    as HashRef[DiscoveredApiObservation()];

declare 'Style',
    as (Int | Str);

declare 'SourceType',
    as (Int | Str);

declare 'DiscoveredApiOperation',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation'];

coerce 'DiscoveredApiOperation',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation'->new($_) };

declare 'RepeatedDiscoveredApiOperation',
    as ArrayRef[DiscoveredApiOperation()];

coerce 'RepeatedDiscoveredApiOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation'->new($_) } @$_ ] };

declare 'MapStringDiscoveredApiOperation',
    as HashRef[DiscoveredApiOperation()];

declare 'Classification',
    as (Int | Str);

declare 'MatchResult',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation::MatchResult'];

coerce 'MatchResult',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation::MatchResult'->new($_) };

declare 'RepeatedMatchResult',
    as ArrayRef[MatchResult()];

coerce 'RepeatedMatchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::DiscoveredApiOperation::MatchResult'->new($_) } @$_ ] };

declare 'MapStringMatchResult',
    as HashRef[MatchResult()];

declare 'HttpOperationDetails',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails'];

coerce 'HttpOperationDetails',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails'->new($_) };

declare 'RepeatedHttpOperationDetails',
    as ArrayRef[HttpOperationDetails()];

coerce 'RepeatedHttpOperationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails'->new($_) } @$_ ] };

declare 'MapStringHttpOperationDetails',
    as HashRef[HttpOperationDetails()];

declare 'DataType',
    as (Int | Str);

declare 'PathParam',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::PathParam'];

coerce 'PathParam',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::PathParam'->new($_) };

declare 'RepeatedPathParam',
    as ArrayRef[PathParam()];

coerce 'RepeatedPathParam',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::PathParam'->new($_) } @$_ ] };

declare 'MapStringPathParam',
    as HashRef[PathParam()];

declare 'QueryParam',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::QueryParam'];

coerce 'QueryParam',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::QueryParam'->new($_) };

declare 'RepeatedQueryParam',
    as ArrayRef[QueryParam()];

coerce 'RepeatedQueryParam',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::QueryParam'->new($_) } @$_ ] };

declare 'MapStringQueryParam',
    as HashRef[QueryParam()];

declare 'Header',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::Header'];

coerce 'Header',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::Header'->new($_) };

declare 'RepeatedHeader',
    as ArrayRef[Header()];

coerce 'RepeatedHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::Header'->new($_) } @$_ ] };

declare 'MapStringHeader',
    as HashRef[Header()];

declare 'HttpRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpRequest'];

coerce 'HttpRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpRequest'->new($_) };

declare 'RepeatedHttpRequest',
    as ArrayRef[HttpRequest()];

coerce 'RepeatedHttpRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpRequest'->new($_) } @$_ ] };

declare 'MapStringHttpRequest',
    as HashRef[HttpRequest()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpRequest::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpRequest::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpRequest::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'HttpResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse'];

coerce 'HttpResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse'->new($_) };

declare 'RepeatedHttpResponse',
    as ArrayRef[HttpResponse()];

coerce 'RepeatedHttpResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse'->new($_) } @$_ ] };

declare 'MapStringHttpResponse',
    as HashRef[HttpResponse()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'ResponseCodesEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse::ResponseCodesEntry'];

coerce 'ResponseCodesEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse::ResponseCodesEntry'->new($_) };

declare 'RepeatedResponseCodesEntry',
    as ArrayRef[ResponseCodesEntry()];

coerce 'RepeatedResponseCodesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::HttpResponse::ResponseCodesEntry'->new($_) } @$_ ] };

declare 'MapStringResponseCodesEntry',
    as HashRef[ResponseCodesEntry()];

declare 'QueryParamsEntry',
    as InstanceOf['Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::QueryParamsEntry'];

coerce 'QueryParamsEntry',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::QueryParamsEntry'->new($_) };

declare 'RepeatedQueryParamsEntry',
    as ArrayRef[QueryParamsEntry()];

coerce 'RepeatedQueryParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CommonFields::HttpOperationDetails::QueryParamsEntry'->new($_) } @$_ ] };

declare 'MapStringQueryParamsEntry',
    as HashRef[QueryParamsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::CommonFields::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
