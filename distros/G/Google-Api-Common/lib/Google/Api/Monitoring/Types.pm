package Google::Api::Monitoring::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Monitoring',
    as InstanceOf['Google::Api::Monitoring::Monitoring'];

coerce 'Monitoring',
    from HashRef, via { 'Google::Api::Monitoring::Monitoring'->new($_) };

declare 'RepeatedMonitoring',
    as ArrayRef[Monitoring()];

coerce 'RepeatedMonitoring',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Monitoring::Monitoring'->new($_) } @$_ ] };

declare 'MapStringMonitoring',
    as HashRef[Monitoring()];

declare 'MonitoringDestination',
    as InstanceOf['Google::Api::Monitoring::Monitoring::MonitoringDestination'];

coerce 'MonitoringDestination',
    from HashRef, via { 'Google::Api::Monitoring::Monitoring::MonitoringDestination'->new($_) };

declare 'RepeatedMonitoringDestination',
    as ArrayRef[MonitoringDestination()];

coerce 'RepeatedMonitoringDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Monitoring::Monitoring::MonitoringDestination'->new($_) } @$_ ] };

declare 'MapStringMonitoringDestination',
    as HashRef[MonitoringDestination()];

1;

__END__

=head1 NAME

Google::Api::Monitoring::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
