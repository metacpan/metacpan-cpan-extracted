package Google::Api::MonitoredResource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MonitoredResourceDescriptor',
    as InstanceOf['Google::Api::MonitoredResource::MonitoredResourceDescriptor'];

coerce 'MonitoredResourceDescriptor',
    from HashRef, via { 'Google::Api::MonitoredResource::MonitoredResourceDescriptor'->new($_) };

declare 'RepeatedMonitoredResourceDescriptor',
    as ArrayRef[MonitoredResourceDescriptor()];

coerce 'RepeatedMonitoredResourceDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::MonitoredResource::MonitoredResourceDescriptor'->new($_) } @$_ ] };

declare 'MapStringMonitoredResourceDescriptor',
    as HashRef[MonitoredResourceDescriptor()];

declare 'MonitoredResource',
    as InstanceOf['Google::Api::MonitoredResource::MonitoredResource'];

coerce 'MonitoredResource',
    from HashRef, via { 'Google::Api::MonitoredResource::MonitoredResource'->new($_) };

declare 'RepeatedMonitoredResource',
    as ArrayRef[MonitoredResource()];

coerce 'RepeatedMonitoredResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::MonitoredResource::MonitoredResource'->new($_) } @$_ ] };

declare 'MapStringMonitoredResource',
    as HashRef[MonitoredResource()];

declare 'LabelsEntry',
    as InstanceOf['Google::Api::MonitoredResource::MonitoredResource::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Api::MonitoredResource::MonitoredResource::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::MonitoredResource::MonitoredResource::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MonitoredResourceMetadata',
    as InstanceOf['Google::Api::MonitoredResource::MonitoredResourceMetadata'];

coerce 'MonitoredResourceMetadata',
    from HashRef, via { 'Google::Api::MonitoredResource::MonitoredResourceMetadata'->new($_) };

declare 'RepeatedMonitoredResourceMetadata',
    as ArrayRef[MonitoredResourceMetadata()];

coerce 'RepeatedMonitoredResourceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::MonitoredResource::MonitoredResourceMetadata'->new($_) } @$_ ] };

declare 'MapStringMonitoredResourceMetadata',
    as HashRef[MonitoredResourceMetadata()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Api::MonitoredResource::MonitoredResourceMetadata::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Api::MonitoredResource::MonitoredResourceMetadata::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::MonitoredResource::MonitoredResourceMetadata::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

1;
