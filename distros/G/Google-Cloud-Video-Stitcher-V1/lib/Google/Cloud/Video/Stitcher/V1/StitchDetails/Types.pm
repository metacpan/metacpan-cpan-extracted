package Google::Cloud::Video::Stitcher::V1::StitchDetails::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VodStitchDetail',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail'];

coerce 'VodStitchDetail',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail'->new($_) };

declare 'RepeatedVodStitchDetail',
    as ArrayRef[VodStitchDetail()];

coerce 'RepeatedVodStitchDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::StitchDetails::VodStitchDetail'->new($_) } @$_ ] };

declare 'MapStringVodStitchDetail',
    as HashRef[VodStitchDetail()];

declare 'AdStitchDetail',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail'];

coerce 'AdStitchDetail',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail'->new($_) };

declare 'RepeatedAdStitchDetail',
    as ArrayRef[AdStitchDetail()];

coerce 'RepeatedAdStitchDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail'->new($_) } @$_ ] };

declare 'MapStringAdStitchDetail',
    as HashRef[AdStitchDetail()];

declare 'MediaEntry',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail::MediaEntry'];

coerce 'MediaEntry',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail::MediaEntry'->new($_) };

declare 'RepeatedMediaEntry',
    as ArrayRef[MediaEntry()];

coerce 'RepeatedMediaEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::StitchDetails::AdStitchDetail::MediaEntry'->new($_) } @$_ ] };

declare 'MapStringMediaEntry',
    as HashRef[MediaEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::StitchDetails::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
