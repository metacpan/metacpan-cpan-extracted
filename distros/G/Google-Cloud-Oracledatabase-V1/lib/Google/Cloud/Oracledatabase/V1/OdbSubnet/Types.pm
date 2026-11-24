package Google::Cloud::Oracledatabase::V1::OdbSubnet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OdbSubnet',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet'];

coerce 'OdbSubnet',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet'->new($_) };

declare 'RepeatedOdbSubnet',
    as ArrayRef[OdbSubnet()];

coerce 'RepeatedOdbSubnet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet'->new($_) } @$_ ] };

declare 'MapStringOdbSubnet',
    as HashRef[OdbSubnet()];

declare 'Purpose',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::OdbSubnet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateOdbSubnetRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::CreateOdbSubnetRequest'];

coerce 'CreateOdbSubnetRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::CreateOdbSubnetRequest'->new($_) };

declare 'RepeatedCreateOdbSubnetRequest',
    as ArrayRef[CreateOdbSubnetRequest()];

coerce 'RepeatedCreateOdbSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::CreateOdbSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOdbSubnetRequest',
    as HashRef[CreateOdbSubnetRequest()];

declare 'UpdateOdbSubnetRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::UpdateOdbSubnetRequest'];

coerce 'UpdateOdbSubnetRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::UpdateOdbSubnetRequest'->new($_) };

declare 'RepeatedUpdateOdbSubnetRequest',
    as ArrayRef[UpdateOdbSubnetRequest()];

coerce 'RepeatedUpdateOdbSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::UpdateOdbSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOdbSubnetRequest',
    as HashRef[UpdateOdbSubnetRequest()];

declare 'DeleteOdbSubnetRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::DeleteOdbSubnetRequest'];

coerce 'DeleteOdbSubnetRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::DeleteOdbSubnetRequest'->new($_) };

declare 'RepeatedDeleteOdbSubnetRequest',
    as ArrayRef[DeleteOdbSubnetRequest()];

coerce 'RepeatedDeleteOdbSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::DeleteOdbSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOdbSubnetRequest',
    as HashRef[DeleteOdbSubnetRequest()];

declare 'ListOdbSubnetsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsRequest'];

coerce 'ListOdbSubnetsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsRequest'->new($_) };

declare 'RepeatedListOdbSubnetsRequest',
    as ArrayRef[ListOdbSubnetsRequest()];

coerce 'RepeatedListOdbSubnetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsRequest'->new($_) } @$_ ] };

declare 'MapStringListOdbSubnetsRequest',
    as HashRef[ListOdbSubnetsRequest()];

declare 'ListOdbSubnetsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsResponse'];

coerce 'ListOdbSubnetsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsResponse'->new($_) };

declare 'RepeatedListOdbSubnetsResponse',
    as ArrayRef[ListOdbSubnetsResponse()];

coerce 'RepeatedListOdbSubnetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::ListOdbSubnetsResponse'->new($_) } @$_ ] };

declare 'MapStringListOdbSubnetsResponse',
    as HashRef[ListOdbSubnetsResponse()];

declare 'GetOdbSubnetRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbSubnet::GetOdbSubnetRequest'];

coerce 'GetOdbSubnetRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::GetOdbSubnetRequest'->new($_) };

declare 'RepeatedGetOdbSubnetRequest',
    as ArrayRef[GetOdbSubnetRequest()];

coerce 'RepeatedGetOdbSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbSubnet::GetOdbSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringGetOdbSubnetRequest',
    as HashRef[GetOdbSubnetRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::OdbSubnet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
