package Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateAnnotationRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest'];

coerce 'CreateAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest'->new($_) };

declare 'RepeatedCreateAnnotationRequest',
    as ArrayRef[CreateAnnotationRequest()];

coerce 'RepeatedCreateAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnnotationRequest',
    as HashRef[CreateAnnotationRequest()];

declare 'GetAnnotationRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetAnnotationRequest'];

coerce 'GetAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetAnnotationRequest'->new($_) };

declare 'RepeatedGetAnnotationRequest',
    as ArrayRef[GetAnnotationRequest()];

coerce 'RepeatedGetAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotationRequest',
    as HashRef[GetAnnotationRequest()];

declare 'CreateCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateCollectorRequest'];

coerce 'CreateCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateCollectorRequest'->new($_) };

declare 'RepeatedCreateCollectorRequest',
    as ArrayRef[CreateCollectorRequest()];

coerce 'RepeatedCreateCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::CreateCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCollectorRequest',
    as HashRef[CreateCollectorRequest()];

declare 'ListCollectorsRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsRequest'];

coerce 'ListCollectorsRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsRequest'->new($_) };

declare 'RepeatedListCollectorsRequest',
    as ArrayRef[ListCollectorsRequest()];

coerce 'RepeatedListCollectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListCollectorsRequest',
    as HashRef[ListCollectorsRequest()];

declare 'ListCollectorsResponse',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsResponse'];

coerce 'ListCollectorsResponse',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsResponse'->new($_) };

declare 'RepeatedListCollectorsResponse',
    as ArrayRef[ListCollectorsResponse()];

coerce 'RepeatedListCollectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ListCollectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListCollectorsResponse',
    as HashRef[ListCollectorsResponse()];

declare 'GetCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetCollectorRequest'];

coerce 'GetCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetCollectorRequest'->new($_) };

declare 'RepeatedGetCollectorRequest',
    as ArrayRef[GetCollectorRequest()];

coerce 'RepeatedGetCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::GetCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetCollectorRequest',
    as HashRef[GetCollectorRequest()];

declare 'DeleteCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::DeleteCollectorRequest'];

coerce 'DeleteCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::DeleteCollectorRequest'->new($_) };

declare 'RepeatedDeleteCollectorRequest',
    as ArrayRef[DeleteCollectorRequest()];

coerce 'RepeatedDeleteCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::DeleteCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCollectorRequest',
    as HashRef[DeleteCollectorRequest()];

declare 'UpdateCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::UpdateCollectorRequest'];

coerce 'UpdateCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::UpdateCollectorRequest'->new($_) };

declare 'RepeatedUpdateCollectorRequest',
    as ArrayRef[UpdateCollectorRequest()];

coerce 'RepeatedUpdateCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::UpdateCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCollectorRequest',
    as HashRef[UpdateCollectorRequest()];

declare 'ResumeCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ResumeCollectorRequest'];

coerce 'ResumeCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ResumeCollectorRequest'->new($_) };

declare 'RepeatedResumeCollectorRequest',
    as ArrayRef[ResumeCollectorRequest()];

coerce 'RepeatedResumeCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::ResumeCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringResumeCollectorRequest',
    as HashRef[ResumeCollectorRequest()];

declare 'RegisterCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RegisterCollectorRequest'];

coerce 'RegisterCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RegisterCollectorRequest'->new($_) };

declare 'RepeatedRegisterCollectorRequest',
    as ArrayRef[RegisterCollectorRequest()];

coerce 'RepeatedRegisterCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::RegisterCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterCollectorRequest',
    as HashRef[RegisterCollectorRequest()];

declare 'PauseCollectorRequest',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::PauseCollectorRequest'];

coerce 'PauseCollectorRequest',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::PauseCollectorRequest'->new($_) };

declare 'RepeatedPauseCollectorRequest',
    as ArrayRef[PauseCollectorRequest()];

coerce 'RepeatedPauseCollectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::PauseCollectorRequest'->new($_) } @$_ ] };

declare 'MapStringPauseCollectorRequest',
    as HashRef[PauseCollectorRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Rapidmigrationassessment::V1::Rapidmigrationassessment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
