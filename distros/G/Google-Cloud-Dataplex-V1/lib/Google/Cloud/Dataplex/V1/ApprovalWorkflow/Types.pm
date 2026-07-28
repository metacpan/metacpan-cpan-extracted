package Google::Cloud::Dataplex::V1::ApprovalWorkflow::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChangeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest'];

coerce 'ChangeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest'->new($_) };

declare 'RepeatedChangeRequest',
    as ArrayRef[ChangeRequest()];

coerce 'RepeatedChangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest'->new($_) } @$_ ] };

declare 'MapStringChangeRequest',
    as HashRef[ChangeRequest()];

declare 'State',
    as (Int | Str);

declare 'ChangeType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::ApprovalWorkflow::ChangeRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DataProductAccessRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::ApprovalWorkflow::DataProductAccessRequest'];

coerce 'DataProductAccessRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::ApprovalWorkflow::DataProductAccessRequest'->new($_) };

declare 'RepeatedDataProductAccessRequest',
    as ArrayRef[DataProductAccessRequest()];

coerce 'RepeatedDataProductAccessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::ApprovalWorkflow::DataProductAccessRequest'->new($_) } @$_ ] };

declare 'MapStringDataProductAccessRequest',
    as HashRef[DataProductAccessRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::ApprovalWorkflow::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
