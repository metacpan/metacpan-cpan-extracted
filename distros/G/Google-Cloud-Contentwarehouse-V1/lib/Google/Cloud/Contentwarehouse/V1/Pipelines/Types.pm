package Google::Cloud::Contentwarehouse::V1::Pipelines::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunPipelineResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse'];

coerce 'RunPipelineResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse'->new($_) };

declare 'RepeatedRunPipelineResponse',
    as ArrayRef[RunPipelineResponse()];

coerce 'RepeatedRunPipelineResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse'->new($_) } @$_ ] };

declare 'MapStringRunPipelineResponse',
    as HashRef[RunPipelineResponse()];

declare 'RunPipelineMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata'];

coerce 'RunPipelineMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata'->new($_) };

declare 'RepeatedRunPipelineMetadata',
    as ArrayRef[RunPipelineMetadata()];

coerce 'RepeatedRunPipelineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata'->new($_) } @$_ ] };

declare 'MapStringRunPipelineMetadata',
    as HashRef[RunPipelineMetadata()];

declare 'GcsIngestPipelineMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::GcsIngestPipelineMetadata'];

coerce 'GcsIngestPipelineMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::GcsIngestPipelineMetadata'->new($_) };

declare 'RepeatedGcsIngestPipelineMetadata',
    as ArrayRef[GcsIngestPipelineMetadata()];

coerce 'RepeatedGcsIngestPipelineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::GcsIngestPipelineMetadata'->new($_) } @$_ ] };

declare 'MapStringGcsIngestPipelineMetadata',
    as HashRef[GcsIngestPipelineMetadata()];

declare 'ExportToCdwPipelineMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ExportToCdwPipelineMetadata'];

coerce 'ExportToCdwPipelineMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ExportToCdwPipelineMetadata'->new($_) };

declare 'RepeatedExportToCdwPipelineMetadata',
    as ArrayRef[ExportToCdwPipelineMetadata()];

coerce 'RepeatedExportToCdwPipelineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ExportToCdwPipelineMetadata'->new($_) } @$_ ] };

declare 'MapStringExportToCdwPipelineMetadata',
    as HashRef[ExportToCdwPipelineMetadata()];

declare 'ProcessWithDocAiPipelineMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ProcessWithDocAiPipelineMetadata'];

coerce 'ProcessWithDocAiPipelineMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ProcessWithDocAiPipelineMetadata'->new($_) };

declare 'RepeatedProcessWithDocAiPipelineMetadata',
    as ArrayRef[ProcessWithDocAiPipelineMetadata()];

coerce 'RepeatedProcessWithDocAiPipelineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ProcessWithDocAiPipelineMetadata'->new($_) } @$_ ] };

declare 'MapStringProcessWithDocAiPipelineMetadata',
    as HashRef[ProcessWithDocAiPipelineMetadata()];

declare 'IndividualDocumentStatus',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::IndividualDocumentStatus'];

coerce 'IndividualDocumentStatus',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::IndividualDocumentStatus'->new($_) };

declare 'RepeatedIndividualDocumentStatus',
    as ArrayRef[IndividualDocumentStatus()];

coerce 'RepeatedIndividualDocumentStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::IndividualDocumentStatus'->new($_) } @$_ ] };

declare 'MapStringIndividualDocumentStatus',
    as HashRef[IndividualDocumentStatus()];

declare 'ProcessorInfo',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo'];

coerce 'ProcessorInfo',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo'->new($_) };

declare 'RepeatedProcessorInfo',
    as ArrayRef[ProcessorInfo()];

coerce 'RepeatedProcessorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo'->new($_) } @$_ ] };

declare 'MapStringProcessorInfo',
    as HashRef[ProcessorInfo()];

declare 'IngestPipelineConfig',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig'];

coerce 'IngestPipelineConfig',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig'->new($_) };

declare 'RepeatedIngestPipelineConfig',
    as ArrayRef[IngestPipelineConfig()];

coerce 'RepeatedIngestPipelineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig'->new($_) } @$_ ] };

declare 'MapStringIngestPipelineConfig',
    as HashRef[IngestPipelineConfig()];

declare 'GcsIngestPipeline',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestPipeline'];

coerce 'GcsIngestPipeline',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestPipeline'->new($_) };

declare 'RepeatedGcsIngestPipeline',
    as ArrayRef[GcsIngestPipeline()];

coerce 'RepeatedGcsIngestPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestPipeline'->new($_) } @$_ ] };

declare 'MapStringGcsIngestPipeline',
    as HashRef[GcsIngestPipeline()];

declare 'GcsIngestWithDocAiProcessorsPipeline',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestWithDocAiProcessorsPipeline'];

coerce 'GcsIngestWithDocAiProcessorsPipeline',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestWithDocAiProcessorsPipeline'->new($_) };

declare 'RepeatedGcsIngestWithDocAiProcessorsPipeline',
    as ArrayRef[GcsIngestWithDocAiProcessorsPipeline()];

coerce 'RepeatedGcsIngestWithDocAiProcessorsPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestWithDocAiProcessorsPipeline'->new($_) } @$_ ] };

declare 'MapStringGcsIngestWithDocAiProcessorsPipeline',
    as HashRef[GcsIngestWithDocAiProcessorsPipeline()];

declare 'ExportToCdwPipeline',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::ExportToCdwPipeline'];

coerce 'ExportToCdwPipeline',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::ExportToCdwPipeline'->new($_) };

declare 'RepeatedExportToCdwPipeline',
    as ArrayRef[ExportToCdwPipeline()];

coerce 'RepeatedExportToCdwPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::ExportToCdwPipeline'->new($_) } @$_ ] };

declare 'MapStringExportToCdwPipeline',
    as HashRef[ExportToCdwPipeline()];

declare 'ProcessWithDocAiPipeline',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessWithDocAiPipeline'];

coerce 'ProcessWithDocAiPipeline',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessWithDocAiPipeline'->new($_) };

declare 'RepeatedProcessWithDocAiPipeline',
    as ArrayRef[ProcessWithDocAiPipeline()];

coerce 'RepeatedProcessWithDocAiPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessWithDocAiPipeline'->new($_) } @$_ ] };

declare 'MapStringProcessWithDocAiPipeline',
    as HashRef[ProcessWithDocAiPipeline()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Pipelines::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
