package Google::Cloud::Video::Stitcher::V1::Events::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Event',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Events::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Events::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Events::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'EventType',
    as (Int | Str);

declare 'ProgressEvent',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::Events::ProgressEvent'];

coerce 'ProgressEvent',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::Events::ProgressEvent'->new($_) };

declare 'RepeatedProgressEvent',
    as ArrayRef[ProgressEvent()];

coerce 'RepeatedProgressEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::Events::ProgressEvent'->new($_) } @$_ ] };

declare 'MapStringProgressEvent',
    as HashRef[ProgressEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::Events::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
