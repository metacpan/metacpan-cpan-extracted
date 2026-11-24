package Google::Cloud::Ids::Logging::V1::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ThreatLog',
    as InstanceOf['Google::Cloud::Ids::Logging::V1::Logging::ThreatLog'];

coerce 'ThreatLog',
    from HashRef, via { 'Google::Cloud::Ids::Logging::V1::Logging::ThreatLog'->new($_) };

declare 'RepeatedThreatLog',
    as ArrayRef[ThreatLog()];

coerce 'RepeatedThreatLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::Logging::V1::Logging::ThreatLog'->new($_) } @$_ ] };

declare 'MapStringThreatLog',
    as HashRef[ThreatLog()];

declare 'Severity',
    as (Int | Str);

declare 'Direction',
    as (Int | Str);

declare 'TrafficLog',
    as InstanceOf['Google::Cloud::Ids::Logging::V1::Logging::TrafficLog'];

coerce 'TrafficLog',
    from HashRef, via { 'Google::Cloud::Ids::Logging::V1::Logging::TrafficLog'->new($_) };

declare 'RepeatedTrafficLog',
    as ArrayRef[TrafficLog()];

coerce 'RepeatedTrafficLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ids::Logging::V1::Logging::TrafficLog'->new($_) } @$_ ] };

declare 'MapStringTrafficLog',
    as HashRef[TrafficLog()];

1;

__END__

=head1 NAME

Google::Cloud::Ids::Logging::V1::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
