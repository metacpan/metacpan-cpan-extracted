package Google::Cloud::Video::Stitcher::V1::Sessions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VodSession',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::VodSession'];

coerce 'VodSession',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSession'->new($_) };

declare 'RepeatedVodSession',
    as ArrayRef[VodSession()];

coerce 'RepeatedVodSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSession'->new($_) } @$_ ] };

declare 'MapStringVodSession',
    as HashRef[VodSession()];

declare 'GamSettings',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::GamSettings'];

coerce 'GamSettings',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::GamSettings'->new($_) };

declare 'RepeatedGamSettings',
    as ArrayRef[GamSettings()];

coerce 'RepeatedGamSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::GamSettings'->new($_) } @$_ ] };

declare 'MapStringGamSettings',
    as HashRef[GamSettings()];

declare 'AdTagMacroMapEntry',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::AdTagMacroMapEntry'];

coerce 'AdTagMacroMapEntry',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::AdTagMacroMapEntry'->new($_) };

declare 'RepeatedAdTagMacroMapEntry',
    as ArrayRef[AdTagMacroMapEntry()];

coerce 'RepeatedAdTagMacroMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSession::AdTagMacroMapEntry'->new($_) } @$_ ] };

declare 'MapStringAdTagMacroMapEntry',
    as HashRef[AdTagMacroMapEntry()];

declare 'Interstitials',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::Interstitials'];

coerce 'Interstitials',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::Interstitials'->new($_) };

declare 'RepeatedInterstitials',
    as ArrayRef[Interstitials()];

coerce 'RepeatedInterstitials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::Interstitials'->new($_) } @$_ ] };

declare 'MapStringInterstitials',
    as HashRef[Interstitials()];

declare 'VodSessionAd',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAd'];

coerce 'VodSessionAd',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAd'->new($_) };

declare 'RepeatedVodSessionAd',
    as ArrayRef[VodSessionAd()];

coerce 'RepeatedVodSessionAd',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAd'->new($_) } @$_ ] };

declare 'MapStringVodSessionAd',
    as HashRef[VodSessionAd()];

declare 'VodSessionContent',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionContent'];

coerce 'VodSessionContent',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionContent'->new($_) };

declare 'RepeatedVodSessionContent',
    as ArrayRef[VodSessionContent()];

coerce 'RepeatedVodSessionContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionContent'->new($_) } @$_ ] };

declare 'MapStringVodSessionContent',
    as HashRef[VodSessionContent()];

declare 'VodSessionAdBreak',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAdBreak'];

coerce 'VodSessionAdBreak',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAdBreak'->new($_) };

declare 'RepeatedVodSessionAdBreak',
    as ArrayRef[VodSessionAdBreak()];

coerce 'RepeatedVodSessionAdBreak',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::VodSessionAdBreak'->new($_) } @$_ ] };

declare 'MapStringVodSessionAdBreak',
    as HashRef[VodSessionAdBreak()];

declare 'LiveSession',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession'];

coerce 'LiveSession',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession'->new($_) };

declare 'RepeatedLiveSession',
    as ArrayRef[LiveSession()];

coerce 'RepeatedLiveSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession'->new($_) } @$_ ] };

declare 'MapStringLiveSession',
    as HashRef[LiveSession()];

declare 'GamSettings',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings'];

coerce 'GamSettings',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings'->new($_) };

declare 'RepeatedGamSettings',
    as ArrayRef[GamSettings()];

coerce 'RepeatedGamSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings'->new($_) } @$_ ] };

declare 'MapStringGamSettings',
    as HashRef[GamSettings()];

declare 'TargetingParametersEntry',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings::TargetingParametersEntry'];

coerce 'TargetingParametersEntry',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings::TargetingParametersEntry'->new($_) };

declare 'RepeatedTargetingParametersEntry',
    as ArrayRef[TargetingParametersEntry()];

coerce 'RepeatedTargetingParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::GamSettings::TargetingParametersEntry'->new($_) } @$_ ] };

declare 'MapStringTargetingParametersEntry',
    as HashRef[TargetingParametersEntry()];

declare 'AdTagMacrosEntry',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::AdTagMacrosEntry'];

coerce 'AdTagMacrosEntry',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::AdTagMacrosEntry'->new($_) };

declare 'RepeatedAdTagMacrosEntry',
    as ArrayRef[AdTagMacrosEntry()];

coerce 'RepeatedAdTagMacrosEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::LiveSession::AdTagMacrosEntry'->new($_) } @$_ ] };

declare 'MapStringAdTagMacrosEntry',
    as HashRef[AdTagMacrosEntry()];

declare 'ManifestOptions',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions'];

coerce 'ManifestOptions',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions'->new($_) };

declare 'RepeatedManifestOptions',
    as ArrayRef[ManifestOptions()];

coerce 'RepeatedManifestOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::ManifestOptions'->new($_) } @$_ ] };

declare 'MapStringManifestOptions',
    as HashRef[ManifestOptions()];

declare 'OrderPolicy',
    as (Int | Str);

declare 'RenditionFilter',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Sessions::RenditionFilter'];

coerce 'RenditionFilter',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Sessions::RenditionFilter'->new($_) };

declare 'RepeatedRenditionFilter',
    as ArrayRef[RenditionFilter()];

coerce 'RepeatedRenditionFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Sessions::RenditionFilter'->new($_) } @$_ ] };

declare 'MapStringRenditionFilter',
    as HashRef[RenditionFilter()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Sessions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
