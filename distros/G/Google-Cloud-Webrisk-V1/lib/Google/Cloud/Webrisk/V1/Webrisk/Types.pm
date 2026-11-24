package Google::Cloud::Webrisk::V1::Webrisk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ThreatType',
    as (Int | Str);

declare 'CompressionType',
    as (Int | Str);

declare 'ComputeThreatListDiffRequest',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest'];

coerce 'ComputeThreatListDiffRequest',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest'->new($_) };

declare 'RepeatedComputeThreatListDiffRequest',
    as ArrayRef[ComputeThreatListDiffRequest()];

coerce 'RepeatedComputeThreatListDiffRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest'->new($_) } @$_ ] };

declare 'MapStringComputeThreatListDiffRequest',
    as HashRef[ComputeThreatListDiffRequest()];

declare 'Constraints',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest::Constraints'];

coerce 'Constraints',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest::Constraints'->new($_) };

declare 'RepeatedConstraints',
    as ArrayRef[Constraints()];

coerce 'RepeatedConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest::Constraints'->new($_) } @$_ ] };

declare 'MapStringConstraints',
    as HashRef[Constraints()];

declare 'ComputeThreatListDiffResponse',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse'];

coerce 'ComputeThreatListDiffResponse',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse'->new($_) };

declare 'RepeatedComputeThreatListDiffResponse',
    as ArrayRef[ComputeThreatListDiffResponse()];

coerce 'RepeatedComputeThreatListDiffResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse'->new($_) } @$_ ] };

declare 'MapStringComputeThreatListDiffResponse',
    as HashRef[ComputeThreatListDiffResponse()];

declare 'ResponseType',
    as (Int | Str);

declare 'Checksum',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse::Checksum'];

coerce 'Checksum',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse::Checksum'->new($_) };

declare 'RepeatedChecksum',
    as ArrayRef[Checksum()];

coerce 'RepeatedChecksum',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse::Checksum'->new($_) } @$_ ] };

declare 'MapStringChecksum',
    as HashRef[Checksum()];

declare 'SearchUrisRequest',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SearchUrisRequest'];

coerce 'SearchUrisRequest',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisRequest'->new($_) };

declare 'RepeatedSearchUrisRequest',
    as ArrayRef[SearchUrisRequest()];

coerce 'RepeatedSearchUrisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisRequest'->new($_) } @$_ ] };

declare 'MapStringSearchUrisRequest',
    as HashRef[SearchUrisRequest()];

declare 'SearchUrisResponse',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse'];

coerce 'SearchUrisResponse',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse'->new($_) };

declare 'RepeatedSearchUrisResponse',
    as ArrayRef[SearchUrisResponse()];

coerce 'RepeatedSearchUrisResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse'->new($_) } @$_ ] };

declare 'MapStringSearchUrisResponse',
    as HashRef[SearchUrisResponse()];

declare 'ThreatUri',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse::ThreatUri'];

coerce 'ThreatUri',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse::ThreatUri'->new($_) };

declare 'RepeatedThreatUri',
    as ArrayRef[ThreatUri()];

coerce 'RepeatedThreatUri',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse::ThreatUri'->new($_) } @$_ ] };

declare 'MapStringThreatUri',
    as HashRef[ThreatUri()];

declare 'SearchHashesRequest',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SearchHashesRequest'];

coerce 'SearchHashesRequest',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesRequest'->new($_) };

declare 'RepeatedSearchHashesRequest',
    as ArrayRef[SearchHashesRequest()];

coerce 'RepeatedSearchHashesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchHashesRequest',
    as HashRef[SearchHashesRequest()];

declare 'SearchHashesResponse',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse'];

coerce 'SearchHashesResponse',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse'->new($_) };

declare 'RepeatedSearchHashesResponse',
    as ArrayRef[SearchHashesResponse()];

coerce 'RepeatedSearchHashesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchHashesResponse',
    as HashRef[SearchHashesResponse()];

declare 'ThreatHash',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse::ThreatHash'];

coerce 'ThreatHash',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse::ThreatHash'->new($_) };

declare 'RepeatedThreatHash',
    as ArrayRef[ThreatHash()];

coerce 'RepeatedThreatHash',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse::ThreatHash'->new($_) } @$_ ] };

declare 'MapStringThreatHash',
    as HashRef[ThreatHash()];

declare 'ThreatEntryAdditions',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ThreatEntryAdditions'];

coerce 'ThreatEntryAdditions',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatEntryAdditions'->new($_) };

declare 'RepeatedThreatEntryAdditions',
    as ArrayRef[ThreatEntryAdditions()];

coerce 'RepeatedThreatEntryAdditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatEntryAdditions'->new($_) } @$_ ] };

declare 'MapStringThreatEntryAdditions',
    as HashRef[ThreatEntryAdditions()];

declare 'ThreatEntryRemovals',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ThreatEntryRemovals'];

coerce 'ThreatEntryRemovals',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatEntryRemovals'->new($_) };

declare 'RepeatedThreatEntryRemovals',
    as ArrayRef[ThreatEntryRemovals()];

