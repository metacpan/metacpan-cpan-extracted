package Google::Cloud::Discoveryengine::V1beta::UserLicenseService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListUserLicensesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest'];

coerce 'ListUserLicensesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest'->new($_) };

declare 'RepeatedListUserLicensesRequest',
    as ArrayRef[ListUserLicensesRequest()];

coerce 'RepeatedListUserLicensesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest'->new($_) } @$_ ] };

declare 'MapStringListUserLicensesRequest',
    as HashRef[ListUserLicensesRequest()];

declare 'ListUserLicensesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse'];

coerce 'ListUserLicensesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse'->new($_) };

declare 'RepeatedListUserLicensesResponse',
    as ArrayRef[ListUserLicensesResponse()];

coerce 'RepeatedListUserLicensesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse'->new($_) } @$_ ] };

declare 'MapStringListUserLicensesResponse',
    as HashRef[ListUserLicensesResponse()];

declare 'ListLicenseConfigsUsageStatsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsRequest'];

coerce 'ListLicenseConfigsUsageStatsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsRequest'->new($_) };

declare 'RepeatedListLicenseConfigsUsageStatsRequest',
    as ArrayRef[ListLicenseConfigsUsageStatsRequest()];

coerce 'RepeatedListLicenseConfigsUsageStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsRequest'->new($_) } @$_ ] };

declare 'MapStringListLicenseConfigsUsageStatsRequest',
    as HashRef[ListLicenseConfigsUsageStatsRequest()];

declare 'ListLicenseConfigsUsageStatsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsResponse'];

coerce 'ListLicenseConfigsUsageStatsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsResponse'->new($_) };

declare 'RepeatedListLicenseConfigsUsageStatsResponse',
    as ArrayRef[ListLicenseConfigsUsageStatsResponse()];

coerce 'RepeatedListLicenseConfigsUsageStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsResponse'->new($_) } @$_ ] };

declare 'MapStringListLicenseConfigsUsageStatsResponse',
    as HashRef[ListLicenseConfigsUsageStatsResponse()];

declare 'BatchUpdateUserLicensesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest'];

coerce 'BatchUpdateUserLicensesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest'->new($_) };

declare 'RepeatedBatchUpdateUserLicensesRequest',
    as ArrayRef[BatchUpdateUserLicensesRequest()];

coerce 'RepeatedBatchUpdateUserLicensesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateUserLicensesRequest',
    as HashRef[BatchUpdateUserLicensesRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'BatchUpdateUserLicensesMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesMetadata'];

coerce 'BatchUpdateUserLicensesMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesMetadata'->new($_) };

declare 'RepeatedBatchUpdateUserLicensesMetadata',
    as ArrayRef[BatchUpdateUserLicensesMetadata()];

coerce 'RepeatedBatchUpdateUserLicensesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateUserLicensesMetadata',
    as HashRef[BatchUpdateUserLicensesMetadata()];

declare 'BatchUpdateUserLicensesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesResponse'];

coerce 'BatchUpdateUserLicensesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesResponse'->new($_) };

declare 'RepeatedBatchUpdateUserLicensesResponse',
    as ArrayRef[BatchUpdateUserLicensesResponse()];

coerce 'RepeatedBatchUpdateUserLicensesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateUserLicensesResponse',
    as HashRef[BatchUpdateUserLicensesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserLicenseService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
