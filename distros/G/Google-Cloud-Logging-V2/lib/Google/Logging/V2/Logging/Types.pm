package Google::Logging::V2::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeleteLogRequest',
    as InstanceOf['Google::Logging::V2::Logging::DeleteLogRequest'];

coerce 'DeleteLogRequest',
    from HashRef, via { 'Google::Logging::V2::Logging::DeleteLogRequest'->new($_) };

declare 'RepeatedDeleteLogRequest',
    as ArrayRef[DeleteLogRequest()];

coerce 'RepeatedDeleteLogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::DeleteLogRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLogRequest',
    as HashRef[DeleteLogRequest()];

declare 'WriteLogEntriesRequest',
    as InstanceOf['Google::Logging::V2::Logging::WriteLogEntriesRequest'];

coerce 'WriteLogEntriesRequest',
    from HashRef, via { 'Google::Logging::V2::Logging::WriteLogEntriesRequest'->new($_) };

declare 'RepeatedWriteLogEntriesRequest',
    as ArrayRef[WriteLogEntriesRequest()];

coerce 'RepeatedWriteLogEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::WriteLogEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringWriteLogEntriesRequest',
    as HashRef[WriteLogEntriesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Logging::V2::Logging::WriteLogEntriesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Logging::V2::Logging::WriteLogEntriesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::WriteLogEntriesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'WriteLogEntriesResponse',
    as InstanceOf['Google::Logging::V2::Logging::WriteLogEntriesResponse'];

coerce 'WriteLogEntriesResponse',
    from HashRef, via { 'Google::Logging::V2::Logging::WriteLogEntriesResponse'->new($_) };

declare 'RepeatedWriteLogEntriesResponse',
    as ArrayRef[WriteLogEntriesResponse()];

coerce 'RepeatedWriteLogEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::WriteLogEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringWriteLogEntriesResponse',
    as HashRef[WriteLogEntriesResponse()];

declare 'WriteLogEntriesPartialErrors',
    as InstanceOf['Google::Logging::V2::Logging::WriteLogEntriesPartialErrors'];

coerce 'WriteLogEntriesPartialErrors',
    from HashRef, via { 'Google::Logging::V2::Logging::WriteLogEntriesPartialErrors'->new($_) };

declare 'RepeatedWriteLogEntriesPartialErrors',
    as ArrayRef[WriteLogEntriesPartialErrors()];

coerce 'RepeatedWriteLogEntriesPartialErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::WriteLogEntriesPartialErrors'->new($_) } @$_ ] };

declare 'MapStringWriteLogEntriesPartialErrors',
    as HashRef[WriteLogEntriesPartialErrors()];

declare 'LogEntryErrorsEntry',
    as InstanceOf['Google::Logging::V2::Logging::WriteLogEntriesPartialErrors::LogEntryErrorsEntry'];

coerce 'LogEntryErrorsEntry',
    from HashRef, via { 'Google::Logging::V2::Logging::WriteLogEntriesPartialErrors::LogEntryErrorsEntry'->new($_) };

declare 'RepeatedLogEntryErrorsEntry',
    as ArrayRef[LogEntryErrorsEntry()];

coerce 'RepeatedLogEntryErrorsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::WriteLogEntriesPartialErrors::LogEntryErrorsEntry'->new($_) } @$_ ] };

declare 'MapStringLogEntryErrorsEntry',
    as HashRef[LogEntryErrorsEntry()];

declare 'ListLogEntriesRequest',
    as InstanceOf['Google::Logging::V2::Logging::ListLogEntriesRequest'];

coerce 'ListLogEntriesRequest',
    from HashRef, via { 'Google::Logging::V2::Logging::ListLogEntriesRequest'->new($_) };

declare 'RepeatedListLogEntriesRequest',
    as ArrayRef[ListLogEntriesRequest()];

coerce 'RepeatedListLogEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::ListLogEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListLogEntriesRequest',
    as HashRef[ListLogEntriesRequest()];

declare 'ListLogEntriesResponse',
    as InstanceOf['Google::Logging::V2::Logging::ListLogEntriesResponse'];

coerce 'ListLogEntriesResponse',
    from HashRef, via { 'Google::Logging::V2::Logging::ListLogEntriesResponse'->new($_) };

declare 'RepeatedListLogEntriesResponse',
    as ArrayRef[ListLogEntriesResponse()];

coerce 'RepeatedListLogEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::ListLogEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListLogEntriesResponse',
    as HashRef[ListLogEntriesResponse()];

