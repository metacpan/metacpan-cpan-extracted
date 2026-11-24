package Google::Appengine::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Appengine::V1::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Appengine::V1::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'LabelsEntry',
    as InstanceOf['Google::Appengine::V1::Service::Service::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Appengine::V1::Service::Service::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Service::Service::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TrafficSplit',
    as InstanceOf['Google::Appengine::V1::Service::TrafficSplit'];

coerce 'TrafficSplit',
    from HashRef, via { 'Google::Appengine::V1::Service::TrafficSplit'->new($_) };

declare 'RepeatedTrafficSplit',
    as ArrayRef[TrafficSplit()];

coerce 'RepeatedTrafficSplit',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Service::TrafficSplit'->new($_) } @$_ ] };

declare 'MapStringTrafficSplit',
    as HashRef[TrafficSplit()];

declare 'ShardBy',
    as (Int | Str);

declare 'AllocationsEntry',
    as InstanceOf['Google::Appengine::V1::Service::TrafficSplit::AllocationsEntry'];

coerce 'AllocationsEntry',
    from HashRef, via { 'Google::Appengine::V1::Service::TrafficSplit::AllocationsEntry'->new($_) };

declare 'RepeatedAllocationsEntry',
    as ArrayRef[AllocationsEntry()];

coerce 'RepeatedAllocationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Service::TrafficSplit::AllocationsEntry'->new($_) } @$_ ] };

declare 'MapStringAllocationsEntry',
    as HashRef[AllocationsEntry()];

1;

__END__

=head1 NAME

Google::Appengine::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
