package Google::Cloud::Video::Stitcher::V1::LiveConfigs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AdTracking',
    as (Int | Str);

declare 'LiveConfig',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig'];

coerce 'LiveConfig',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig'->new($_) };

declare 'RepeatedLiveConfig',
    as ArrayRef[LiveConfig()];

coerce 'RepeatedLiveConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::LiveConfigs::LiveConfig'->new($_) } @$_ ] };

declare 'MapStringLiveConfig',
    as HashRef[LiveConfig()];

declare 'State',
    as (Int | Str);

declare 'StitchingPolicy',
    as (Int | Str);

declare 'PrefetchConfig',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::LiveConfigs::PrefetchConfig'];

coerce 'PrefetchConfig',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::LiveConfigs::PrefetchConfig'->new($_) };

declare 'RepeatedPrefetchConfig',
    as ArrayRef[PrefetchConfig()];

coerce 'RepeatedPrefetchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::LiveConfigs::PrefetchConfig'->new($_) } @$_ ] };

declare 'MapStringPrefetchConfig',
    as HashRef[PrefetchConfig()];

declare 'GamLiveConfig',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::LiveConfigs::GamLiveConfig'];

coerce 'GamLiveConfig',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::LiveConfigs::GamLiveConfig'->new($_) };

declare 'RepeatedGamLiveConfig',
    as ArrayRef[GamLiveConfig()];

coerce 'RepeatedGamLiveConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::LiveConfigs::GamLiveConfig'->new($_) } @$_ ] };

declare 'MapStringGamLiveConfig',
    as HashRef[GamLiveConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::LiveConfigs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
