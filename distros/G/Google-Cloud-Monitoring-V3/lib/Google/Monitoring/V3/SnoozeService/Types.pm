package Google::Monitoring::V3::SnoozeService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSnoozeRequest',
    as InstanceOf['Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest'];

coerce 'CreateSnoozeRequest',
    from HashRef, via { 'Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest'->new($_) };

declare 'RepeatedCreateSnoozeRequest',
    as ArrayRef[CreateSnoozeRequest()];

coerce 'RepeatedCreateSnoozeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSnoozeRequest',
    as HashRef[CreateSnoozeRequest()];

declare 'ListSnoozesRequest',
    as InstanceOf['Google::Monitoring::V3::SnoozeService::ListSnoozesRequest'];

coerce 'ListSnoozesRequest',
    from HashRef, via { 'Google::Monitoring::V3::SnoozeService::ListSnoozesRequest'->new($_) };

declare 'RepeatedListSnoozesRequest',
    as ArrayRef[ListSnoozesRequest()];

coerce 'RepeatedListSnoozesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::SnoozeService::ListSnoozesRequest'->new($_) } @$_ ] };

declare 'MapStringListSnoozesRequest',
    as HashRef[ListSnoozesRequest()];

declare 'ListSnoozesResponse',
    as InstanceOf['Google::Monitoring::V3::SnoozeService::ListSnoozesResponse'];

coerce 'ListSnoozesResponse',
    from HashRef, via { 'Google::Monitoring::V3::SnoozeService::ListSnoozesResponse'->new($_) };

declare 'RepeatedListSnoozesResponse',
    as ArrayRef[ListSnoozesResponse()];

coerce 'RepeatedListSnoozesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::SnoozeService::ListSnoozesResponse'->new($_) } @$_ ] };

declare 'MapStringListSnoozesResponse',
    as HashRef[ListSnoozesResponse()];

declare 'GetSnoozeRequest',
    as InstanceOf['Google::Monitoring::V3::SnoozeService::GetSnoozeRequest'];

coerce 'GetSnoozeRequest',
    from HashRef, via { 'Google::Monitoring::V3::SnoozeService::GetSnoozeRequest'->new($_) };

declare 'RepeatedGetSnoozeRequest',
    as ArrayRef[GetSnoozeRequest()];

coerce 'RepeatedGetSnoozeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::SnoozeService::GetSnoozeRequest'->new($_) } @$_ ] };

declare 'MapStringGetSnoozeRequest',
    as HashRef[GetSnoozeRequest()];

declare 'UpdateSnoozeRequest',
    as InstanceOf['Google::Monitoring::V3::SnoozeService::UpdateSnoozeRequest'];

coerce 'UpdateSnoozeRequest',
    from HashRef, via { 'Google::Monitoring::V3::SnoozeService::UpdateSnoozeRequest'->new($_) };

declare 'RepeatedUpdateSnoozeRequest',
    as ArrayRef[UpdateSnoozeRequest()];

coerce 'RepeatedUpdateSnoozeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::SnoozeService::UpdateSnoozeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSnoozeRequest',
    as HashRef[UpdateSnoozeRequest()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::SnoozeService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
