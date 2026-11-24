package Google::Cloud::Cloudcontrolspartner::V1::Partners::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Partner',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner'];

coerce 'Partner',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner'->new($_) };

declare 'RepeatedPartner',
    as ArrayRef[Partner()];

coerce 'RepeatedPartner',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::Partner'->new($_) } @$_ ] };

declare 'MapStringPartner',
    as HashRef[Partner()];

declare 'GetPartnerRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Partners::GetPartnerRequest'];

coerce 'GetPartnerRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::GetPartnerRequest'->new($_) };

declare 'RepeatedGetPartnerRequest',
    as ArrayRef[GetPartnerRequest()];

coerce 'RepeatedGetPartnerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::GetPartnerRequest'->new($_) } @$_ ] };

declare 'MapStringGetPartnerRequest',
    as HashRef[GetPartnerRequest()];

declare 'Sku',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Partners::Sku'];

coerce 'Sku',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::Sku'->new($_) };

declare 'RepeatedSku',
    as ArrayRef[Sku()];

coerce 'RepeatedSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::Sku'->new($_) } @$_ ] };

declare 'MapStringSku',
    as HashRef[Sku()];

declare 'EkmMetadata',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Partners::EkmMetadata'];

coerce 'EkmMetadata',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::EkmMetadata'->new($_) };

declare 'RepeatedEkmMetadata',
    as ArrayRef[EkmMetadata()];

coerce 'RepeatedEkmMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Partners::EkmMetadata'->new($_) } @$_ ] };

declare 'MapStringEkmMetadata',
    as HashRef[EkmMetadata()];

declare 'EkmSolution',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Partners::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
