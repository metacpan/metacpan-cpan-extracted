package Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AccessApprovalRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest'];

coerce 'AccessApprovalRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest'->new($_) };

declare 'RepeatedAccessApprovalRequest',
    as ArrayRef[AccessApprovalRequest()];

coerce 'RepeatedAccessApprovalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessApprovalRequest'->new($_) } @$_ ] };

declare 'MapStringAccessApprovalRequest',
    as HashRef[AccessApprovalRequest()];

declare 'ListAccessApprovalRequestsRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsRequest'];

coerce 'ListAccessApprovalRequestsRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsRequest'->new($_) };

declare 'RepeatedListAccessApprovalRequestsRequest',
    as ArrayRef[ListAccessApprovalRequestsRequest()];

coerce 'RepeatedListAccessApprovalRequestsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsRequest'->new($_) } @$_ ] };

declare 'MapStringListAccessApprovalRequestsRequest',
    as HashRef[ListAccessApprovalRequestsRequest()];

declare 'ListAccessApprovalRequestsResponse',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsResponse'];

coerce 'ListAccessApprovalRequestsResponse',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsResponse'->new($_) };

declare 'RepeatedListAccessApprovalRequestsResponse',
    as ArrayRef[ListAccessApprovalRequestsResponse()];

coerce 'RepeatedListAccessApprovalRequestsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::ListAccessApprovalRequestsResponse'->new($_) } @$_ ] };

declare 'MapStringListAccessApprovalRequestsResponse',
    as HashRef[ListAccessApprovalRequestsResponse()];

declare 'AccessReason',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessReason'];

coerce 'AccessReason',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessReason'->new($_) };

declare 'RepeatedAccessReason',
    as ArrayRef[AccessReason()];

coerce 'RepeatedAccessReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::AccessReason'->new($_) } @$_ ] };

declare 'MapStringAccessReason',
    as HashRef[AccessReason()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
