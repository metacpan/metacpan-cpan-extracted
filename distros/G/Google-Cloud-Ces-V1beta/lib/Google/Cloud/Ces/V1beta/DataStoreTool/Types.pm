package Google::Cloud::Ces::V1beta::DataStoreTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataStoreTool',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool'];

coerce 'DataStoreTool',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool'->new($_) };

declare 'RepeatedDataStoreTool',
    as ArrayRef[DataStoreTool()];

coerce 'RepeatedDataStoreTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool'->new($_) } @$_ ] };

declare 'MapStringDataStoreTool',
    as HashRef[DataStoreTool()];

declare 'FilterParameterBehavior',
    as (Int | Str);

declare 'RewriterConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::RewriterConfig'];

coerce 'RewriterConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::RewriterConfig'->new($_) };

declare 'RepeatedRewriterConfig',
    as ArrayRef[RewriterConfig()];

coerce 'RepeatedRewriterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::RewriterConfig'->new($_) } @$_ ] };

declare 'MapStringRewriterConfig',
    as HashRef[RewriterConfig()];

declare 'SummarizationConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::SummarizationConfig'];

coerce 'SummarizationConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::SummarizationConfig'->new($_) };

declare 'RepeatedSummarizationConfig',
    as ArrayRef[SummarizationConfig()];

coerce 'RepeatedSummarizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::SummarizationConfig'->new($_) } @$_ ] };

declare 'MapStringSummarizationConfig',
    as HashRef[SummarizationConfig()];

declare 'GroundingConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::GroundingConfig'];

coerce 'GroundingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::GroundingConfig'->new($_) };

declare 'RepeatedGroundingConfig',
    as ArrayRef[GroundingConfig()];

coerce 'RepeatedGroundingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::GroundingConfig'->new($_) } @$_ ] };

declare 'MapStringGroundingConfig',
    as HashRef[GroundingConfig()];

declare 'DataStoreSource',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::DataStoreSource'];

coerce 'DataStoreSource',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::DataStoreSource'->new($_) };

declare 'RepeatedDataStoreSource',
    as ArrayRef[DataStoreSource()];

coerce 'RepeatedDataStoreSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::DataStoreSource'->new($_) } @$_ ] };

declare 'MapStringDataStoreSource',
    as HashRef[DataStoreSource()];

declare 'EngineSource',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::EngineSource'];

coerce 'EngineSource',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::EngineSource'->new($_) };

declare 'RepeatedEngineSource',
    as ArrayRef[EngineSource()];

coerce 'RepeatedEngineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::EngineSource'->new($_) } @$_ ] };

declare 'MapStringEngineSource',
    as HashRef[EngineSource()];

declare 'BoostSpecs',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpecs'];

coerce 'BoostSpecs',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpecs'->new($_) };

declare 'RepeatedBoostSpecs',
    as ArrayRef[BoostSpecs()];

coerce 'RepeatedBoostSpecs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpecs'->new($_) } @$_ ] };

declare 'MapStringBoostSpecs',
    as HashRef[BoostSpecs()];

declare 'BoostSpec',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec'];

coerce 'BoostSpec',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec'->new($_) };

declare 'RepeatedBoostSpec',
    as ArrayRef[BoostSpec()];

coerce 'RepeatedBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec'->new($_) } @$_ ] };

declare 'MapStringBoostSpec',
    as HashRef[BoostSpec()];

declare 'ConditionBoostSpec',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec'];

coerce 'ConditionBoostSpec',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec'->new($_) };

declare 'RepeatedConditionBoostSpec',
    as ArrayRef[ConditionBoostSpec()];

coerce 'RepeatedConditionBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec'->new($_) } @$_ ] };

declare 'MapStringConditionBoostSpec',
    as HashRef[ConditionBoostSpec()];

declare 'BoostControlSpec',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec::BoostControlSpec'];

coerce 'BoostControlSpec',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) };

declare 'RepeatedBoostControlSpec',
    as ArrayRef[BoostControlSpec()];

coerce 'RepeatedBoostControlSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) } @$_ ] };

declare 'MapStringBoostControlSpec',
    as HashRef[BoostControlSpec()];

declare 'AttributeType',
    as (Int | Str);

declare 'InterpolationType',
    as (Int | Str);

declare 'ControlPoint',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'];

coerce 'ControlPoint',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) };

declare 'RepeatedControlPoint',
    as ArrayRef[ControlPoint()];

coerce 'RepeatedControlPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) } @$_ ] };

declare 'MapStringControlPoint',
    as HashRef[ControlPoint()];

declare 'SnippetsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::SnippetsConfig'];

coerce 'SnippetsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::SnippetsConfig'->new($_) };

declare 'RepeatedSnippetsConfig',
    as ArrayRef[SnippetsConfig()];

coerce 'RepeatedSnippetsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::SnippetsConfig'->new($_) } @$_ ] };

declare 'MapStringSnippetsConfig',
    as HashRef[SnippetsConfig()];

declare 'ModalityConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::ModalityConfig'];

coerce 'ModalityConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::ModalityConfig'->new($_) };

declare 'RepeatedModalityConfig',
    as ArrayRef[ModalityConfig()];

coerce 'RepeatedModalityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::DataStoreTool::DataStoreTool::ModalityConfig'->new($_) } @$_ ] };

declare 'MapStringModalityConfig',
    as HashRef[ModalityConfig()];

declare 'ModalityType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::DataStoreTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
