package Google::Cloud::Video::Stitcher::V1::Companions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompanionAds',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds'];

coerce 'CompanionAds',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds'->new($_) };

declare 'RepeatedCompanionAds',
    as ArrayRef[CompanionAds()];

coerce 'RepeatedCompanionAds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Companions::CompanionAds'->new($_) } @$_ ] };

declare 'MapStringCompanionAds',
    as HashRef[CompanionAds()];

declare 'DisplayRequirement',
    as (Int | Str);

declare 'Companion',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Companions::Companion'];

coerce 'Companion',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Companions::Companion'->new($_) };

declare 'RepeatedCompanion',
    as ArrayRef[Companion()];

coerce 'RepeatedCompanion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Companions::Companion'->new($_) } @$_ ] };

declare 'MapStringCompanion',
    as HashRef[Companion()];

declare 'HtmlAdResource',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Companions::HtmlAdResource'];

coerce 'HtmlAdResource',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Companions::HtmlAdResource'->new($_) };

declare 'RepeatedHtmlAdResource',
    as ArrayRef[HtmlAdResource()];

coerce 'RepeatedHtmlAdResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Companions::HtmlAdResource'->new($_) } @$_ ] };

declare 'MapStringHtmlAdResource',
    as HashRef[HtmlAdResource()];

declare 'IframeAdResource',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Companions::IframeAdResource'];

coerce 'IframeAdResource',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Companions::IframeAdResource'->new($_) };

declare 'RepeatedIframeAdResource',
    as ArrayRef[IframeAdResource()];

coerce 'RepeatedIframeAdResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Companions::IframeAdResource'->new($_) } @$_ ] };

declare 'MapStringIframeAdResource',
    as HashRef[IframeAdResource()];

declare 'StaticAdResource',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Companions::StaticAdResource'];

coerce 'StaticAdResource',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Companions::StaticAdResource'->new($_) };

declare 'RepeatedStaticAdResource',
    as ArrayRef[StaticAdResource()];

coerce 'RepeatedStaticAdResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Companions::StaticAdResource'->new($_) } @$_ ] };

declare 'MapStringStaticAdResource',
    as HashRef[StaticAdResource()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Companions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
