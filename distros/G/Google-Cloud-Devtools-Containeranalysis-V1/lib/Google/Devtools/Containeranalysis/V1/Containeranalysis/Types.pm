package Google::Devtools::Containeranalysis::V1::Containeranalysis::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExportSBOMRequest',
    as InstanceOf['Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest'];

coerce 'ExportSBOMRequest',
    from HashRef, via { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest'->new($_) };

declare 'RepeatedExportSBOMRequest',
    as ArrayRef[ExportSBOMRequest()];

coerce 'RepeatedExportSBOMRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest'->new($_) } @$_ ] };

declare 'MapStringExportSBOMRequest',
    as HashRef[ExportSBOMRequest()];

declare 'CloudStorageLocation',
    as InstanceOf['Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest::CloudStorageLocation'];

coerce 'CloudStorageLocation',
    from HashRef, via { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest::CloudStorageLocation'->new($_) };

declare 'RepeatedCloudStorageLocation',
    as ArrayRef[CloudStorageLocation()];

coerce 'RepeatedCloudStorageLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMRequest::CloudStorageLocation'->new($_) } @$_ ] };

declare 'MapStringCloudStorageLocation',
    as HashRef[CloudStorageLocation()];

declare 'ExportSBOMResponse',
    as InstanceOf['Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMResponse'];

coerce 'ExportSBOMResponse',
    from HashRef, via { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMResponse'->new($_) };

declare 'RepeatedExportSBOMResponse',
    as ArrayRef[ExportSBOMResponse()];

coerce 'RepeatedExportSBOMResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::ExportSBOMResponse'->new($_) } @$_ ] };

declare 'MapStringExportSBOMResponse',
    as HashRef[ExportSBOMResponse()];

declare 'GetVulnerabilityOccurrencesSummaryRequest',
    as InstanceOf['Google::Devtools::Containeranalysis::V1::Containeranalysis::GetVulnerabilityOccurrencesSummaryRequest'];

coerce 'GetVulnerabilityOccurrencesSummaryRequest',
    from HashRef, via { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::GetVulnerabilityOccurrencesSummaryRequest'->new($_) };

declare 'RepeatedGetVulnerabilityOccurrencesSummaryRequest',
    as ArrayRef[GetVulnerabilityOccurrencesSummaryRequest()];

coerce 'RepeatedGetVulnerabilityOccurrencesSummaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::GetVulnerabilityOccurrencesSummaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetVulnerabilityOccurrencesSummaryRequest',
    as HashRef[GetVulnerabilityOccurrencesSummaryRequest()];

declare 'VulnerabilityOccurrencesSummary',
    as InstanceOf['Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary'];

coerce 'VulnerabilityOccurrencesSummary',
    from HashRef, via { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary'->new($_) };

declare 'RepeatedVulnerabilityOccurrencesSummary',
    as ArrayRef[VulnerabilityOccurrencesSummary()];

coerce 'RepeatedVulnerabilityOccurrencesSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary'->new($_) } @$_ ] };

declare 'MapStringVulnerabilityOccurrencesSummary',
    as HashRef[VulnerabilityOccurrencesSummary()];

declare 'FixableTotalByDigest',
    as InstanceOf['Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary::FixableTotalByDigest'];

coerce 'FixableTotalByDigest',
    from HashRef, via { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary::FixableTotalByDigest'->new($_) };

declare 'RepeatedFixableTotalByDigest',
    as ArrayRef[FixableTotalByDigest()];

coerce 'RepeatedFixableTotalByDigest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Containeranalysis::V1::Containeranalysis::VulnerabilityOccurrencesSummary::FixableTotalByDigest'->new($_) } @$_ ] };

declare 'MapStringFixableTotalByDigest',
    as HashRef[FixableTotalByDigest()];

1;

__END__

=head1 NAME

Google::Devtools::Containeranalysis::V1::Containeranalysis::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
