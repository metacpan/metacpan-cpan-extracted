package Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateConnectionAssignment',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment'];

coerce 'GoldengateConnectionAssignment',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment'->new($_) };

declare 'RepeatedGoldengateConnectionAssignment',
    as ArrayRef[GoldengateConnectionAssignment()];

coerce 'RepeatedGoldengateConnectionAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment'->new($_) } @$_ ] };

declare 'MapStringGoldengateConnectionAssignment',
    as HashRef[GoldengateConnectionAssignment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GoldengateConnectionAssignmentProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignmentProperties'];

coerce 'GoldengateConnectionAssignmentProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignmentProperties'->new($_) };

declare 'RepeatedGoldengateConnectionAssignmentProperties',
    as ArrayRef[GoldengateConnectionAssignmentProperties()];

coerce 'RepeatedGoldengateConnectionAssignmentProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GoldengateConnectionAssignmentProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateConnectionAssignmentProperties',
    as HashRef[GoldengateConnectionAssignmentProperties()];

declare 'State',
    as (Int | Str);

declare 'ListGoldengateConnectionAssignmentsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsRequest'];

coerce 'ListGoldengateConnectionAssignmentsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsRequest'->new($_) };

declare 'RepeatedListGoldengateConnectionAssignmentsRequest',
    as ArrayRef[ListGoldengateConnectionAssignmentsRequest()];

coerce 'RepeatedListGoldengateConnectionAssignmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateConnectionAssignmentsRequest',
    as HashRef[ListGoldengateConnectionAssignmentsRequest()];

declare 'ListGoldengateConnectionAssignmentsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsResponse'];

coerce 'ListGoldengateConnectionAssignmentsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsResponse'->new($_) };

declare 'RepeatedListGoldengateConnectionAssignmentsResponse',
    as ArrayRef[ListGoldengateConnectionAssignmentsResponse()];

coerce 'RepeatedListGoldengateConnectionAssignmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::ListGoldengateConnectionAssignmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateConnectionAssignmentsResponse',
    as HashRef[ListGoldengateConnectionAssignmentsResponse()];

declare 'GetGoldengateConnectionAssignmentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GetGoldengateConnectionAssignmentRequest'];

coerce 'GetGoldengateConnectionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GetGoldengateConnectionAssignmentRequest'->new($_) };

declare 'RepeatedGetGoldengateConnectionAssignmentRequest',
    as ArrayRef[GetGoldengateConnectionAssignmentRequest()];

coerce 'RepeatedGetGoldengateConnectionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::GetGoldengateConnectionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetGoldengateConnectionAssignmentRequest',
    as HashRef[GetGoldengateConnectionAssignmentRequest()];

declare 'CreateGoldengateConnectionAssignmentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::CreateGoldengateConnectionAssignmentRequest'];

coerce 'CreateGoldengateConnectionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::CreateGoldengateConnectionAssignmentRequest'->new($_) };

declare 'RepeatedCreateGoldengateConnectionAssignmentRequest',
    as ArrayRef[CreateGoldengateConnectionAssignmentRequest()];

coerce 'RepeatedCreateGoldengateConnectionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::CreateGoldengateConnectionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGoldengateConnectionAssignmentRequest',
    as HashRef[CreateGoldengateConnectionAssignmentRequest()];

declare 'TestGoldengateConnectionAssignmentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentRequest'];

coerce 'TestGoldengateConnectionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentRequest'->new($_) };

declare 'RepeatedTestGoldengateConnectionAssignmentRequest',
    as ArrayRef[TestGoldengateConnectionAssignmentRequest()];

coerce 'RepeatedTestGoldengateConnectionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringTestGoldengateConnectionAssignmentRequest',
    as HashRef[TestGoldengateConnectionAssignmentRequest()];

declare 'TestType',
    as (Int | Str);

declare 'TestConnectionAssignmentError',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError'];

coerce 'TestConnectionAssignmentError',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError'->new($_) };

declare 'RepeatedTestConnectionAssignmentError',
    as ArrayRef[TestConnectionAssignmentError()];

coerce 'RepeatedTestConnectionAssignmentError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestConnectionAssignmentError'->new($_) } @$_ ] };

declare 'MapStringTestConnectionAssignmentError',
    as HashRef[TestConnectionAssignmentError()];

declare 'TestGoldengateConnectionAssignmentResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentResponse'];

coerce 'TestGoldengateConnectionAssignmentResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentResponse'->new($_) };

declare 'RepeatedTestGoldengateConnectionAssignmentResponse',
    as ArrayRef[TestGoldengateConnectionAssignmentResponse()];

coerce 'RepeatedTestGoldengateConnectionAssignmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::TestGoldengateConnectionAssignmentResponse'->new($_) } @$_ ] };

declare 'MapStringTestGoldengateConnectionAssignmentResponse',
    as HashRef[TestGoldengateConnectionAssignmentResponse()];

declare 'ResultType',
    as (Int | Str);

declare 'UpdateGoldengateConnectionAssignmentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::UpdateGoldengateConnectionAssignmentRequest'];

coerce 'UpdateGoldengateConnectionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::UpdateGoldengateConnectionAssignmentRequest'->new($_) };

declare 'RepeatedUpdateGoldengateConnectionAssignmentRequest',
    as ArrayRef[UpdateGoldengateConnectionAssignmentRequest()];

coerce 'RepeatedUpdateGoldengateConnectionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::UpdateGoldengateConnectionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGoldengateConnectionAssignmentRequest',
    as HashRef[UpdateGoldengateConnectionAssignmentRequest()];

declare 'DeleteGoldengateConnectionAssignmentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::DeleteGoldengateConnectionAssignmentRequest'];

coerce 'DeleteGoldengateConnectionAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::DeleteGoldengateConnectionAssignmentRequest'->new($_) };

declare 'RepeatedDeleteGoldengateConnectionAssignmentRequest',
    as ArrayRef[DeleteGoldengateConnectionAssignmentRequest()];

coerce 'RepeatedDeleteGoldengateConnectionAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::DeleteGoldengateConnectionAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGoldengateConnectionAssignmentRequest',
    as HashRef[DeleteGoldengateConnectionAssignmentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
