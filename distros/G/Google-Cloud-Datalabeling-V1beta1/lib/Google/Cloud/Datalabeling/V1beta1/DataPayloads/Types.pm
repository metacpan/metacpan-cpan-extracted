package Google::Cloud::Datalabeling::V1beta1::DataPayloads::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ImagePayload',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload'];

coerce 'ImagePayload',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload'->new($_) };

declare 'RepeatedImagePayload',
    as ArrayRef[ImagePayload()];

coerce 'RepeatedImagePayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::ImagePayload'->new($_) } @$_ ] };

declare 'MapStringImagePayload',
    as HashRef[ImagePayload()];

declare 'TextPayload',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload'];

coerce 'TextPayload',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload'->new($_) };

declare 'RepeatedTextPayload',
    as ArrayRef[TextPayload()];

coerce 'RepeatedTextPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::TextPayload'->new($_) } @$_ ] };

declare 'MapStringTextPayload',
    as HashRef[TextPayload()];

declare 'VideoThumbnail',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoThumbnail'];

coerce 'VideoThumbnail',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoThumbnail'->new($_) };

declare 'RepeatedVideoThumbnail',
    as ArrayRef[VideoThumbnail()];

coerce 'RepeatedVideoThumbnail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoThumbnail'->new($_) } @$_ ] };

declare 'MapStringVideoThumbnail',
    as HashRef[VideoThumbnail()];

declare 'VideoPayload',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload'];

coerce 'VideoPayload',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload'->new($_) };

declare 'RepeatedVideoPayload',
    as ArrayRef[VideoPayload()];

coerce 'RepeatedVideoPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataPayloads::VideoPayload'->new($_) } @$_ ] };

declare 'MapStringVideoPayload',
    as HashRef[VideoPayload()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::DataPayloads::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
