package Google::Cloud::Securitycenter::V2::IpRules::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IpRules',
    as InstanceOf['Google::Cloud::Securitycenter::V2::IpRules::IpRules'];

coerce 'IpRules',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::IpRules::IpRules'->new($_) };

declare 'RepeatedIpRules',
    as ArrayRef[IpRules()];

coerce 'RepeatedIpRules',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::IpRules::IpRules'->new($_) } @$_ ] };

declare 'MapStringIpRules',
    as HashRef[IpRules()];

declare 'Direction',
    as (Int | Str);

declare 'IpRule',
    as InstanceOf['Google::Cloud::Securitycenter::V2::IpRules::IpRule'];

coerce 'IpRule',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::IpRules::IpRule'->new($_) };

declare 'RepeatedIpRule',
    as ArrayRef[IpRule()];

coerce 'RepeatedIpRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::IpRules::IpRule'->new($_) } @$_ ] };

declare 'MapStringIpRule',
    as HashRef[IpRule()];

declare 'PortRange',
    as InstanceOf['Google::Cloud::Securitycenter::V2::IpRules::IpRule::PortRange'];

coerce 'PortRange',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::IpRules::IpRule::PortRange'->new($_) };

declare 'RepeatedPortRange',
    as ArrayRef[PortRange()];

coerce 'RepeatedPortRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::IpRules::IpRule::PortRange'->new($_) } @$_ ] };

declare 'MapStringPortRange',
    as HashRef[PortRange()];

declare 'Allowed',
    as InstanceOf['Google::Cloud::Securitycenter::V2::IpRules::Allowed'];

coerce 'Allowed',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::IpRules::Allowed'->new($_) };

declare 'RepeatedAllowed',
    as ArrayRef[Allowed()];

coerce 'RepeatedAllowed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::IpRules::Allowed'->new($_) } @$_ ] };

declare 'MapStringAllowed',
    as HashRef[Allowed()];

declare 'Denied',
    as InstanceOf['Google::Cloud::Securitycenter::V2::IpRules::Denied'];

coerce 'Denied',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::IpRules::Denied'->new($_) };

declare 'RepeatedDenied',
    as ArrayRef[Denied()];

coerce 'RepeatedDenied',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::IpRules::Denied'->new($_) } @$_ ] };

declare 'MapStringDenied',
    as HashRef[Denied()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::IpRules::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
