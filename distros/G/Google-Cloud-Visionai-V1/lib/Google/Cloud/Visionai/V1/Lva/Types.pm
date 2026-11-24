package Google::Cloud::Visionai::V1::Lva::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunMode',
    as (Int | Str);

declare 'OperatorDefinition',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::OperatorDefinition'];

coerce 'OperatorDefinition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::OperatorDefinition'->new($_) };

declare 'RepeatedOperatorDefinition',
    as ArrayRef[OperatorDefinition()];

coerce 'RepeatedOperatorDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::OperatorDefinition'->new($_) } @$_ ] };

declare 'MapStringOperatorDefinition',
    as HashRef[OperatorDefinition()];

declare 'ArgumentDefinition',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::OperatorDefinition::ArgumentDefinition'];

coerce 'ArgumentDefinition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::OperatorDefinition::ArgumentDefinition'->new($_) };

declare 'RepeatedArgumentDefinition',
    as ArrayRef[ArgumentDefinition()];

coerce 'RepeatedArgumentDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::OperatorDefinition::ArgumentDefinition'->new($_) } @$_ ] };

declare 'MapStringArgumentDefinition',
    as HashRef[ArgumentDefinition()];

declare 'AttributeDefinition',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::OperatorDefinition::AttributeDefinition'];

coerce 'AttributeDefinition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::OperatorDefinition::AttributeDefinition'->new($_) };

declare 'RepeatedAttributeDefinition',
    as ArrayRef[AttributeDefinition()];

coerce 'RepeatedAttributeDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::OperatorDefinition::AttributeDefinition'->new($_) } @$_ ] };

declare 'MapStringAttributeDefinition',
    as HashRef[AttributeDefinition()];

declare 'ResourceSpecification',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::ResourceSpecification'];

coerce 'ResourceSpecification',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::ResourceSpecification'->new($_) };

declare 'RepeatedResourceSpecification',
    as ArrayRef[ResourceSpecification()];

coerce 'RepeatedResourceSpecification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::ResourceSpecification'->new($_) } @$_ ] };

declare 'MapStringResourceSpecification',
    as HashRef[ResourceSpecification()];

declare 'AttributeValue',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AttributeValue'];

coerce 'AttributeValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AttributeValue'->new($_) };

declare 'RepeatedAttributeValue',
    as ArrayRef[AttributeValue()];

coerce 'RepeatedAttributeValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AttributeValue'->new($_) } @$_ ] };

declare 'MapStringAttributeValue',
    as HashRef[AttributeValue()];

declare 'AnalyzerDefinition',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition'];

coerce 'AnalyzerDefinition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition'->new($_) };

declare 'RepeatedAnalyzerDefinition',
    as ArrayRef[AnalyzerDefinition()];

coerce 'RepeatedAnalyzerDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition'->new($_) } @$_ ] };

declare 'MapStringAnalyzerDefinition',
    as HashRef[AnalyzerDefinition()];

declare 'StreamInput',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::StreamInput'];

coerce 'StreamInput',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::StreamInput'->new($_) };

declare 'RepeatedStreamInput',
    as ArrayRef[StreamInput()];

coerce 'RepeatedStreamInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::StreamInput'->new($_) } @$_ ] };

declare 'MapStringStreamInput',
    as HashRef[StreamInput()];

declare 'DebugOptions',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions'];

coerce 'DebugOptions',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions'->new($_) };

declare 'RepeatedDebugOptions',
    as ArrayRef[DebugOptions()];

coerce 'RepeatedDebugOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions'->new($_) } @$_ ] };

declare 'MapStringDebugOptions',
    as HashRef[DebugOptions()];

declare 'EnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions::EnvironmentVariablesEntry'];

coerce 'EnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions::EnvironmentVariablesEntry'->new($_) };

declare 'RepeatedEnvironmentVariablesEntry',
    as ArrayRef[EnvironmentVariablesEntry()];

coerce 'RepeatedEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::DebugOptions::EnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariablesEntry',
    as HashRef[EnvironmentVariablesEntry()];

declare 'OperatorOption',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::OperatorOption'];

coerce 'OperatorOption',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::OperatorOption'->new($_) };

declare 'RepeatedOperatorOption',
    as ArrayRef[OperatorOption()];

coerce 'RepeatedOperatorOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::OperatorOption'->new($_) } @$_ ] };

declare 'MapStringOperatorOption',
    as HashRef[OperatorOption()];

declare 'AttrsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::AttrsEntry'];

coerce 'AttrsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::AttrsEntry'->new($_) };

declare 'RepeatedAttrsEntry',
    as ArrayRef[AttrsEntry()];

coerce 'RepeatedAttrsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalyzerDefinition::AttrsEntry'->new($_) } @$_ ] };

declare 'MapStringAttrsEntry',
    as HashRef[AttrsEntry()];

declare 'AnalysisDefinition',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::AnalysisDefinition'];

coerce 'AnalysisDefinition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::AnalysisDefinition'->new($_) };

declare 'RepeatedAnalysisDefinition',
    as ArrayRef[AnalysisDefinition()];

coerce 'RepeatedAnalysisDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::AnalysisDefinition'->new($_) } @$_ ] };

declare 'MapStringAnalysisDefinition',
    as HashRef[AnalysisDefinition()];

declare 'RunStatus',
    as InstanceOf['Google::Cloud::Visionai::V1::Lva::RunStatus'];

coerce 'RunStatus',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Lva::RunStatus'->new($_) };

declare 'RepeatedRunStatus',
    as ArrayRef[RunStatus()];

coerce 'RepeatedRunStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Lva::RunStatus'->new($_) } @$_ ] };

declare 'MapStringRunStatus',
    as HashRef[RunStatus()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::Lva::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
