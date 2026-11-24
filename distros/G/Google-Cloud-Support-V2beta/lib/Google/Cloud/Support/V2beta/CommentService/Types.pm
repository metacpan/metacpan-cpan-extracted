package Google::Cloud::Support::V2beta::CommentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCommentsRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest'];

coerce 'ListCommentsRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest'->new($_) };

declare 'RepeatedListCommentsRequest',
    as ArrayRef[ListCommentsRequest()];

coerce 'RepeatedListCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringListCommentsRequest',
    as HashRef[ListCommentsRequest()];

declare 'ListCommentsResponse',
    as InstanceOf['Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse'];

coerce 'ListCommentsResponse',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse'->new($_) };

declare 'RepeatedListCommentsResponse',
    as ArrayRef[ListCommentsResponse()];

coerce 'RepeatedListCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringListCommentsResponse',
    as HashRef[ListCommentsResponse()];

declare 'CreateCommentRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CommentService::CreateCommentRequest'];

coerce 'CreateCommentRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CommentService::CreateCommentRequest'->new($_) };

declare 'RepeatedCreateCommentRequest',
    as ArrayRef[CreateCommentRequest()];

coerce 'RepeatedCreateCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CommentService::CreateCommentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCommentRequest',
    as HashRef[CreateCommentRequest()];

declare 'GetCommentRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CommentService::GetCommentRequest'];

coerce 'GetCommentRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CommentService::GetCommentRequest'->new($_) };

declare 'RepeatedGetCommentRequest',
    as ArrayRef[GetCommentRequest()];

coerce 'RepeatedGetCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CommentService::GetCommentRequest'->new($_) } @$_ ] };

declare 'MapStringGetCommentRequest',
    as HashRef[GetCommentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::CommentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
