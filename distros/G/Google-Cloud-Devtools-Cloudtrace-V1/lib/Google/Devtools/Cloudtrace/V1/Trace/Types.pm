package Google::Devtools::Cloudtrace::V1::Trace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Trace',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::Trace'];

coerce 'Trace',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::Trace'->new($_) };

declare 'RepeatedTrace',
    as ArrayRef[Trace()];

coerce 'RepeatedTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::Trace'->new($_) } @$_ ] };

declare 'MapStringTrace',
    as HashRef[Trace()];

declare 'Traces',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::Traces'];

coerce 'Traces',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::Traces'->new($_) };

declare 'RepeatedTraces',
    as ArrayRef[Traces()];

coerce 'RepeatedTraces',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::Traces'->new($_) } @$_ ] };

declare 'MapStringTraces',
    as HashRef[Traces()];

declare 'TraceSpan',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::TraceSpan'];

coerce 'TraceSpan',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::TraceSpan'->new($_) };

declare 'RepeatedTraceSpan',
    as ArrayRef[TraceSpan()];

coerce 'RepeatedTraceSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::TraceSpan'->new($_) } @$_ ] };

declare 'MapStringTraceSpan',
    as HashRef[TraceSpan()];

declare 'SpanKind',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::TraceSpan::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::TraceSpan::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::TraceSpan::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListTracesRequest',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest'];

coerce 'ListTracesRequest',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest'->new($_) };

declare 'RepeatedListTracesRequest',
    as ArrayRef[ListTracesRequest()];

coerce 'RepeatedListTracesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesRequest'->new($_) } @$_ ] };

declare 'MapStringListTracesRequest',
    as HashRef[ListTracesRequest()];

declare 'ViewType',
    as (Int | Str);

declare 'ListTracesResponse',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse'];

coerce 'ListTracesResponse',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse'->new($_) };

declare 'RepeatedListTracesResponse',
    as ArrayRef[ListTracesResponse()];

coerce 'RepeatedListTracesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::ListTracesResponse'->new($_) } @$_ ] };

declare 'MapStringListTracesResponse',
    as HashRef[ListTracesResponse()];

declare 'GetTraceRequest',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest'];

coerce 'GetTraceRequest',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest'->new($_) };

declare 'RepeatedGetTraceRequest',
    as ArrayRef[GetTraceRequest()];

coerce 'RepeatedGetTraceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::GetTraceRequest'->new($_) } @$_ ] };

declare 'MapStringGetTraceRequest',
    as HashRef[GetTraceRequest()];

declare 'PatchTracesRequest',
    as InstanceOf['Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest'];

coerce 'PatchTracesRequest',
    from HashRef, via { 'Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest'->new($_) };

declare 'RepeatedPatchTracesRequest',
    as ArrayRef[PatchTracesRequest()];

coerce 'RepeatedPatchTracesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudtrace::V1::Trace::PatchTracesRequest'->new($_) } @$_ ] };

declare 'MapStringPatchTracesRequest',
    as HashRef[PatchTracesRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudtrace::V1::Trace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
