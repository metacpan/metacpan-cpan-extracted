package Google::Cloud::Identitytoolkit::V2::AccountManagementService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FinalizeMfaEnrollmentRequest',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest'];

coerce 'FinalizeMfaEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest'->new($_) };

declare 'RepeatedFinalizeMfaEnrollmentRequest',
    as ArrayRef[FinalizeMfaEnrollmentRequest()];

coerce 'RepeatedFinalizeMfaEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeMfaEnrollmentRequest',
    as HashRef[FinalizeMfaEnrollmentRequest()];

declare 'FinalizeMfaEnrollmentResponse',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse'];

coerce 'FinalizeMfaEnrollmentResponse',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse'->new($_) };

declare 'RepeatedFinalizeMfaEnrollmentResponse',
    as ArrayRef[FinalizeMfaEnrollmentResponse()];

coerce 'RepeatedFinalizeMfaEnrollmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeMfaEnrollmentResponse',
    as HashRef[FinalizeMfaEnrollmentResponse()];

declare 'StartMfaEnrollmentRequest',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest'];

coerce 'StartMfaEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest'->new($_) };

declare 'RepeatedStartMfaEnrollmentRequest',
    as ArrayRef[StartMfaEnrollmentRequest()];

coerce 'RepeatedStartMfaEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringStartMfaEnrollmentRequest',
    as HashRef[StartMfaEnrollmentRequest()];

declare 'StartMfaEnrollmentResponse',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse'];

coerce 'StartMfaEnrollmentResponse',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse'->new($_) };

declare 'RepeatedStartMfaEnrollmentResponse',
    as ArrayRef[StartMfaEnrollmentResponse()];

coerce 'RepeatedStartMfaEnrollmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse'->new($_) } @$_ ] };

declare 'MapStringStartMfaEnrollmentResponse',
    as HashRef[StartMfaEnrollmentResponse()];

declare 'WithdrawMfaRequest',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest'];

coerce 'WithdrawMfaRequest',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest'->new($_) };

declare 'RepeatedWithdrawMfaRequest',
    as ArrayRef[WithdrawMfaRequest()];

coerce 'RepeatedWithdrawMfaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest'->new($_) } @$_ ] };

declare 'MapStringWithdrawMfaRequest',
    as HashRef[WithdrawMfaRequest()];

declare 'WithdrawMfaResponse',
    as InstanceOf['Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse'];

coerce 'WithdrawMfaResponse',
    from HashRef, via { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse'->new($_) };

declare 'RepeatedWithdrawMfaResponse',
    as ArrayRef[WithdrawMfaResponse()];

coerce 'RepeatedWithdrawMfaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse'->new($_) } @$_ ] };

declare 'MapStringWithdrawMfaResponse',
    as HashRef[WithdrawMfaResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Identitytoolkit::V2::AccountManagementService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
