package Google::Spanner::Adapter::V1::Adapter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AdaptMessageRequest',
    as InstanceOf['Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest'];

coerce 'AdaptMessageRequest',
    from HashRef, via { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest'->new($_) };

declare 'RepeatedAdaptMessageRequest',
    as ArrayRef[AdaptMessageRequest()];

coerce 'RepeatedAdaptMessageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest'->new($_) } @$_ ] };

declare 'MapStringAdaptMessageRequest',
    as HashRef[AdaptMessageRequest()];

declare 'AttachmentsEntry',
    as InstanceOf['Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest::AttachmentsEntry'];

coerce 'AttachmentsEntry',
    from HashRef, via { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest::AttachmentsEntry'->new($_) };

declare 'RepeatedAttachmentsEntry',
    as ArrayRef[AttachmentsEntry()];

coerce 'RepeatedAttachmentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest::AttachmentsEntry'->new($_) } @$_ ] };

declare 'MapStringAttachmentsEntry',
    as HashRef[AttachmentsEntry()];

declare 'AdaptMessageResponse',
    as InstanceOf['Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse'];

coerce 'AdaptMessageResponse',
    from HashRef, via { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse'->new($_) };

declare 'RepeatedAdaptMessageResponse',
    as ArrayRef[AdaptMessageResponse()];

coerce 'RepeatedAdaptMessageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse'->new($_) } @$_ ] };

declare 'MapStringAdaptMessageResponse',
    as HashRef[AdaptMessageResponse()];

declare 'StateUpdatesEntry',
    as InstanceOf['Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse::StateUpdatesEntry'];

coerce 'StateUpdatesEntry',
    from HashRef, via { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse::StateUpdatesEntry'->new($_) };

declare 'RepeatedStateUpdatesEntry',
    as ArrayRef[StateUpdatesEntry()];

coerce 'RepeatedStateUpdatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse::StateUpdatesEntry'->new($_) } @$_ ] };

declare 'MapStringStateUpdatesEntry',
    as HashRef[StateUpdatesEntry()];

declare 'Session',
    as InstanceOf['Google::Spanner::Adapter::V1::Adapter::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Spanner::Adapter::V1::Adapter::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Adapter::V1::Adapter::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

declare 'CreateSessionRequest',
    as InstanceOf['Google::Spanner::Adapter::V1::Adapter::CreateSessionRequest'];

coerce 'CreateSessionRequest',
    from HashRef, via { 'Google::Spanner::Adapter::V1::Adapter::CreateSessionRequest'->new($_) };

declare 'RepeatedCreateSessionRequest',
    as ArrayRef[CreateSessionRequest()];

coerce 'RepeatedCreateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Adapter::V1::Adapter::CreateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionRequest',
    as HashRef[CreateSessionRequest()];

1;

__END__

=head1 NAME

Google::Spanner::Adapter::V1::Adapter::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
