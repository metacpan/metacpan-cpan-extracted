package Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EffectiveEventThreatDetectionCustomModule',
    as InstanceOf['Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule'];

coerce 'EffectiveEventThreatDetectionCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule'->new($_) };

declare 'RepeatedEffectiveEventThreatDetectionCustomModule',
    as ArrayRef[EffectiveEventThreatDetectionCustomModule()];

coerce 'RepeatedEffectiveEventThreatDetectionCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule'->new($_) } @$_ ] };

declare 'MapStringEffectiveEventThreatDetectionCustomModule',
    as HashRef[EffectiveEventThreatDetectionCustomModule()];

declare 'EnablementState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
