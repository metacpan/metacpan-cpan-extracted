package Google::Cloud::Networkmanagement::V1::Reachability::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListConnectivityTestsRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest'];

coerce 'ListConnectivityTestsRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest'->new($_) };

declare 'RepeatedListConnectivityTestsRequest',
    as ArrayRef[ListConnectivityTestsRequest()];

coerce 'RepeatedListConnectivityTestsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectivityTestsRequest',
    as HashRef[ListConnectivityTestsRequest()];

declare 'ListConnectivityTestsResponse',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse'];

coerce 'ListConnectivityTestsResponse',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse'->new($_) };

declare 'RepeatedListConnectivityTestsResponse',
    as ArrayRef[ListConnectivityTestsResponse()];

coerce 'RepeatedListConnectivityTestsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectivityTestsResponse',
    as HashRef[ListConnectivityTestsResponse()];

declare 'GetConnectivityTestRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::GetConnectivityTestRequest'];

coerce 'GetConnectivityTestRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::GetConnectivityTestRequest'->new($_) };

declare 'RepeatedGetConnectivityTestRequest',
    as ArrayRef[GetConnectivityTestRequest()];

coerce 'RepeatedGetConnectivityTestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::GetConnectivityTestRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectivityTestRequest',
    as HashRef[GetConnectivityTestRequest()];

declare 'CreateConnectivityTestRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::CreateConnectivityTestRequest'];

coerce 'CreateConnectivityTestRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::CreateConnectivityTestRequest'->new($_) };

declare 'RepeatedCreateConnectivityTestRequest',
    as ArrayRef[CreateConnectivityTestRequest()];

coerce 'RepeatedCreateConnectivityTestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::CreateConnectivityTestRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectivityTestRequest',
    as HashRef[CreateConnectivityTestRequest()];

declare 'UpdateConnectivityTestRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest'];

coerce 'UpdateConnectivityTestRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest'->new($_) };

declare 'RepeatedUpdateConnectivityTestRequest',
    as ArrayRef[UpdateConnectivityTestRequest()];

coerce 'RepeatedUpdateConnectivityTestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectivityTestRequest',
    as HashRef[UpdateConnectivityTestRequest()];

declare 'DeleteConnectivityTestRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::DeleteConnectivityTestRequest'];

coerce 'DeleteConnectivityTestRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::DeleteConnectivityTestRequest'->new($_) };

declare 'RepeatedDeleteConnectivityTestRequest',
    as ArrayRef[DeleteConnectivityTestRequest()];

coerce 'RepeatedDeleteConnectivityTestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::DeleteConnectivityTestRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectivityTestRequest',
    as HashRef[DeleteConnectivityTestRequest()];

declare 'RerunConnectivityTestRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::RerunConnectivityTestRequest'];

coerce 'RerunConnectivityTestRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::RerunConnectivityTestRequest'->new($_) };

declare 'RepeatedRerunConnectivityTestRequest',
    as ArrayRef[RerunConnectivityTestRequest()];

coerce 'RepeatedRerunConnectivityTestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::RerunConnectivityTestRequest'->new($_) } @$_ ] };

declare 'MapStringRerunConnectivityTestRequest',
    as HashRef[RerunConnectivityTestRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::Reachability::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::Reachability::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::Reachability::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Networkmanagement::V1::Reachability::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
