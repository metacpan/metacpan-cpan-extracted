package Google::Cloud::Video::Stitcher::V1::CdnKeys::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CdnKey',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey'];

coerce 'CdnKey',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey'->new($_) };

declare 'RepeatedCdnKey',
    as ArrayRef[CdnKey()];

coerce 'RepeatedCdnKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::CdnKey'->new($_) } @$_ ] };

declare 'MapStringCdnKey',
    as HashRef[CdnKey()];

declare 'GoogleCdnKey',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::CdnKeys::GoogleCdnKey'];

coerce 'GoogleCdnKey',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::GoogleCdnKey'->new($_) };

declare 'RepeatedGoogleCdnKey',
    as ArrayRef[GoogleCdnKey()];

coerce 'RepeatedGoogleCdnKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::GoogleCdnKey'->new($_) } @$_ ] };

declare 'MapStringGoogleCdnKey',
    as HashRef[GoogleCdnKey()];

declare 'AkamaiCdnKey',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::CdnKeys::AkamaiCdnKey'];

coerce 'AkamaiCdnKey',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::AkamaiCdnKey'->new($_) };

declare 'RepeatedAkamaiCdnKey',
    as ArrayRef[AkamaiCdnKey()];

coerce 'RepeatedAkamaiCdnKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::AkamaiCdnKey'->new($_) } @$_ ] };

declare 'MapStringAkamaiCdnKey',
    as HashRef[AkamaiCdnKey()];

declare 'MediaCdnKey',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey'];

coerce 'MediaCdnKey',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey'->new($_) };

declare 'RepeatedMediaCdnKey',
    as ArrayRef[MediaCdnKey()];

coerce 'RepeatedMediaCdnKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey'->new($_) } @$_ ] };

declare 'MapStringMediaCdnKey',
    as HashRef[MediaCdnKey()];

declare 'TokenConfig',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey::TokenConfig'];

coerce 'TokenConfig',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey::TokenConfig'->new($_) };

declare 'RepeatedTokenConfig',
    as ArrayRef[TokenConfig()];

coerce 'RepeatedTokenConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::CdnKeys::MediaCdnKey::TokenConfig'->new($_) } @$_ ] };

declare 'MapStringTokenConfig',
    as HashRef[TokenConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::CdnKeys::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
