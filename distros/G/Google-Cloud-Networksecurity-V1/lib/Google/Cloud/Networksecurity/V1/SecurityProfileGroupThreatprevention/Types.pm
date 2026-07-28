package Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Severity',
    as (Int | Str);

declare 'ThreatType',
    as (Int | Str);

declare 'ThreatAction',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'ThreatPreventionProfile',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::ThreatPreventionProfile'];

coerce 'ThreatPreventionProfile',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::ThreatPreventionProfile'->new($_) };

declare 'RepeatedThreatPreventionProfile',
    as ArrayRef[ThreatPreventionProfile()];

coerce 'RepeatedThreatPreventionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::ThreatPreventionProfile'->new($_) } @$_ ] };

declare 'MapStringThreatPreventionProfile',
    as HashRef[ThreatPreventionProfile()];

declare 'SeverityOverride',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::SeverityOverride'];

coerce 'SeverityOverride',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::SeverityOverride'->new($_) };

declare 'RepeatedSeverityOverride',
    as ArrayRef[SeverityOverride()];

coerce 'RepeatedSeverityOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::SeverityOverride'->new($_) } @$_ ] };

declare 'MapStringSeverityOverride',
    as HashRef[SeverityOverride()];

declare 'ThreatOverride',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::ThreatOverride'];

coerce 'ThreatOverride',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::ThreatOverride'->new($_) };

declare 'RepeatedThreatOverride',
    as ArrayRef[ThreatOverride()];

coerce 'RepeatedThreatOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::ThreatOverride'->new($_) } @$_ ] };

declare 'MapStringThreatOverride',
    as HashRef[ThreatOverride()];

declare 'AntivirusOverride',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::AntivirusOverride'];

coerce 'AntivirusOverride',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::AntivirusOverride'->new($_) };

declare 'RepeatedAntivirusOverride',
    as ArrayRef[AntivirusOverride()];

coerce 'RepeatedAntivirusOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::AntivirusOverride'->new($_) } @$_ ] };

declare 'MapStringAntivirusOverride',
    as HashRef[AntivirusOverride()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
