package Google::Cloud::Video::Stitcher::V1::Slates::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Slate',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Slates::Slate'];

coerce 'Slate',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Slates::Slate'->new($_) };

declare 'RepeatedSlate',
    as ArrayRef[Slate()];

coerce 'RepeatedSlate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Slates::Slate'->new($_) } @$_ ] };

declare 'MapStringSlate',
    as HashRef[Slate()];

declare 'GamSlate',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Slates::Slate::GamSlate'];

coerce 'GamSlate',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Slates::Slate::GamSlate'->new($_) };

declare 'RepeatedGamSlate',
    as ArrayRef[GamSlate()];

coerce 'RepeatedGamSlate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Slates::Slate::GamSlate'->new($_) } @$_ ] };

declare 'MapStringGamSlate',
    as HashRef[GamSlate()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Slates::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
