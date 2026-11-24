package Google::Cloud::Oracledatabase::V1::OdbDnsZone::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OdbDnsZone',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone'];

coerce 'OdbDnsZone',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone'->new($_) };

declare 'RepeatedOdbDnsZone',
    as ArrayRef[OdbDnsZone()];

coerce 'RepeatedOdbDnsZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone'->new($_) } @$_ ] };

declare 'MapStringOdbDnsZone',
    as HashRef[OdbDnsZone()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::OdbDnsZone::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateOdbDnsZoneRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::CreateOdbDnsZoneRequest'];

coerce 'CreateOdbDnsZoneRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::CreateOdbDnsZoneRequest'->new($_) };

declare 'RepeatedCreateOdbDnsZoneRequest',
    as ArrayRef[CreateOdbDnsZoneRequest()];

coerce 'RepeatedCreateOdbDnsZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::CreateOdbDnsZoneRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOdbDnsZoneRequest',
    as HashRef[CreateOdbDnsZoneRequest()];

declare 'DeleteOdbDnsZoneRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::DeleteOdbDnsZoneRequest'];

coerce 'DeleteOdbDnsZoneRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::DeleteOdbDnsZoneRequest'->new($_) };

declare 'RepeatedDeleteOdbDnsZoneRequest',
    as ArrayRef[DeleteOdbDnsZoneRequest()];

coerce 'RepeatedDeleteOdbDnsZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::DeleteOdbDnsZoneRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOdbDnsZoneRequest',
    as HashRef[DeleteOdbDnsZoneRequest()];

declare 'ListOdbDnsZonesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesRequest'];

coerce 'ListOdbDnsZonesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesRequest'->new($_) };

declare 'RepeatedListOdbDnsZonesRequest',
    as ArrayRef[ListOdbDnsZonesRequest()];

coerce 'RepeatedListOdbDnsZonesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesRequest'->new($_) } @$_ ] };

declare 'MapStringListOdbDnsZonesRequest',
    as HashRef[ListOdbDnsZonesRequest()];

declare 'ListOdbDnsZonesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesResponse'];

coerce 'ListOdbDnsZonesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesResponse'->new($_) };

declare 'RepeatedListOdbDnsZonesResponse',
    as ArrayRef[ListOdbDnsZonesResponse()];

coerce 'RepeatedListOdbDnsZonesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::ListOdbDnsZonesResponse'->new($_) } @$_ ] };

declare 'MapStringListOdbDnsZonesResponse',
    as HashRef[ListOdbDnsZonesResponse()];

declare 'GetOdbDnsZoneRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::GetOdbDnsZoneRequest'];

coerce 'GetOdbDnsZoneRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::GetOdbDnsZoneRequest'->new($_) };

declare 'RepeatedGetOdbDnsZoneRequest',
    as ArrayRef[GetOdbDnsZoneRequest()];

coerce 'RepeatedGetOdbDnsZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::GetOdbDnsZoneRequest'->new($_) } @$_ ] };

declare 'MapStringGetOdbDnsZoneRequest',
    as HashRef[GetOdbDnsZoneRequest()];

declare 'UpdateOdbDnsZoneRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::OdbDnsZone::UpdateOdbDnsZoneRequest'];

coerce 'UpdateOdbDnsZoneRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::UpdateOdbDnsZoneRequest'->new($_) };

declare 'RepeatedUpdateOdbDnsZoneRequest',
    as ArrayRef[UpdateOdbDnsZoneRequest()];

coerce 'RepeatedUpdateOdbDnsZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::OdbDnsZone::UpdateOdbDnsZoneRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOdbDnsZoneRequest',
    as HashRef[UpdateOdbDnsZoneRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::OdbDnsZone::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
