package Google::Cloud::Video::Stitcher::V1::AdTagDetails::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LiveAdTagDetail',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail'];

coerce 'LiveAdTagDetail',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail'->new($_) };

declare 'RepeatedLiveAdTagDetail',
    as ArrayRef[LiveAdTagDetail()];

coerce 'RepeatedLiveAdTagDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::LiveAdTagDetail'->new($_) } @$_ ] };

declare 'MapStringLiveAdTagDetail',
    as HashRef[LiveAdTagDetail()];

declare 'VodAdTagDetail',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::AdTagDetails::VodAdTagDetail'];

coerce 'VodAdTagDetail',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::VodAdTagDetail'->new($_) };

declare 'RepeatedVodAdTagDetail',
    as ArrayRef[VodAdTagDetail()];

coerce 'RepeatedVodAdTagDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::VodAdTagDetail'->new($_) } @$_ ] };

declare 'MapStringVodAdTagDetail',
    as HashRef[VodAdTagDetail()];

declare 'AdRequest',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest'];

coerce 'AdRequest',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest'->new($_) };

declare 'RepeatedAdRequest',
    as ArrayRef[AdRequest()];

coerce 'RepeatedAdRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::AdRequest'->new($_) } @$_ ] };

declare 'MapStringAdRequest',
    as HashRef[AdRequest()];

declare 'RequestMetadata',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::AdTagDetails::RequestMetadata'];

coerce 'RequestMetadata',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::RequestMetadata'->new($_) };

declare 'RepeatedRequestMetadata',
    as ArrayRef[RequestMetadata()];

coerce 'RepeatedRequestMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::RequestMetadata'->new($_) } @$_ ] };

declare 'MapStringRequestMetadata',
    as HashRef[RequestMetadata()];

declare 'ResponseMetadata',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::AdTagDetails::ResponseMetadata'];

coerce 'ResponseMetadata',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::ResponseMetadata'->new($_) };

declare 'RepeatedResponseMetadata',
    as ArrayRef[ResponseMetadata()];

coerce 'RepeatedResponseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::AdTagDetails::ResponseMetadata'->new($_) } @$_ ] };

declare 'MapStringResponseMetadata',
    as HashRef[ResponseMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::AdTagDetails::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
