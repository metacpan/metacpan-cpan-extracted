package Google::Cloud::Video::Stitcher::V1::VodConfigs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VodConfig',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig'];

coerce 'VodConfig',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig'->new($_) };

declare 'RepeatedVodConfig',
    as ArrayRef[VodConfig()];

coerce 'RepeatedVodConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VodConfigs::VodConfig'->new($_) } @$_ ] };

declare 'MapStringVodConfig',
    as HashRef[VodConfig()];

declare 'State',
    as (Int | Str);

declare 'GamVodConfig',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::VodConfigs::GamVodConfig'];

coerce 'GamVodConfig',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::VodConfigs::GamVodConfig'->new($_) };

declare 'RepeatedGamVodConfig',
    as ArrayRef[GamVodConfig()];

coerce 'RepeatedGamVodConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::VodConfigs::GamVodConfig'->new($_) } @$_ ] };

declare 'MapStringGamVodConfig',
    as HashRef[GamVodConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::VodConfigs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
