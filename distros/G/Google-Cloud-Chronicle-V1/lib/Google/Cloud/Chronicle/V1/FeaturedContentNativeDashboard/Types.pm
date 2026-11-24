package Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FeaturedContentNativeDashboard',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard'];

coerce 'FeaturedContentNativeDashboard',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard'->new($_) };

declare 'RepeatedFeaturedContentNativeDashboard',
    as ArrayRef[FeaturedContentNativeDashboard()];

coerce 'RepeatedFeaturedContentNativeDashboard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard'->new($_) } @$_ ] };

declare 'MapStringFeaturedContentNativeDashboard',
    as HashRef[FeaturedContentNativeDashboard()];

declare 'GetFeaturedContentNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest'];

coerce 'GetFeaturedContentNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest'->new($_) };

declare 'RepeatedGetFeaturedContentNativeDashboardRequest',
    as ArrayRef[GetFeaturedContentNativeDashboardRequest()];

coerce 'RepeatedGetFeaturedContentNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeaturedContentNativeDashboardRequest',
    as HashRef[GetFeaturedContentNativeDashboardRequest()];

declare 'ListFeaturedContentNativeDashboardsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsRequest'];

coerce 'ListFeaturedContentNativeDashboardsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsRequest'->new($_) };

declare 'RepeatedListFeaturedContentNativeDashboardsRequest',
    as ArrayRef[ListFeaturedContentNativeDashboardsRequest()];

coerce 'RepeatedListFeaturedContentNativeDashboardsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsRequest'->new($_) } @$_ ] };

declare 'MapStringListFeaturedContentNativeDashboardsRequest',
    as HashRef[ListFeaturedContentNativeDashboardsRequest()];

declare 'ListFeaturedContentNativeDashboardsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsResponse'];

coerce 'ListFeaturedContentNativeDashboardsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsResponse'->new($_) };

declare 'RepeatedListFeaturedContentNativeDashboardsResponse',
    as ArrayRef[ListFeaturedContentNativeDashboardsResponse()];

coerce 'RepeatedListFeaturedContentNativeDashboardsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::ListFeaturedContentNativeDashboardsResponse'->new($_) } @$_ ] };

declare 'MapStringListFeaturedContentNativeDashboardsResponse',
    as HashRef[ListFeaturedContentNativeDashboardsResponse()];

declare 'InstallFeaturedContentNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest'];

coerce 'InstallFeaturedContentNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest'->new($_) };

declare 'RepeatedInstallFeaturedContentNativeDashboardRequest',
    as ArrayRef[InstallFeaturedContentNativeDashboardRequest()];

coerce 'RepeatedInstallFeaturedContentNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringInstallFeaturedContentNativeDashboardRequest',
    as HashRef[InstallFeaturedContentNativeDashboardRequest()];

declare 'InstallFeaturedContentNativeDashboardResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse'];

coerce 'InstallFeaturedContentNativeDashboardResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse'->new($_) };

declare 'RepeatedInstallFeaturedContentNativeDashboardResponse',
    as ArrayRef[InstallFeaturedContentNativeDashboardResponse()];

coerce 'RepeatedInstallFeaturedContentNativeDashboardResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse'->new($_) } @$_ ] };

declare 'MapStringInstallFeaturedContentNativeDashboardResponse',
    as HashRef[InstallFeaturedContentNativeDashboardResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
