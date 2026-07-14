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
