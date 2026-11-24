package Google::Cloud::Networkconnectivity::V1::InternalRange::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InternalRange',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange'];

coerce 'InternalRange',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange'->new($_) };

declare 'RepeatedInternalRange',
    as ArrayRef[InternalRange()];

coerce 'RepeatedInternalRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange'->new($_) } @$_ ] };

declare 'MapStringInternalRange',
    as HashRef[InternalRange()];

declare 'Usage',
    as (Int | Str);

declare 'Peering',
    as (Int | Str);

declare 'Overlap',
    as (Int | Str);

declare 'AllocationStrategy',
    as (Int | Str);

declare 'Migration',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::Migration'];

coerce 'Migration',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::Migration'->new($_) };

declare 'RepeatedMigration',
    as ArrayRef[Migration()];

coerce 'RepeatedMigration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::Migration'->new($_) } @$_ ] };

declare 'MapStringMigration',
    as HashRef[Migration()];

declare 'AllocationOptions',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::AllocationOptions'];

coerce 'AllocationOptions',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::AllocationOptions'->new($_) };

declare 'RepeatedAllocationOptions',
    as ArrayRef[AllocationOptions()];

coerce 'RepeatedAllocationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::AllocationOptions'->new($_) } @$_ ] };

declare 'MapStringAllocationOptions',
    as HashRef[AllocationOptions()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::InternalRange::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInternalRangesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesRequest'];

coerce 'ListInternalRangesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesRequest'->new($_) };

declare 'RepeatedListInternalRangesRequest',
    as ArrayRef[ListInternalRangesRequest()];

coerce 'RepeatedListInternalRangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesRequest'->new($_) } @$_ ] };

declare 'MapStringListInternalRangesRequest',
    as HashRef[ListInternalRangesRequest()];

declare 'ListInternalRangesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse'];

coerce 'ListInternalRangesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse'->new($_) };

declare 'RepeatedListInternalRangesResponse',
    as ArrayRef[ListInternalRangesResponse()];

coerce 'RepeatedListInternalRangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse'->new($_) } @$_ ] };

declare 'MapStringListInternalRangesResponse',
    as HashRef[ListInternalRangesResponse()];

declare 'GetInternalRangeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::GetInternalRangeRequest'];

coerce 'GetInternalRangeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::GetInternalRangeRequest'->new($_) };

declare 'RepeatedGetInternalRangeRequest',
    as ArrayRef[GetInternalRangeRequest()];

coerce 'RepeatedGetInternalRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::GetInternalRangeRequest'->new($_) } @$_ ] };

declare 'MapStringGetInternalRangeRequest',
    as HashRef[GetInternalRangeRequest()];

declare 'CreateInternalRangeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::CreateInternalRangeRequest'];

coerce 'CreateInternalRangeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::CreateInternalRangeRequest'->new($_) };

declare 'RepeatedCreateInternalRangeRequest',
    as ArrayRef[CreateInternalRangeRequest()];

coerce 'RepeatedCreateInternalRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::CreateInternalRangeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInternalRangeRequest',
    as HashRef[CreateInternalRangeRequest()];

declare 'UpdateInternalRangeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::UpdateInternalRangeRequest'];

coerce 'UpdateInternalRangeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::UpdateInternalRangeRequest'->new($_) };

declare 'RepeatedUpdateInternalRangeRequest',
    as ArrayRef[UpdateInternalRangeRequest()];

coerce 'RepeatedUpdateInternalRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::UpdateInternalRangeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInternalRangeRequest',
    as HashRef[UpdateInternalRangeRequest()];

declare 'DeleteInternalRangeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::InternalRange::DeleteInternalRangeRequest'];

coerce 'DeleteInternalRangeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::InternalRange::DeleteInternalRangeRequest'->new($_) };

declare 'RepeatedDeleteInternalRangeRequest',
    as ArrayRef[DeleteInternalRangeRequest()];

coerce 'RepeatedDeleteInternalRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::InternalRange::DeleteInternalRangeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInternalRangeRequest',
    as HashRef[DeleteInternalRangeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1::InternalRange::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
