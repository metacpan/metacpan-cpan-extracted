package Google::Cloud::Support::V2beta::FeedService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ShowFeedRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest'];

coerce 'ShowFeedRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest'->new($_) };

declare 'RepeatedShowFeedRequest',
    as ArrayRef[ShowFeedRequest()];

coerce 'RepeatedShowFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest'->new($_) } @$_ ] };

declare 'MapStringShowFeedRequest',
    as HashRef[ShowFeedRequest()];

declare 'ShowFeedResponse',
    as InstanceOf['Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse'];

coerce 'ShowFeedResponse',
    from HashRef, via { 'Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse'->new($_) };

declare 'RepeatedShowFeedResponse',
    as ArrayRef[ShowFeedResponse()];

coerce 'RepeatedShowFeedResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse'->new($_) } @$_ ] };

declare 'MapStringShowFeedResponse',
    as HashRef[ShowFeedResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::FeedService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
