package Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateScanConfigRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest'];

coerce 'CreateScanConfigRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest'->new($_) };

declare 'RepeatedCreateScanConfigRequest',
    as ArrayRef[CreateScanConfigRequest()];

coerce 'RepeatedCreateScanConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateScanConfigRequest',
    as HashRef[CreateScanConfigRequest()];

declare 'DeleteScanConfigRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::DeleteScanConfigRequest'];

coerce 'DeleteScanConfigRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::DeleteScanConfigRequest'->new($_) };

declare 'RepeatedDeleteScanConfigRequest',
    as ArrayRef[DeleteScanConfigRequest()];

coerce 'RepeatedDeleteScanConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::DeleteScanConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteScanConfigRequest',
    as HashRef[DeleteScanConfigRequest()];

declare 'GetScanConfigRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanConfigRequest'];

coerce 'GetScanConfigRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanConfigRequest'->new($_) };

declare 'RepeatedGetScanConfigRequest',
    as ArrayRef[GetScanConfigRequest()];

coerce 'RepeatedGetScanConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetScanConfigRequest',
    as HashRef[GetScanConfigRequest()];

declare 'ListScanConfigsRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsRequest'];

coerce 'ListScanConfigsRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsRequest'->new($_) };

declare 'RepeatedListScanConfigsRequest',
    as ArrayRef[ListScanConfigsRequest()];

coerce 'RepeatedListScanConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListScanConfigsRequest',
    as HashRef[ListScanConfigsRequest()];

declare 'UpdateScanConfigRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::UpdateScanConfigRequest'];

coerce 'UpdateScanConfigRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::UpdateScanConfigRequest'->new($_) };

declare 'RepeatedUpdateScanConfigRequest',
    as ArrayRef[UpdateScanConfigRequest()];

coerce 'RepeatedUpdateScanConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::UpdateScanConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateScanConfigRequest',
    as HashRef[UpdateScanConfigRequest()];

declare 'ListScanConfigsResponse',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsResponse'];

coerce 'ListScanConfigsResponse',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsResponse'->new($_) };

declare 'RepeatedListScanConfigsResponse',
    as ArrayRef[ListScanConfigsResponse()];

coerce 'RepeatedListScanConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListScanConfigsResponse',
    as HashRef[ListScanConfigsResponse()];

declare 'StartScanRunRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StartScanRunRequest'];

coerce 'StartScanRunRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StartScanRunRequest'->new($_) };

declare 'RepeatedStartScanRunRequest',
    as ArrayRef[StartScanRunRequest()];

coerce 'RepeatedStartScanRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StartScanRunRequest'->new($_) } @$_ ] };

declare 'MapStringStartScanRunRequest',
    as HashRef[StartScanRunRequest()];

declare 'GetScanRunRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanRunRequest'];

coerce 'GetScanRunRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanRunRequest'->new($_) };

declare 'RepeatedGetScanRunRequest',
    as ArrayRef[GetScanRunRequest()];

coerce 'RepeatedGetScanRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetScanRunRequest',
    as HashRef[GetScanRunRequest()];

declare 'ListScanRunsRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsRequest'];

coerce 'ListScanRunsRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsRequest'->new($_) };

declare 'RepeatedListScanRunsRequest',
    as ArrayRef[ListScanRunsRequest()];

coerce 'RepeatedListScanRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListScanRunsRequest',
    as HashRef[ListScanRunsRequest()];

declare 'ListScanRunsResponse',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsResponse'];

coerce 'ListScanRunsResponse',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsResponse'->new($_) };

declare 'RepeatedListScanRunsResponse',
    as ArrayRef[ListScanRunsResponse()];

coerce 'RepeatedListScanRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListScanRunsResponse',
    as HashRef[ListScanRunsResponse()];

declare 'StopScanRunRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StopScanRunRequest'];

coerce 'StopScanRunRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StopScanRunRequest'->new($_) };

declare 'RepeatedStopScanRunRequest',
    as ArrayRef[StopScanRunRequest()];

coerce 'RepeatedStopScanRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StopScanRunRequest'->new($_) } @$_ ] };

declare 'MapStringStopScanRunRequest',
    as HashRef[StopScanRunRequest()];

declare 'ListCrawledUrlsRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsRequest'];

coerce 'ListCrawledUrlsRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsRequest'->new($_) };

declare 'RepeatedListCrawledUrlsRequest',
    as ArrayRef[ListCrawledUrlsRequest()];

coerce 'RepeatedListCrawledUrlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsRequest'->new($_) } @$_ ] };

declare 'MapStringListCrawledUrlsRequest',
    as HashRef[ListCrawledUrlsRequest()];

declare 'ListCrawledUrlsResponse',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsResponse'];

coerce 'ListCrawledUrlsResponse',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsResponse'->new($_) };

declare 'RepeatedListCrawledUrlsResponse',
    as ArrayRef[ListCrawledUrlsResponse()];

coerce 'RepeatedListCrawledUrlsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsResponse'->new($_) } @$_ ] };

declare 'MapStringListCrawledUrlsResponse',
    as HashRef[ListCrawledUrlsResponse()];

declare 'GetFindingRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetFindingRequest'];

coerce 'GetFindingRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetFindingRequest'->new($_) };

declare 'RepeatedGetFindingRequest',
    as ArrayRef[GetFindingRequest()];

coerce 'RepeatedGetFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetFindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetFindingRequest',
    as HashRef[GetFindingRequest()];

declare 'ListFindingsRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsRequest'];

coerce 'ListFindingsRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsRequest'->new($_) };

declare 'RepeatedListFindingsRequest',
    as ArrayRef[ListFindingsRequest()];

coerce 'RepeatedListFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingsRequest',
    as HashRef[ListFindingsRequest()];

declare 'ListFindingsResponse',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsResponse'];

coerce 'ListFindingsResponse',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsResponse'->new($_) };

declare 'RepeatedListFindingsResponse',
    as ArrayRef[ListFindingsResponse()];

coerce 'RepeatedListFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingsResponse',
    as HashRef[ListFindingsResponse()];

declare 'ListFindingTypeStatsRequest',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsRequest'];

coerce 'ListFindingTypeStatsRequest',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsRequest'->new($_) };

declare 'RepeatedListFindingTypeStatsRequest',
    as ArrayRef[ListFindingTypeStatsRequest()];

coerce 'RepeatedListFindingTypeStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingTypeStatsRequest',
    as HashRef[ListFindingTypeStatsRequest()];

declare 'ListFindingTypeStatsResponse',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsResponse'];

coerce 'ListFindingTypeStatsResponse',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsResponse'->new($_) };

declare 'RepeatedListFindingTypeStatsResponse',
    as ArrayRef[ListFindingTypeStatsResponse()];

coerce 'RepeatedListFindingTypeStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingTypeStatsResponse',
    as HashRef[ListFindingTypeStatsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
