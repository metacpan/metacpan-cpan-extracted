package Google::Cloud::Securitycenter::V1::Access::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Access',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Access::Access'];

coerce 'Access',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Access::Access'->new($_) };

declare 'RepeatedAccess',
    as ArrayRef[Access()];

coerce 'RepeatedAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Access::Access'->new($_) } @$_ ] };

declare 'MapStringAccess',
    as HashRef[Access()];

declare 'ServiceAccountDelegationInfo',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Access::ServiceAccountDelegationInfo'];

coerce 'ServiceAccountDelegationInfo',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Access::ServiceAccountDelegationInfo'->new($_) };

declare 'RepeatedServiceAccountDelegationInfo',
    as ArrayRef[ServiceAccountDelegationInfo()];

coerce 'RepeatedServiceAccountDelegationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Access::ServiceAccountDelegationInfo'->new($_) } @$_ ] };

declare 'MapStringServiceAccountDelegationInfo',
    as HashRef[ServiceAccountDelegationInfo()];

declare 'Geolocation',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Access::Geolocation'];

coerce 'Geolocation',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Access::Geolocation'->new($_) };

declare 'RepeatedGeolocation',
    as ArrayRef[Geolocation()];

coerce 'RepeatedGeolocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Access::Geolocation'->new($_) } @$_ ] };

declare 'MapStringGeolocation',
    as HashRef[Geolocation()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Access::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
