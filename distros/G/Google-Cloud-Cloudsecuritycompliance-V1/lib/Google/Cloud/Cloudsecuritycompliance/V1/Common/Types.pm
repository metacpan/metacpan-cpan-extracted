package Google::Cloud::Cloudsecuritycompliance::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RegulatoryControlResponsibilityType',
    as (Int | Str);

declare 'EnforcementMode',
    as (Int | Str);

declare 'FrameworkCategory',
    as (Int | Str);

declare 'CloudControlCategory',
    as (Int | Str);

declare 'CloudProvider',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'RuleActionType',
    as (Int | Str);

declare 'TargetResourceType',
    as (Int | Str);

declare 'Framework',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework'];

coerce 'Framework',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework'->new($_) };

declare 'RepeatedFramework',
    as ArrayRef[Framework()];

coerce 'RepeatedFramework',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Framework'->new($_) } @$_ ] };

declare 'MapStringFramework',
    as HashRef[Framework()];

declare 'FrameworkType',
    as (Int | Str);

declare 'CloudControlDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControlDetails'];

coerce 'CloudControlDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControlDetails'->new($_) };

declare 'RepeatedCloudControlDetails',
    as ArrayRef[CloudControlDetails()];

coerce 'RepeatedCloudControlDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControlDetails'->new($_) } @$_ ] };

declare 'MapStringCloudControlDetails',
    as HashRef[CloudControlDetails()];

declare 'FrameworkReference',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::FrameworkReference'];

coerce 'FrameworkReference',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::FrameworkReference'->new($_) };

declare 'RepeatedFrameworkReference',
    as ArrayRef[FrameworkReference()];

coerce 'RepeatedFrameworkReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::FrameworkReference'->new($_) } @$_ ] };

declare 'MapStringFrameworkReference',
    as HashRef[FrameworkReference()];

declare 'Parameter',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'CloudControl',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl'];

coerce 'CloudControl',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl'->new($_) };

declare 'RepeatedCloudControl',
    as ArrayRef[CloudControl()];

coerce 'RepeatedCloudControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CloudControl'->new($_) } @$_ ] };

declare 'MapStringCloudControl',
    as HashRef[CloudControl()];

declare 'Type',
    as (Int | Str);

declare 'ParameterSpec',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::ParameterSpec'];

coerce 'ParameterSpec',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ParameterSpec'->new($_) };

declare 'RepeatedParameterSpec',
    as ArrayRef[ParameterSpec()];

coerce 'RepeatedParameterSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ParameterSpec'->new($_) } @$_ ] };

declare 'MapStringParameterSpec',
    as HashRef[ParameterSpec()];

declare 'ValueType',
    as (Int | Str);

declare 'Validation',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::Validation'];

coerce 'Validation',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Validation'->new($_) };

declare 'RepeatedValidation',
    as ArrayRef[Validation()];

coerce 'RepeatedValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Validation'->new($_) } @$_ ] };

declare 'MapStringValidation',
    as HashRef[Validation()];

declare 'AllowedValues',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::AllowedValues'];

coerce 'AllowedValues',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::AllowedValues'->new($_) };

declare 'RepeatedAllowedValues',
    as ArrayRef[AllowedValues()];

coerce 'RepeatedAllowedValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::AllowedValues'->new($_) } @$_ ] };

declare 'MapStringAllowedValues',
    as HashRef[AllowedValues()];

declare 'RegexpPattern',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::RegexpPattern'];

coerce 'RegexpPattern',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::RegexpPattern'->new($_) };

declare 'RepeatedRegexpPattern',
    as ArrayRef[RegexpPattern()];

coerce 'RepeatedRegexpPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::RegexpPattern'->new($_) } @$_ ] };

declare 'MapStringRegexpPattern',
    as HashRef[RegexpPattern()];

declare 'IntRange',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::IntRange'];

coerce 'IntRange',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::IntRange'->new($_) };

declare 'RepeatedIntRange',
    as ArrayRef[IntRange()];

coerce 'RepeatedIntRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::IntRange'->new($_) } @$_ ] };

declare 'MapStringIntRange',
    as HashRef[IntRange()];

declare 'StringList',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::StringList'];

coerce 'StringList',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::StringList'->new($_) };

declare 'RepeatedStringList',
    as ArrayRef[StringList()];

coerce 'RepeatedStringList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::StringList'->new($_) } @$_ ] };

declare 'MapStringStringList',
    as HashRef[StringList()];

declare 'ParamValue',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::ParamValue'];

coerce 'ParamValue',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ParamValue'->new($_) };

declare 'RepeatedParamValue',
    as ArrayRef[ParamValue()];

coerce 'RepeatedParamValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ParamValue'->new($_) } @$_ ] };

declare 'MapStringParamValue',
    as HashRef[ParamValue()];

declare 'ParameterSubstitutionRule',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::ParameterSubstitutionRule'];

coerce 'ParameterSubstitutionRule',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ParameterSubstitutionRule'->new($_) };

declare 'RepeatedParameterSubstitutionRule',
    as ArrayRef[ParameterSubstitutionRule()];

coerce 'RepeatedParameterSubstitutionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ParameterSubstitutionRule'->new($_) } @$_ ] };

declare 'MapStringParameterSubstitutionRule',
    as HashRef[ParameterSubstitutionRule()];

declare 'AttributeSubstitutionRule',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::AttributeSubstitutionRule'];

coerce 'AttributeSubstitutionRule',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::AttributeSubstitutionRule'->new($_) };

declare 'RepeatedAttributeSubstitutionRule',
    as ArrayRef[AttributeSubstitutionRule()];

coerce 'RepeatedAttributeSubstitutionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::AttributeSubstitutionRule'->new($_) } @$_ ] };

declare 'MapStringAttributeSubstitutionRule',
    as HashRef[AttributeSubstitutionRule()];

declare 'PlaceholderSubstitutionRule',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::PlaceholderSubstitutionRule'];

coerce 'PlaceholderSubstitutionRule',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::PlaceholderSubstitutionRule'->new($_) };

declare 'RepeatedPlaceholderSubstitutionRule',
    as ArrayRef[PlaceholderSubstitutionRule()];

coerce 'RepeatedPlaceholderSubstitutionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::PlaceholderSubstitutionRule'->new($_) } @$_ ] };

declare 'MapStringPlaceholderSubstitutionRule',
    as HashRef[PlaceholderSubstitutionRule()];

declare 'Rule',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'CELExpression',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::CELExpression'];

coerce 'CELExpression',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CELExpression'->new($_) };

declare 'RepeatedCELExpression',
    as ArrayRef[CELExpression()];

coerce 'RepeatedCELExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::CELExpression'->new($_) } @$_ ] };

declare 'MapStringCELExpression',
    as HashRef[CELExpression()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Control',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::Control'];

coerce 'Control',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Control'->new($_) };

declare 'RepeatedControl',
    as ArrayRef[Control()];

coerce 'RepeatedControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::Control'->new($_) } @$_ ] };

declare 'MapStringControl',
    as HashRef[Control()];

declare 'Family',
    as (Int | Str);

declare 'ControlFamily',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Common::ControlFamily'];

coerce 'ControlFamily',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ControlFamily'->new($_) };

declare 'RepeatedControlFamily',
    as ArrayRef[ControlFamily()];

coerce 'RepeatedControlFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Common::ControlFamily'->new($_) } @$_ ] };

declare 'MapStringControlFamily',
    as HashRef[ControlFamily()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
