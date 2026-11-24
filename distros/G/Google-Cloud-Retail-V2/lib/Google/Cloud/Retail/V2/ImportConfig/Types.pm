package Google::Cloud::Retail::V2::ImportConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'BigQuerySource',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::BigQuerySource'];

coerce 'BigQuerySource',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::BigQuerySource'->new($_) };

declare 'RepeatedBigQuerySource',
    as ArrayRef[BigQuerySource()];

coerce 'RepeatedBigQuerySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::BigQuerySource'->new($_) } @$_ ] };

declare 'MapStringBigQuerySource',
    as HashRef[BigQuerySource()];

declare 'ProductInlineSource',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ProductInlineSource'];

coerce 'ProductInlineSource',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ProductInlineSource'->new($_) };

declare 'RepeatedProductInlineSource',
    as ArrayRef[ProductInlineSource()];

coerce 'RepeatedProductInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ProductInlineSource'->new($_) } @$_ ] };

declare 'MapStringProductInlineSource',
    as HashRef[ProductInlineSource()];

declare 'UserEventInlineSource',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::UserEventInlineSource'];

coerce 'UserEventInlineSource',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::UserEventInlineSource'->new($_) };

declare 'RepeatedUserEventInlineSource',
    as ArrayRef[UserEventInlineSource()];

coerce 'RepeatedUserEventInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::UserEventInlineSource'->new($_) } @$_ ] };

declare 'MapStringUserEventInlineSource',
    as HashRef[UserEventInlineSource()];

declare 'ImportErrorsConfig',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig'];

coerce 'ImportErrorsConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig'->new($_) };

declare 'RepeatedImportErrorsConfig',
    as ArrayRef[ImportErrorsConfig()];

coerce 'RepeatedImportErrorsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportErrorsConfig'->new($_) } @$_ ] };

declare 'MapStringImportErrorsConfig',
    as HashRef[ImportErrorsConfig()];

declare 'ImportProductsRequest',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportProductsRequest'];

coerce 'ImportProductsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportProductsRequest'->new($_) };

declare 'RepeatedImportProductsRequest',
    as ArrayRef[ImportProductsRequest()];

coerce 'RepeatedImportProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportProductsRequest'->new($_) } @$_ ] };

declare 'MapStringImportProductsRequest',
    as HashRef[ImportProductsRequest()];

declare 'ReconciliationMode',
    as (Int | Str);

declare 'ImportUserEventsRequest',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsRequest'];

coerce 'ImportUserEventsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsRequest'->new($_) };

declare 'RepeatedImportUserEventsRequest',
    as ArrayRef[ImportUserEventsRequest()];

coerce 'RepeatedImportUserEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsRequest'->new($_) } @$_ ] };

declare 'MapStringImportUserEventsRequest',
    as HashRef[ImportUserEventsRequest()];

declare 'ImportCompletionDataRequest',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataRequest'];

coerce 'ImportCompletionDataRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataRequest'->new($_) };

declare 'RepeatedImportCompletionDataRequest',
    as ArrayRef[ImportCompletionDataRequest()];

coerce 'RepeatedImportCompletionDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportCompletionDataRequest',
    as HashRef[ImportCompletionDataRequest()];

declare 'ProductInputConfig',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ProductInputConfig'];

coerce 'ProductInputConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ProductInputConfig'->new($_) };

declare 'RepeatedProductInputConfig',
    as ArrayRef[ProductInputConfig()];

coerce 'RepeatedProductInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ProductInputConfig'->new($_) } @$_ ] };

declare 'MapStringProductInputConfig',
    as HashRef[ProductInputConfig()];

declare 'UserEventInputConfig',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::UserEventInputConfig'];

coerce 'UserEventInputConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::UserEventInputConfig'->new($_) };

declare 'RepeatedUserEventInputConfig',
    as ArrayRef[UserEventInputConfig()];

coerce 'RepeatedUserEventInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::UserEventInputConfig'->new($_) } @$_ ] };

declare 'MapStringUserEventInputConfig',
    as HashRef[UserEventInputConfig()];

declare 'CompletionDataInputConfig',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::CompletionDataInputConfig'];

coerce 'CompletionDataInputConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::CompletionDataInputConfig'->new($_) };

declare 'RepeatedCompletionDataInputConfig',
    as ArrayRef[CompletionDataInputConfig()];

coerce 'RepeatedCompletionDataInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::CompletionDataInputConfig'->new($_) } @$_ ] };

declare 'MapStringCompletionDataInputConfig',
    as HashRef[CompletionDataInputConfig()];

declare 'ImportMetadata',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportMetadata'];

coerce 'ImportMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportMetadata'->new($_) };

declare 'RepeatedImportMetadata',
    as ArrayRef[ImportMetadata()];

coerce 'RepeatedImportMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportMetadata'->new($_) } @$_ ] };

declare 'MapStringImportMetadata',
    as HashRef[ImportMetadata()];

declare 'ImportProductsResponse',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportProductsResponse'];

coerce 'ImportProductsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportProductsResponse'->new($_) };

declare 'RepeatedImportProductsResponse',
    as ArrayRef[ImportProductsResponse()];

coerce 'RepeatedImportProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportProductsResponse'->new($_) } @$_ ] };

declare 'MapStringImportProductsResponse',
    as HashRef[ImportProductsResponse()];

declare 'ImportUserEventsResponse',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsResponse'];

coerce 'ImportUserEventsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsResponse'->new($_) };

declare 'RepeatedImportUserEventsResponse',
    as ArrayRef[ImportUserEventsResponse()];

coerce 'RepeatedImportUserEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportUserEventsResponse'->new($_) } @$_ ] };

declare 'MapStringImportUserEventsResponse',
    as HashRef[ImportUserEventsResponse()];

declare 'UserEventImportSummary',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::UserEventImportSummary'];

coerce 'UserEventImportSummary',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::UserEventImportSummary'->new($_) };

declare 'RepeatedUserEventImportSummary',
    as ArrayRef[UserEventImportSummary()];

coerce 'RepeatedUserEventImportSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::UserEventImportSummary'->new($_) } @$_ ] };

declare 'MapStringUserEventImportSummary',
    as HashRef[UserEventImportSummary()];

declare 'ImportCompletionDataResponse',
    as InstanceOf['Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataResponse'];

coerce 'ImportCompletionDataResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataResponse'->new($_) };

declare 'RepeatedImportCompletionDataResponse',
    as ArrayRef[ImportCompletionDataResponse()];

coerce 'RepeatedImportCompletionDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::ImportConfig::ImportCompletionDataResponse'->new($_) } @$_ ] };

declare 'MapStringImportCompletionDataResponse',
    as HashRef[ImportCompletionDataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2::ImportConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