declare 'ListMonitoredResourceDescriptorsRequest',
    as InstanceOf['Google::Logging::V2::Logging::ListMonitoredResourceDescriptorsRequest'];

coerce 'ListMonitoredResourceDescriptorsRequest',
    from HashRef, via { 'Google::Logging::V2::Logging::ListMonitoredResourceDescriptorsRequest'->new($_) };

declare 'RepeatedListMonitoredResourceDescriptorsRequest',
    as ArrayRef[ListMonitoredResourceDescriptorsRequest()];

coerce 'RepeatedListMonitoredResourceDescriptorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::ListMonitoredResourceDescriptorsRequest'->new($_) } @$_ ] };

declare 'MapStringListMonitoredResourceDescriptorsRequest',
    as HashRef[ListMonitoredResourceDescriptorsRequest()];

declare 'ListMonitoredResourceDescriptorsResponse',
    as InstanceOf['Google::Logging::V2::Logging::ListMonitoredResourceDescriptorsResponse'];

coerce 'ListMonitoredResourceDescriptorsResponse',
    from HashRef, via { 'Google::Logging::V2::Logging::ListMonitoredResourceDescriptorsResponse'->new($_) };

declare 'RepeatedListMonitoredResourceDescriptorsResponse',
    as ArrayRef[ListMonitoredResourceDescriptorsResponse()];

coerce 'RepeatedListMonitoredResourceDescriptorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::ListMonitoredResourceDescriptorsResponse'->new($_) } @$_ ] };

declare 'MapStringListMonitoredResourceDescriptorsResponse',
    as HashRef[ListMonitoredResourceDescriptorsResponse()];

declare 'ListLogsRequest',
    as InstanceOf['Google::Logging::V2::Logging::ListLogsRequest'];

coerce 'ListLogsRequest',
    from HashRef, via { 'Google::Logging::V2::Logging::ListLogsRequest'->new($_) };

declare 'RepeatedListLogsRequest',
    as ArrayRef[ListLogsRequest()];

coerce 'RepeatedListLogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::ListLogsRequest'->new($_) } @$_ ] };

declare 'MapStringListLogsRequest',
    as HashRef[ListLogsRequest()];

declare 'ListLogsResponse',
    as InstanceOf['Google::Logging::V2::Logging::ListLogsResponse'];

coerce 'ListLogsResponse',
    from HashRef, via { 'Google::Logging::V2::Logging::ListLogsResponse'->new($_) };

declare 'RepeatedListLogsResponse',
    as ArrayRef[ListLogsResponse()];

coerce 'RepeatedListLogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::ListLogsResponse'->new($_) } @$_ ] };

declare 'MapStringListLogsResponse',
    as HashRef[ListLogsResponse()];

declare 'TailLogEntriesRequest',
    as InstanceOf['Google::Logging::V2::Logging::TailLogEntriesRequest'];

coerce 'TailLogEntriesRequest',
    from HashRef, via { 'Google::Logging::V2::Logging::TailLogEntriesRequest'->new($_) };

declare 'RepeatedTailLogEntriesRequest',
    as ArrayRef[TailLogEntriesRequest()];

coerce 'RepeatedTailLogEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::TailLogEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringTailLogEntriesRequest',
    as HashRef[TailLogEntriesRequest()];

declare 'TailLogEntriesResponse',
    as InstanceOf['Google::Logging::V2::Logging::TailLogEntriesResponse'];

coerce 'TailLogEntriesResponse',
    from HashRef, via { 'Google::Logging::V2::Logging::TailLogEntriesResponse'->new($_) };

declare 'RepeatedTailLogEntriesResponse',
    as ArrayRef[TailLogEntriesResponse()];

coerce 'RepeatedTailLogEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::TailLogEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringTailLogEntriesResponse',
    as HashRef[TailLogEntriesResponse()];

declare 'SuppressionInfo',
    as InstanceOf['Google::Logging::V2::Logging::TailLogEntriesResponse::SuppressionInfo'];

coerce 'SuppressionInfo',
    from HashRef, via { 'Google::Logging::V2::Logging::TailLogEntriesResponse::SuppressionInfo'->new($_) };

declare 'RepeatedSuppressionInfo',
    as ArrayRef[SuppressionInfo()];

coerce 'RepeatedSuppressionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::Logging::TailLogEntriesResponse::SuppressionInfo'->new($_) } @$_ ] };

declare 'MapStringSuppressionInfo',
    as HashRef[SuppressionInfo()];

declare 'Reason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Logging::V2::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
