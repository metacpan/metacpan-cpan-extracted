package Google::Longrunning::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Operation',
    as InstanceOf['Google::Longrunning::Operations::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Longrunning::Operations::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'GetOperationRequest',
    as InstanceOf['Google::Longrunning::Operations::GetOperationRequest'];

coerce 'GetOperationRequest',
    from HashRef, via { 'Google::Longrunning::Operations::GetOperationRequest'->new($_) };

declare 'RepeatedGetOperationRequest',
    as ArrayRef[GetOperationRequest()];

coerce 'RepeatedGetOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::GetOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetOperationRequest',
    as HashRef[GetOperationRequest()];

declare 'ListOperationsRequest',
    as InstanceOf['Google::Longrunning::Operations::ListOperationsRequest'];

coerce 'ListOperationsRequest',
    from HashRef, via { 'Google::Longrunning::Operations::ListOperationsRequest'->new($_) };

declare 'RepeatedListOperationsRequest',
    as ArrayRef[ListOperationsRequest()];

coerce 'RepeatedListOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::ListOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListOperationsRequest',
    as HashRef[ListOperationsRequest()];

declare 'ListOperationsResponse',
    as InstanceOf['Google::Longrunning::Operations::ListOperationsResponse'];

coerce 'ListOperationsResponse',
    from HashRef, via { 'Google::Longrunning::Operations::ListOperationsResponse'->new($_) };

declare 'RepeatedListOperationsResponse',
    as ArrayRef[ListOperationsResponse()];

coerce 'RepeatedListOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::ListOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListOperationsResponse',
    as HashRef[ListOperationsResponse()];

declare 'CancelOperationRequest',
    as InstanceOf['Google::Longrunning::Operations::CancelOperationRequest'];

coerce 'CancelOperationRequest',
    from HashRef, via { 'Google::Longrunning::Operations::CancelOperationRequest'->new($_) };

declare 'RepeatedCancelOperationRequest',
    as ArrayRef[CancelOperationRequest()];

coerce 'RepeatedCancelOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::CancelOperationRequest'->new($_) } @$_ ] };

declare 'MapStringCancelOperationRequest',
    as HashRef[CancelOperationRequest()];

declare 'DeleteOperationRequest',
    as InstanceOf['Google::Longrunning::Operations::DeleteOperationRequest'];

coerce 'DeleteOperationRequest',
    from HashRef, via { 'Google::Longrunning::Operations::DeleteOperationRequest'->new($_) };

declare 'RepeatedDeleteOperationRequest',
    as ArrayRef[DeleteOperationRequest()];

coerce 'RepeatedDeleteOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::DeleteOperationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOperationRequest',
    as HashRef[DeleteOperationRequest()];

declare 'WaitOperationRequest',
    as InstanceOf['Google::Longrunning::Operations::WaitOperationRequest'];

coerce 'WaitOperationRequest',
    from HashRef, via { 'Google::Longrunning::Operations::WaitOperationRequest'->new($_) };

declare 'RepeatedWaitOperationRequest',
    as ArrayRef[WaitOperationRequest()];

coerce 'RepeatedWaitOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::WaitOperationRequest'->new($_) } @$_ ] };

declare 'MapStringWaitOperationRequest',
    as HashRef[WaitOperationRequest()];

declare 'OperationInfo',
    as InstanceOf['Google::Longrunning::Operations::OperationInfo'];

coerce 'OperationInfo',
    from HashRef, via { 'Google::Longrunning::Operations::OperationInfo'->new($_) };

declare 'RepeatedOperationInfo',
    as ArrayRef[OperationInfo()];

coerce 'RepeatedOperationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Longrunning::Operations::OperationInfo'->new($_) } @$_ ] };

declare 'MapStringOperationInfo',
    as HashRef[OperationInfo()];

1;

__END__

=head1 NAME

Google::Longrunning::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
