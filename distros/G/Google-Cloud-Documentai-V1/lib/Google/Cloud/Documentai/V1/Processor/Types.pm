package Google::Cloud::Documentai::V1::Processor::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProcessorVersion',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::ProcessorVersion'];

coerce 'ProcessorVersion',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion'->new($_) };

declare 'RepeatedProcessorVersion',
    as ArrayRef[ProcessorVersion()];

coerce 'RepeatedProcessorVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion'->new($_) } @$_ ] };

declare 'MapStringProcessorVersion',
    as HashRef[ProcessorVersion()];

declare 'State',
    as (Int | Str);

declare 'ModelType',
    as (Int | Str);

declare 'DeprecationInfo',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::ProcessorVersion::DeprecationInfo'];

coerce 'DeprecationInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::DeprecationInfo'->new($_) };

declare 'RepeatedDeprecationInfo',
    as ArrayRef[DeprecationInfo()];

coerce 'RepeatedDeprecationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::DeprecationInfo'->new($_) } @$_ ] };

declare 'MapStringDeprecationInfo',
    as HashRef[DeprecationInfo()];

declare 'GenAiModelInfo',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo'];

coerce 'GenAiModelInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo'->new($_) };

declare 'RepeatedGenAiModelInfo',
    as ArrayRef[GenAiModelInfo()];

coerce 'RepeatedGenAiModelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo'->new($_) } @$_ ] };

declare 'MapStringGenAiModelInfo',
    as HashRef[GenAiModelInfo()];

declare 'FoundationGenAiModelInfo',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo::FoundationGenAiModelInfo'];

coerce 'FoundationGenAiModelInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo::FoundationGenAiModelInfo'->new($_) };

declare 'RepeatedFoundationGenAiModelInfo',
    as ArrayRef[FoundationGenAiModelInfo()];

coerce 'RepeatedFoundationGenAiModelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo::FoundationGenAiModelInfo'->new($_) } @$_ ] };

declare 'MapStringFoundationGenAiModelInfo',
    as HashRef[FoundationGenAiModelInfo()];

declare 'CustomGenAiModelInfo',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo::CustomGenAiModelInfo'];

coerce 'CustomGenAiModelInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo::CustomGenAiModelInfo'->new($_) };

declare 'RepeatedCustomGenAiModelInfo',
    as ArrayRef[CustomGenAiModelInfo()];

coerce 'RepeatedCustomGenAiModelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersion::GenAiModelInfo::CustomGenAiModelInfo'->new($_) } @$_ ] };

declare 'MapStringCustomGenAiModelInfo',
    as HashRef[CustomGenAiModelInfo()];

declare 'CustomModelType',
    as (Int | Str);

declare 'ProcessorVersionAlias',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::ProcessorVersionAlias'];

coerce 'ProcessorVersionAlias',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersionAlias'->new($_) };

declare 'RepeatedProcessorVersionAlias',
    as ArrayRef[ProcessorVersionAlias()];

coerce 'RepeatedProcessorVersionAlias',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::ProcessorVersionAlias'->new($_) } @$_ ] };

declare 'MapStringProcessorVersionAlias',
    as HashRef[ProcessorVersionAlias()];

declare 'Processor',
    as InstanceOf['Google::Cloud::Documentai::V1::Processor::Processor'];

coerce 'Processor',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Processor::Processor'->new($_) };

declare 'RepeatedProcessor',
    as ArrayRef[Processor()];

coerce 'RepeatedProcessor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Processor::Processor'->new($_) } @$_ ] };

declare 'MapStringProcessor',
    as HashRef[Processor()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::Processor::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
