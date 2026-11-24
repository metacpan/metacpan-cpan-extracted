package Google::Cloud::Securitycenter::V1::AttackExposure::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttackExposure',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure'];

coerce 'AttackExposure',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure'->new($_) };

declare 'RepeatedAttackExposure',
    as ArrayRef[AttackExposure()];

coerce 'RepeatedAttackExposure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackExposure::AttackExposure'->new($_) } @$_ ] };

declare 'MapStringAttackExposure',
    as HashRef[AttackExposure()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::AttackExposure::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
