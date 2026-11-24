package Google::Cloud::Retail::V2alpha::ModelService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest'];

coerce 'CreateModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest'->new($_) };

declare 'RepeatedCreateModelRequest',
    as ArrayRef[CreateModelRequest()];

coerce 'RepeatedCreateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateModelRequest',
    as HashRef[CreateModelRequest()];

declare 'UpdateModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::UpdateModelRequest'];

coerce 'UpdateModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::UpdateModelRequest'->new($_) };

declare 'RepeatedUpdateModelRequest',
    as ArrayRef[UpdateModelRequest()];

coerce 'RepeatedUpdateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::UpdateModelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateModelRequest',
    as HashRef[UpdateModelRequest()];

declare 'GetModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'PauseModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::PauseModelRequest'];

coerce 'PauseModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::PauseModelRequest'->new($_) };

declare 'RepeatedPauseModelRequest',
    as ArrayRef[PauseModelRequest()];

coerce 'RepeatedPauseModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::PauseModelRequest'->new($_) } @$_ ] };

declare 'MapStringPauseModelRequest',
    as HashRef[PauseModelRequest()];

declare 'ResumeModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::ResumeModelRequest'];

coerce 'ResumeModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::ResumeModelRequest'->new($_) };

declare 'RepeatedResumeModelRequest',
    as ArrayRef[ResumeModelRequest()];

coerce 'RepeatedResumeModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::ResumeModelRequest'->new($_) } @$_ ] };

declare 'MapStringResumeModelRequest',
    as HashRef[ResumeModelRequest()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'DeleteModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::DeleteModelRequest'];

coerce 'DeleteModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::DeleteModelRequest'->new($_) };

declare 'RepeatedDeleteModelRequest',
    as ArrayRef[DeleteModelRequest()];

coerce 'RepeatedDeleteModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::DeleteModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteModelRequest',
    as HashRef[DeleteModelRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'TuneModelRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::TuneModelRequest'];

coerce 'TuneModelRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::TuneModelRequest'->new($_) };

declare 'RepeatedTuneModelRequest',
    as ArrayRef[TuneModelRequest()];

coerce 'RepeatedTuneModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::TuneModelRequest'->new($_) } @$_ ] };

declare 'MapStringTuneModelRequest',
    as HashRef[TuneModelRequest()];

declare 'CreateModelMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::CreateModelMetadata'];

coerce 'CreateModelMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::CreateModelMetadata'->new($_) };

declare 'RepeatedCreateModelMetadata',
    as ArrayRef[CreateModelMetadata()];

coerce 'RepeatedCreateModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::CreateModelMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateModelMetadata',
    as HashRef[CreateModelMetadata()];

declare 'TuneModelMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::TuneModelMetadata'];

coerce 'TuneModelMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::TuneModelMetadata'->new($_) };

declare 'RepeatedTuneModelMetadata',
    as ArrayRef[TuneModelMetadata()];

coerce 'RepeatedTuneModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::TuneModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTuneModelMetadata',
    as HashRef[TuneModelMetadata()];

declare 'TuneModelResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ModelService::TuneModelResponse'];

coerce 'TuneModelResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ModelService::TuneModelResponse'->new($_) };

declare 'RepeatedTuneModelResponse',
    as ArrayRef[TuneModelResponse()];

coerce 'RepeatedTuneModelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ModelService::TuneModelResponse'->new($_) } @$_ ] };

declare 'MapStringTuneModelResponse',
    as HashRef[TuneModelResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ModelService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
