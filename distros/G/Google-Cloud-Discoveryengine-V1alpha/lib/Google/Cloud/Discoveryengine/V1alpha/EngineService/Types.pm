package Google::Cloud::Discoveryengine::V1alpha::EngineService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest'];

coerce 'CreateEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest'->new($_) };

declare 'RepeatedCreateEngineRequest',
    as ArrayRef[CreateEngineRequest()];

coerce 'RepeatedCreateEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEngineRequest',
    as HashRef[CreateEngineRequest()];

declare 'CreateEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineMetadata'];

coerce 'CreateEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineMetadata'->new($_) };

declare 'RepeatedCreateEngineMetadata',
    as ArrayRef[CreateEngineMetadata()];

coerce 'RepeatedCreateEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateEngineMetadata',
    as HashRef[CreateEngineMetadata()];

declare 'DeleteEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineRequest'];

coerce 'DeleteEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineRequest'->new($_) };

declare 'RepeatedDeleteEngineRequest',
    as ArrayRef[DeleteEngineRequest()];

coerce 'RepeatedDeleteEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEngineRequest',
    as HashRef[DeleteEngineRequest()];

declare 'DeleteEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineMetadata'];

coerce 'DeleteEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineMetadata'->new($_) };

declare 'RepeatedDeleteEngineMetadata',
    as ArrayRef[DeleteEngineMetadata()];

coerce 'RepeatedDeleteEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::DeleteEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteEngineMetadata',
    as HashRef[DeleteEngineMetadata()];

declare 'GetEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::GetEngineRequest'];

coerce 'GetEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::GetEngineRequest'->new($_) };

declare 'RepeatedGetEngineRequest',
    as ArrayRef[GetEngineRequest()];

coerce 'RepeatedGetEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::GetEngineRequest'->new($_) } @$_ ] };

declare 'MapStringGetEngineRequest',
    as HashRef[GetEngineRequest()];

declare 'ListEnginesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesRequest'];

coerce 'ListEnginesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesRequest'->new($_) };

declare 'RepeatedListEnginesRequest',
    as ArrayRef[ListEnginesRequest()];

coerce 'RepeatedListEnginesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesRequest'->new($_) } @$_ ] };

declare 'MapStringListEnginesRequest',
    as HashRef[ListEnginesRequest()];

declare 'ListEnginesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesResponse'];

coerce 'ListEnginesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesResponse'->new($_) };

declare 'RepeatedListEnginesResponse',
    as ArrayRef[ListEnginesResponse()];

coerce 'RepeatedListEnginesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ListEnginesResponse'->new($_) } @$_ ] };

declare 'MapStringListEnginesResponse',
    as HashRef[ListEnginesResponse()];

declare 'UpdateEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::UpdateEngineRequest'];

coerce 'UpdateEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::UpdateEngineRequest'->new($_) };

declare 'RepeatedUpdateEngineRequest',
    as ArrayRef[UpdateEngineRequest()];

coerce 'RepeatedUpdateEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::UpdateEngineRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEngineRequest',
    as HashRef[UpdateEngineRequest()];

declare 'PauseEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::PauseEngineRequest'];

coerce 'PauseEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::PauseEngineRequest'->new($_) };

declare 'RepeatedPauseEngineRequest',
    as ArrayRef[PauseEngineRequest()];

coerce 'RepeatedPauseEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::PauseEngineRequest'->new($_) } @$_ ] };

declare 'MapStringPauseEngineRequest',
    as HashRef[PauseEngineRequest()];

declare 'ResumeEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::ResumeEngineRequest'];

coerce 'ResumeEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ResumeEngineRequest'->new($_) };

declare 'RepeatedResumeEngineRequest',
    as ArrayRef[ResumeEngineRequest()];

coerce 'RepeatedResumeEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::ResumeEngineRequest'->new($_) } @$_ ] };

declare 'MapStringResumeEngineRequest',
    as HashRef[ResumeEngineRequest()];

declare 'TuneEngineRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineRequest'];

coerce 'TuneEngineRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineRequest'->new($_) };

declare 'RepeatedTuneEngineRequest',
    as ArrayRef[TuneEngineRequest()];

coerce 'RepeatedTuneEngineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineRequest'->new($_) } @$_ ] };

declare 'MapStringTuneEngineRequest',
    as HashRef[TuneEngineRequest()];

declare 'TuneEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineMetadata'];

coerce 'TuneEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineMetadata'->new($_) };

declare 'RepeatedTuneEngineMetadata',
    as ArrayRef[TuneEngineMetadata()];

coerce 'RepeatedTuneEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringTuneEngineMetadata',
    as HashRef[TuneEngineMetadata()];

declare 'TuneEngineResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineResponse'];

coerce 'TuneEngineResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineResponse'->new($_) };

declare 'RepeatedTuneEngineResponse',
    as ArrayRef[TuneEngineResponse()];

coerce 'RepeatedTuneEngineResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EngineService::TuneEngineResponse'->new($_) } @$_ ] };

declare 'MapStringTuneEngineResponse',
    as HashRef[TuneEngineResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::EngineService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
