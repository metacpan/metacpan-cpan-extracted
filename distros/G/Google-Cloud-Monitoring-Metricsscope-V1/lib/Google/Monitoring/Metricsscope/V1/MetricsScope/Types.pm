package Google::Monitoring::Metricsscope::V1::MetricsScope::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MetricsScope',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope'];

coerce 'MetricsScope',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope'->new($_) };

declare 'RepeatedMetricsScope',
    as ArrayRef[MetricsScope()];

coerce 'RepeatedMetricsScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScope::MetricsScope'->new($_) } @$_ ] };

declare 'MapStringMetricsScope',
    as HashRef[MetricsScope()];

declare 'MonitoredProject',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject'];

coerce 'MonitoredProject',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject'->new($_) };

declare 'RepeatedMonitoredProject',
    as ArrayRef[MonitoredProject()];

coerce 'RepeatedMonitoredProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScope::MonitoredProject'->new($_) } @$_ ] };

declare 'MapStringMonitoredProject',
    as HashRef[MonitoredProject()];

1;

__END__

=head1 NAME

Google::Monitoring::Metricsscope::V1::MetricsScope::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
