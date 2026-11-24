package Google::Cloud::Locationfinder::V1::CloudLocation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudLocation',
    as InstanceOf['Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation'];

coerce 'CloudLocation',
    from HashRef, via { 'Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation'->new($_) };

declare 'RepeatedCloudLocation',
    as ArrayRef[CloudLocation()];

coerce 'RepeatedCloudLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Locationfinder::V1::CloudLocation::CloudLocation'->new($_) } @$_ ] };

declare 'MapStringCloudLocation',
    as HashRef[CloudLocation()];

declare 'CloudProvider',
    as (Int | Str);

declare 'CloudLocationType',
    as (Int | Str);

declare 'ListCloudLocationsRequest',
    as InstanceOf['Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsRequest'];

coerce 'ListCloudLocationsRequest',
    from HashRef, via { 'Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsRequest'->new($_) };

declare 'RepeatedListCloudLocationsRequest',
    as ArrayRef[ListCloudLocationsRequest()];

coerce 'RepeatedListCloudLocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsRequest'->new($_) } @$_ ] };

declare 'MapStringListCloudLocationsRequest',
    as HashRef[ListCloudLocationsRequest()];

declare 'ListCloudLocationsResponse',
    as InstanceOf['Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsResponse'];

coerce 'ListCloudLocationsResponse',
    from HashRef, via { 'Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsResponse'->new($_) };

declare 'RepeatedListCloudLocationsResponse',
    as ArrayRef[ListCloudLocationsResponse()];

coerce 'RepeatedListCloudLocationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Locationfinder::V1::CloudLocation::ListCloudLocationsResponse'->new($_) } @$_ ] };

declare 'MapStringListCloudLocationsResponse',
    as HashRef[ListCloudLocationsResponse()];

declare 'GetCloudLocationRequest',
    as InstanceOf['Google::Cloud::Locationfinder::V1::CloudLocation::GetCloudLocationRequest'];

coerce 'GetCloudLocationRequest',
    from HashRef, via { 'Google::Cloud::Locationfinder::V1::CloudLocation::GetCloudLocationRequest'->new($_) };

declare 'RepeatedGetCloudLocationRequest',
    as ArrayRef[GetCloudLocationRequest()];

coerce 'RepeatedGetCloudLocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Locationfinder::V1::CloudLocation::GetCloudLocationRequest'->new($_) } @$_ ] };

declare 'MapStringGetCloudLocationRequest',
    as HashRef[GetCloudLocationRequest()];

declare 'SearchCloudLocationsRequest',
    as InstanceOf['Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsRequest'];

coerce 'SearchCloudLocationsRequest',
    from HashRef, via { 'Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsRequest'->new($_) };

declare 'RepeatedSearchCloudLocationsRequest',
    as ArrayRef[SearchCloudLocationsRequest()];

coerce 'RepeatedSearchCloudLocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchCloudLocationsRequest',
    as HashRef[SearchCloudLocationsRequest()];

declare 'SearchCloudLocationsResponse',
    as InstanceOf['Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsResponse'];

coerce 'SearchCloudLocationsResponse',
    from HashRef, via { 'Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsResponse'->new($_) };

declare 'RepeatedSearchCloudLocationsResponse',
    as ArrayRef[SearchCloudLocationsResponse()];

coerce 'RepeatedSearchCloudLocationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Locationfinder::V1::CloudLocation::SearchCloudLocationsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchCloudLocationsResponse',
    as HashRef[SearchCloudLocationsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Locationfinder::V1::CloudLocation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
