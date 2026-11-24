package Google::Cloud::Securitycenter::V1::CloudArmor::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudArmor',
    as InstanceOf['Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor'];

coerce 'CloudArmor',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor'->new($_) };

declare 'RepeatedCloudArmor',
    as ArrayRef[CloudArmor()];

coerce 'RepeatedCloudArmor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::CloudArmor::CloudArmor'->new($_) } @$_ ] };

declare 'MapStringCloudArmor',
    as HashRef[CloudArmor()];

declare 'SecurityPolicy',
    as InstanceOf['Google::Cloud::Securitycenter::V1::CloudArmor::SecurityPolicy'];

coerce 'SecurityPolicy',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::CloudArmor::SecurityPolicy'->new($_) };

declare 'RepeatedSecurityPolicy',
    as ArrayRef[SecurityPolicy()];

coerce 'RepeatedSecurityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::CloudArmor::SecurityPolicy'->new($_) } @$_ ] };

declare 'MapStringSecurityPolicy',
    as HashRef[SecurityPolicy()];

declare 'Requests',
    as InstanceOf['Google::Cloud::Securitycenter::V1::CloudArmor::Requests'];

coerce 'Requests',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::CloudArmor::Requests'->new($_) };

declare 'RepeatedRequests',
    as ArrayRef[Requests()];

coerce 'RepeatedRequests',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::CloudArmor::Requests'->new($_) } @$_ ] };

declare 'MapStringRequests',
    as HashRef[Requests()];

declare 'AdaptiveProtection',
    as InstanceOf['Google::Cloud::Securitycenter::V1::CloudArmor::AdaptiveProtection'];

coerce 'AdaptiveProtection',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::CloudArmor::AdaptiveProtection'->new($_) };

declare 'RepeatedAdaptiveProtection',
    as ArrayRef[AdaptiveProtection()];

coerce 'RepeatedAdaptiveProtection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::CloudArmor::AdaptiveProtection'->new($_) } @$_ ] };

declare 'MapStringAdaptiveProtection',
    as HashRef[AdaptiveProtection()];

declare 'Attack',
    as InstanceOf['Google::Cloud::Securitycenter::V1::CloudArmor::Attack'];

coerce 'Attack',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::CloudArmor::Attack'->new($_) };

declare 'RepeatedAttack',
    as ArrayRef[Attack()];

coerce 'RepeatedAttack',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::CloudArmor::Attack'->new($_) } @$_ ] };

declare 'MapStringAttack',
    as HashRef[Attack()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::CloudArmor::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
