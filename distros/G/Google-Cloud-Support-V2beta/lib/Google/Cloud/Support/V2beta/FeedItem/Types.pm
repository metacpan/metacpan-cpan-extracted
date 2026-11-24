package Google::Cloud::Support::V2beta::FeedItem::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FeedItem',
    as InstanceOf['Google::Cloud::Support::V2beta::FeedItem::FeedItem'];

coerce 'FeedItem',
    from HashRef, via { 'Google::Cloud::Support::V2beta::FeedItem::FeedItem'->new($_) };

declare 'RepeatedFeedItem',
    as ArrayRef[FeedItem()];

coerce 'RepeatedFeedItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::FeedItem::FeedItem'->new($_) } @$_ ] };

declare 'MapStringFeedItem',
    as HashRef[FeedItem()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::FeedItem::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
