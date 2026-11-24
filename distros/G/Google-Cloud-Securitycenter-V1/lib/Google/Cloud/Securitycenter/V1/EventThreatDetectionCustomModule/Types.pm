package Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventThreatDetectionCustomModule',
    as InstanceOf['Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule'];

coerce 'EventThreatDetectionCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule'->new($_) };

declare 'RepeatedEventThreatDetectionCustomModule',
    as ArrayRef[EventThreatDetectionCustomModule()];

coerce 'RepeatedEventThreatDetectionCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule'->new($_) } @$_ ] };

declare 'MapStringEventThreatDetectionCustomModule',
    as HashRef[EventThreatDetectionCustomModule()];

declare 'EnablementState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