coerce 'RepeatedThreatEntryRemovals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatEntryRemovals'->new($_) } @$_ ] };

declare 'MapStringThreatEntryRemovals',
    as HashRef[ThreatEntryRemovals()];

declare 'RawIndices',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::RawIndices'];

coerce 'RawIndices',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::RawIndices'->new($_) };

declare 'RepeatedRawIndices',
    as ArrayRef[RawIndices()];

coerce 'RepeatedRawIndices',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::RawIndices'->new($_) } @$_ ] };

declare 'MapStringRawIndices',
    as HashRef[RawIndices()];

declare 'RawHashes',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::RawHashes'];

coerce 'RawHashes',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::RawHashes'->new($_) };

declare 'RepeatedRawHashes',
    as ArrayRef[RawHashes()];

coerce 'RepeatedRawHashes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::RawHashes'->new($_) } @$_ ] };

declare 'MapStringRawHashes',
    as HashRef[RawHashes()];

declare 'RiceDeltaEncoding',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::RiceDeltaEncoding'];

coerce 'RiceDeltaEncoding',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::RiceDeltaEncoding'->new($_) };

declare 'RepeatedRiceDeltaEncoding',
    as ArrayRef[RiceDeltaEncoding()];

coerce 'RepeatedRiceDeltaEncoding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::RiceDeltaEncoding'->new($_) } @$_ ] };

declare 'MapStringRiceDeltaEncoding',
    as HashRef[RiceDeltaEncoding()];

declare 'Submission',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::Submission'];

coerce 'Submission',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::Submission'->new($_) };

declare 'RepeatedSubmission',
    as ArrayRef[Submission()];

coerce 'RepeatedSubmission',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::Submission'->new($_) } @$_ ] };

declare 'MapStringSubmission',
    as HashRef[Submission()];

declare 'ThreatInfo',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo'];

coerce 'ThreatInfo',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo'->new($_) };

declare 'RepeatedThreatInfo',
    as ArrayRef[ThreatInfo()];

coerce 'RepeatedThreatInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo'->new($_) } @$_ ] };

declare 'MapStringThreatInfo',
    as HashRef[ThreatInfo()];

declare 'AbuseType',
    as (Int | Str);

declare 'Confidence',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo::Confidence'];

coerce 'Confidence',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo::Confidence'->new($_) };

declare 'RepeatedConfidence',
    as ArrayRef[Confidence()];

coerce 'RepeatedConfidence',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo::Confidence'->new($_) } @$_ ] };

declare 'MapStringConfidence',
    as HashRef[Confidence()];

declare 'ConfidenceLevel',
    as (Int | Str);

declare 'ThreatJustification',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo::ThreatJustification'];

coerce 'ThreatJustification',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo::ThreatJustification'->new($_) };

declare 'RepeatedThreatJustification',
    as ArrayRef[ThreatJustification()];

coerce 'RepeatedThreatJustification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatInfo::ThreatJustification'->new($_) } @$_ ] };

declare 'MapStringThreatJustification',
    as HashRef[ThreatJustification()];

declare 'JustificationLabel',
    as (Int | Str);

declare 'ThreatDiscovery',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::ThreatDiscovery'];

coerce 'ThreatDiscovery',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatDiscovery'->new($_) };

declare 'RepeatedThreatDiscovery',
    as ArrayRef[ThreatDiscovery()];

coerce 'RepeatedThreatDiscovery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::ThreatDiscovery'->new($_) } @$_ ] };

declare 'MapStringThreatDiscovery',
    as HashRef[ThreatDiscovery()];

declare 'Platform',
    as (Int | Str);

declare 'CreateSubmissionRequest',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::CreateSubmissionRequest'];

coerce 'CreateSubmissionRequest',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::CreateSubmissionRequest'->new($_) };

declare 'RepeatedCreateSubmissionRequest',
    as ArrayRef[CreateSubmissionRequest()];

coerce 'RepeatedCreateSubmissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::CreateSubmissionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSubmissionRequest',
    as HashRef[CreateSubmissionRequest()];

declare 'SubmitUriRequest',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SubmitUriRequest'];

coerce 'SubmitUriRequest',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SubmitUriRequest'->new($_) };

declare 'RepeatedSubmitUriRequest',
    as ArrayRef[SubmitUriRequest()];

coerce 'RepeatedSubmitUriRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SubmitUriRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitUriRequest',
    as HashRef[SubmitUriRequest()];

declare 'SubmitUriMetadata',
    as InstanceOf['Google::Cloud::Webrisk::V1::Webrisk::SubmitUriMetadata'];

coerce 'SubmitUriMetadata',
    from HashRef, via { 'Google::Cloud::Webrisk::V1::Webrisk::SubmitUriMetadata'->new($_) };

declare 'RepeatedSubmitUriMetadata',
    as ArrayRef[SubmitUriMetadata()];

coerce 'RepeatedSubmitUriMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Webrisk::V1::Webrisk::SubmitUriMetadata'->new($_) } @$_ ] };

declare 'MapStringSubmitUriMetadata',
    as HashRef[SubmitUriMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Webrisk::V1::Webrisk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
