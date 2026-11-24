package Grafeas::V1::Grafeas::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Occurrence',
    as InstanceOf['Grafeas::V1::Grafeas::Occurrence'];

coerce 'Occurrence',
    from HashRef, via { 'Grafeas::V1::Grafeas::Occurrence'->new($_) };

declare 'RepeatedOccurrence',
    as ArrayRef[Occurrence()];

coerce 'RepeatedOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::Occurrence'->new($_) } @$_ ] };

declare 'MapStringOccurrence',
    as HashRef[Occurrence()];

declare 'Note',
    as InstanceOf['Grafeas::V1::Grafeas::Note'];

coerce 'Note',
    from HashRef, via { 'Grafeas::V1::Grafeas::Note'->new($_) };

declare 'RepeatedNote',
    as ArrayRef[Note()];

coerce 'RepeatedNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::Note'->new($_) } @$_ ] };

declare 'MapStringNote',
    as HashRef[Note()];

declare 'GetOccurrenceRequest',
    as InstanceOf['Grafeas::V1::Grafeas::GetOccurrenceRequest'];

coerce 'GetOccurrenceRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::GetOccurrenceRequest'->new($_) };

declare 'RepeatedGetOccurrenceRequest',
    as ArrayRef[GetOccurrenceRequest()];

coerce 'RepeatedGetOccurrenceRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::GetOccurrenceRequest'->new($_) } @$_ ] };

declare 'MapStringGetOccurrenceRequest',
    as HashRef[GetOccurrenceRequest()];

declare 'ListOccurrencesRequest',
    as InstanceOf['Grafeas::V1::Grafeas::ListOccurrencesRequest'];

coerce 'ListOccurrencesRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::ListOccurrencesRequest'->new($_) };

declare 'RepeatedListOccurrencesRequest',
    as ArrayRef[ListOccurrencesRequest()];

coerce 'RepeatedListOccurrencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::ListOccurrencesRequest'->new($_) } @$_ ] };

declare 'MapStringListOccurrencesRequest',
    as HashRef[ListOccurrencesRequest()];

declare 'ListOccurrencesResponse',
    as InstanceOf['Grafeas::V1::Grafeas::ListOccurrencesResponse'];

coerce 'ListOccurrencesResponse',
    from HashRef, via { 'Grafeas::V1::Grafeas::ListOccurrencesResponse'->new($_) };

declare 'RepeatedListOccurrencesResponse',
    as ArrayRef[ListOccurrencesResponse()];

coerce 'RepeatedListOccurrencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::ListOccurrencesResponse'->new($_) } @$_ ] };

declare 'MapStringListOccurrencesResponse',
    as HashRef[ListOccurrencesResponse()];

declare 'DeleteOccurrenceRequest',
    as InstanceOf['Grafeas::V1::Grafeas::DeleteOccurrenceRequest'];

coerce 'DeleteOccurrenceRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::DeleteOccurrenceRequest'->new($_) };

declare 'RepeatedDeleteOccurrenceRequest',
    as ArrayRef[DeleteOccurrenceRequest()];

coerce 'RepeatedDeleteOccurrenceRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::DeleteOccurrenceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOccurrenceRequest',
    as HashRef[DeleteOccurrenceRequest()];

declare 'CreateOccurrenceRequest',
    as InstanceOf['Grafeas::V1::Grafeas::CreateOccurrenceRequest'];

coerce 'CreateOccurrenceRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::CreateOccurrenceRequest'->new($_) };

declare 'RepeatedCreateOccurrenceRequest',
    as ArrayRef[CreateOccurrenceRequest()];

coerce 'RepeatedCreateOccurrenceRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::CreateOccurrenceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOccurrenceRequest',
    as HashRef[CreateOccurrenceRequest()];

declare 'UpdateOccurrenceRequest',
    as InstanceOf['Grafeas::V1::Grafeas::UpdateOccurrenceRequest'];

coerce 'UpdateOccurrenceRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::UpdateOccurrenceRequest'->new($_) };

declare 'RepeatedUpdateOccurrenceRequest',
    as ArrayRef[UpdateOccurrenceRequest()];

coerce 'RepeatedUpdateOccurrenceRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::UpdateOccurrenceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOccurrenceRequest',
    as HashRef[UpdateOccurrenceRequest()];

declare 'GetNoteRequest',
    as InstanceOf['Grafeas::V1::Grafeas::GetNoteRequest'];

coerce 'GetNoteRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::GetNoteRequest'->new($_) };

declare 'RepeatedGetNoteRequest',
    as ArrayRef[GetNoteRequest()];

coerce 'RepeatedGetNoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::GetNoteRequest'->new($_) } @$_ ] };

declare 'MapStringGetNoteRequest',
    as HashRef[GetNoteRequest()];

declare 'GetOccurrenceNoteRequest',
    as InstanceOf['Grafeas::V1::Grafeas::GetOccurrenceNoteRequest'];

coerce 'GetOccurrenceNoteRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::GetOccurrenceNoteRequest'->new($_) };

declare 'RepeatedGetOccurrenceNoteRequest',
    as ArrayRef[GetOccurrenceNoteRequest()];

coerce 'RepeatedGetOccurrenceNoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::GetOccurrenceNoteRequest'->new($_) } @$_ ] };

declare 'MapStringGetOccurrenceNoteRequest',
    as HashRef[GetOccurrenceNoteRequest()];

declare 'ListNotesRequest',
    as InstanceOf['Grafeas::V1::Grafeas::ListNotesRequest'];

coerce 'ListNotesRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::ListNotesRequest'->new($_) };

declare 'RepeatedListNotesRequest',
    as ArrayRef[ListNotesRequest()];

coerce 'RepeatedListNotesRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::ListNotesRequest'->new($_) } @$_ ] };

declare 'MapStringListNotesRequest',
    as HashRef[ListNotesRequest()];

declare 'ListNotesResponse',
    as InstanceOf['Grafeas::V1::Grafeas::ListNotesResponse'];

coerce 'ListNotesResponse',
    from HashRef, via { 'Grafeas::V1::Grafeas::ListNotesResponse'->new($_) };

declare 'RepeatedListNotesResponse',
    as ArrayRef[ListNotesResponse()];

coerce 'RepeatedListNotesResponse',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::ListNotesResponse'->new($_) } @$_ ] };

declare 'MapStringListNotesResponse',
    as HashRef[ListNotesResponse()];

declare 'DeleteNoteRequest',
    as InstanceOf['Grafeas::V1::Grafeas::DeleteNoteRequest'];

coerce 'DeleteNoteRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::DeleteNoteRequest'->new($_) };

declare 'RepeatedDeleteNoteRequest',
    as ArrayRef[DeleteNoteRequest()];

coerce 'RepeatedDeleteNoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::DeleteNoteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNoteRequest',
    as HashRef[DeleteNoteRequest()];

declare 'CreateNoteRequest',
    as InstanceOf['Grafeas::V1::Grafeas::CreateNoteRequest'];

coerce 'CreateNoteRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::CreateNoteRequest'->new($_) };

declare 'RepeatedCreateNoteRequest',
    as ArrayRef[CreateNoteRequest()];

coerce 'RepeatedCreateNoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::CreateNoteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNoteRequest',
    as HashRef[CreateNoteRequest()];

declare 'UpdateNoteRequest',
    as InstanceOf['Grafeas::V1::Grafeas::UpdateNoteRequest'];

coerce 'UpdateNoteRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::UpdateNoteRequest'->new($_) };

declare 'RepeatedUpdateNoteRequest',
    as ArrayRef[UpdateNoteRequest()];

coerce 'RepeatedUpdateNoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::UpdateNoteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNoteRequest',
    as HashRef[UpdateNoteRequest()];

declare 'ListNoteOccurrencesRequest',
    as InstanceOf['Grafeas::V1::Grafeas::ListNoteOccurrencesRequest'];

coerce 'ListNoteOccurrencesRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::ListNoteOccurrencesRequest'->new($_) };

declare 'RepeatedListNoteOccurrencesRequest',
    as ArrayRef[ListNoteOccurrencesRequest()];

coerce 'RepeatedListNoteOccurrencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::ListNoteOccurrencesRequest'->new($_) } @$_ ] };

declare 'MapStringListNoteOccurrencesRequest',
    as HashRef[ListNoteOccurrencesRequest()];

declare 'ListNoteOccurrencesResponse',
    as InstanceOf['Grafeas::V1::Grafeas::ListNoteOccurrencesResponse'];

coerce 'ListNoteOccurrencesResponse',
    from HashRef, via { 'Grafeas::V1::Grafeas::ListNoteOccurrencesResponse'->new($_) };

declare 'RepeatedListNoteOccurrencesResponse',
    as ArrayRef[ListNoteOccurrencesResponse()];

coerce 'RepeatedListNoteOccurrencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::ListNoteOccurrencesResponse'->new($_) } @$_ ] };

declare 'MapStringListNoteOccurrencesResponse',
    as HashRef[ListNoteOccurrencesResponse()];

declare 'BatchCreateNotesRequest',
    as InstanceOf['Grafeas::V1::Grafeas::BatchCreateNotesRequest'];

coerce 'BatchCreateNotesRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::BatchCreateNotesRequest'->new($_) };

declare 'RepeatedBatchCreateNotesRequest',
    as ArrayRef[BatchCreateNotesRequest()];

coerce 'RepeatedBatchCreateNotesRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::BatchCreateNotesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateNotesRequest',
    as HashRef[BatchCreateNotesRequest()];

declare 'NotesEntry',
    as InstanceOf['Grafeas::V1::Grafeas::BatchCreateNotesRequest::NotesEntry'];

coerce 'NotesEntry',
    from HashRef, via { 'Grafeas::V1::Grafeas::BatchCreateNotesRequest::NotesEntry'->new($_) };

declare 'RepeatedNotesEntry',
    as ArrayRef[NotesEntry()];

coerce 'RepeatedNotesEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::BatchCreateNotesRequest::NotesEntry'->new($_) } @$_ ] };

declare 'MapStringNotesEntry',
    as HashRef[NotesEntry()];

declare 'BatchCreateNotesResponse',
    as InstanceOf['Grafeas::V1::Grafeas::BatchCreateNotesResponse'];

coerce 'BatchCreateNotesResponse',
    from HashRef, via { 'Grafeas::V1::Grafeas::BatchCreateNotesResponse'->new($_) };

declare 'RepeatedBatchCreateNotesResponse',
    as ArrayRef[BatchCreateNotesResponse()];

coerce 'RepeatedBatchCreateNotesResponse',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::BatchCreateNotesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateNotesResponse',
    as HashRef[BatchCreateNotesResponse()];

declare 'BatchCreateOccurrencesRequest',
    as InstanceOf['Grafeas::V1::Grafeas::BatchCreateOccurrencesRequest'];

coerce 'BatchCreateOccurrencesRequest',
    from HashRef, via { 'Grafeas::V1::Grafeas::BatchCreateOccurrencesRequest'->new($_) };

declare 'RepeatedBatchCreateOccurrencesRequest',
    as ArrayRef[BatchCreateOccurrencesRequest()];

coerce 'RepeatedBatchCreateOccurrencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::BatchCreateOccurrencesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateOccurrencesRequest',
    as HashRef[BatchCreateOccurrencesRequest()];

declare 'BatchCreateOccurrencesResponse',
    as InstanceOf['Grafeas::V1::Grafeas::BatchCreateOccurrencesResponse'];

coerce 'BatchCreateOccurrencesResponse',
    from HashRef, via { 'Grafeas::V1::Grafeas::BatchCreateOccurrencesResponse'->new($_) };

declare 'RepeatedBatchCreateOccurrencesResponse',
    as ArrayRef[BatchCreateOccurrencesResponse()];

coerce 'RepeatedBatchCreateOccurrencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Grafeas::BatchCreateOccurrencesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateOccurrencesResponse',
    as HashRef[BatchCreateOccurrencesResponse()];

1;

__END__

=head1 NAME

Grafeas::V1::Grafeas::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
