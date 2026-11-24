package Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HealthStatus',
    as (Int | Str);

declare 'ResourceInfo',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo'];

coerce 'ResourceInfo',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo'->new($_) };

declare 'RepeatedResourceInfo',
    as ArrayRef[ResourceInfo()];

coerce 'RepeatedResourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ResourceInfo'->new($_) } @$_ ] };

declare 'MapStringResourceInfo',
    as HashRef[ResourceInfo()];

declare 'ContainerHealthDetails',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails'];

coerce 'ContainerHealthDetails',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails'->new($_) };

declare 'RepeatedContainerHealthDetails',
    as ArrayRef[ContainerHealthDetails()];

coerce 'RepeatedContainerHealthDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails'->new($_) } @$_ ] };

declare 'MapStringContainerHealthDetails',
    as HashRef[ContainerHealthDetails()];

declare 'ExtendedStatusEntry',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails::ExtendedStatusEntry'];

coerce 'ExtendedStatusEntry',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails::ExtendedStatusEntry'->new($_) };

declare 'RepeatedExtendedStatusEntry',
    as ArrayRef[ExtendedStatusEntry()];

coerce 'RepeatedExtendedStatusEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::ContainerHealthDetails::ExtendedStatusEntry'->new($_) } @$_ ] };

declare 'MapStringExtendedStatusEntry',
    as HashRef[ExtendedStatusEntry()];

declare 'RemoteAgentDetails',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::RemoteAgentDetails'];

coerce 'RemoteAgentDetails',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::RemoteAgentDetails'->new($_) };

declare 'RepeatedRemoteAgentDetails',
    as ArrayRef[RemoteAgentDetails()];

coerce 'RepeatedRemoteAgentDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::RemoteAgentDetails'->new($_) } @$_ ] };

declare 'MapStringRemoteAgentDetails',
    as HashRef[RemoteAgentDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Beyondcorp::Appconnectors::V1::ResourceInfo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
