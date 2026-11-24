package Google::Chromeos::Moblab::V1beta1::TestService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSessionRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest'];

coerce 'CreateSessionRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest'->new($_) };

declare 'RepeatedCreateSessionRequest',
    as ArrayRef[CreateSessionRequest()];

coerce 'RepeatedCreateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionRequest',
    as HashRef[CreateSessionRequest()];

declare 'GetSessionRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest'];

coerce 'GetSessionRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest'->new($_) };

declare 'RepeatedGetSessionRequest',
    as ArrayRef[GetSessionRequest()];

coerce 'RepeatedGetSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSessionRequest',
    as HashRef[GetSessionRequest()];

declare 'ListTestEffortsRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest'];

coerce 'ListTestEffortsRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest'->new($_) };

declare 'RepeatedListTestEffortsRequest',
    as ArrayRef[ListTestEffortsRequest()];

coerce 'RepeatedListTestEffortsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest'->new($_) } @$_ ] };

declare 'MapStringListTestEffortsRequest',
    as HashRef[ListTestEffortsRequest()];

declare 'ListTestEffortsResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse'];

coerce 'ListTestEffortsResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse'->new($_) };

declare 'RepeatedListTestEffortsResponse',
    as ArrayRef[ListTestEffortsResponse()];

coerce 'RepeatedListTestEffortsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse'->new($_) } @$_ ] };

declare 'MapStringListTestEffortsResponse',
    as HashRef[ListTestEffortsResponse()];

declare 'CancelTestEffortRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest'];

coerce 'CancelTestEffortRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest'->new($_) };

declare 'RepeatedCancelTestEffortRequest',
    as ArrayRef[CancelTestEffortRequest()];

coerce 'RepeatedCancelTestEffortRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest'->new($_) } @$_ ] };

declare 'MapStringCancelTestEffortRequest',
    as HashRef[CancelTestEffortRequest()];

declare 'CancelTestEffortResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse'];

coerce 'CancelTestEffortResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse'->new($_) };

declare 'RepeatedCancelTestEffortResponse',
    as ArrayRef[CancelTestEffortResponse()];

coerce 'RepeatedCancelTestEffortResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse'->new($_) } @$_ ] };

declare 'MapStringCancelTestEffortResponse',
    as HashRef[CancelTestEffortResponse()];

declare 'CreateTestEffortRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest'];

coerce 'CreateTestEffortRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest'->new($_) };

declare 'RepeatedCreateTestEffortRequest',
    as ArrayRef[CreateTestEffortRequest()];

coerce 'RepeatedCreateTestEffortRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTestEffortRequest',
    as HashRef[CreateTestEffortRequest()];

declare 'ListSessionsRequest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest'];

coerce 'ListSessionsRequest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest'->new($_) };

declare 'RepeatedListSessionsRequest',
    as ArrayRef[ListSessionsRequest()];

coerce 'RepeatedListSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSessionsRequest',
    as HashRef[ListSessionsRequest()];

declare 'ListSessionsResponse',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse'];

coerce 'ListSessionsResponse',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse'->new($_) };

declare 'RepeatedListSessionsResponse',
    as ArrayRef[ListSessionsResponse()];

coerce 'RepeatedListSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSessionsResponse',
    as HashRef[ListSessionsResponse()];

1;

__END__

=head1 NAME

Google::Chromeos::Moblab::V1beta1::TestService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
