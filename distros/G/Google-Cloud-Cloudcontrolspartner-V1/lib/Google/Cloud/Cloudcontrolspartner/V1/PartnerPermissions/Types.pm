package Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PartnerPermissions',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions'];

coerce 'PartnerPermissions',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions'->new($_) };

declare 'RepeatedPartnerPermissions',
    as ArrayRef[PartnerPermissions()];

coerce 'RepeatedPartnerPermissions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::PartnerPermissions'->new($_) } @$_ ] };

declare 'MapStringPartnerPermissions',
    as HashRef[PartnerPermissions()];

declare 'Permission',
    as (Int | Str);

declare 'GetPartnerPermissionsRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::GetPartnerPermissionsRequest'];

coerce 'GetPartnerPermissionsRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::GetPartnerPermissionsRequest'->new($_) };

declare 'RepeatedGetPartnerPermissionsRequest',
    as ArrayRef[GetPartnerPermissionsRequest()];

coerce 'RepeatedGetPartnerPermissionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::GetPartnerPermissionsRequest'->new($_) } @$_ ] };

declare 'MapStringGetPartnerPermissionsRequest',
    as HashRef[GetPartnerPermissionsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
