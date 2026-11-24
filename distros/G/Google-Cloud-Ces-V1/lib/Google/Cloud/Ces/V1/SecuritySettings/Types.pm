package Google::Cloud::Ces::V1::SecuritySettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecuritySettings',
    as InstanceOf['Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings'];

coerce 'SecuritySettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings'->new($_) };

declare 'RepeatedSecuritySettings',
    as ArrayRef[SecuritySettings()];

coerce 'RepeatedSecuritySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SecuritySettings::SecuritySettings'->new($_) } @$_ ] };

declare 'MapStringSecuritySettings',
    as HashRef[SecuritySettings()];

declare 'EndpointControlPolicy',
    as InstanceOf['Google::Cloud::Ces::V1::SecuritySettings::EndpointControlPolicy'];

coerce 'EndpointControlPolicy',
    from HashRef, via { 'Google::Cloud::Ces::V1::SecuritySettings::EndpointControlPolicy'->new($_) };

declare 'RepeatedEndpointControlPolicy',
    as ArrayRef[EndpointControlPolicy()];

coerce 'RepeatedEndpointControlPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SecuritySettings::EndpointControlPolicy'->new($_) } @$_ ] };

declare 'MapStringEndpointControlPolicy',
    as HashRef[EndpointControlPolicy()];

declare 'EnforcementScope',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::SecuritySettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
