package Google::Cloud::Edgenetwork::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourceState',
    as (Int | Str);

declare 'RemotePeeringNetworkType',
    as (Int | Str);

declare 'Zone',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Zone'];

coerce 'Zone',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Zone'->new($_) };

declare 'RepeatedZone',
    as ArrayRef[Zone()];

coerce 'RepeatedZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Zone'->new($_) } @$_ ] };

declare 'MapStringZone',
    as HashRef[Zone()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Zone::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Zone::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Zone::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Network',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Network::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Network::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Network::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Subnet',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Subnet'];

coerce 'Subnet',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Subnet'->new($_) };

declare 'RepeatedSubnet',
    as ArrayRef[Subnet()];

coerce 'RepeatedSubnet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Subnet'->new($_) } @$_ ] };

declare 'MapStringSubnet',
    as HashRef[Subnet()];

declare 'BondingType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Subnet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Subnet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Subnet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Interconnect',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Interconnect'];

coerce 'Interconnect',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Interconnect'->new($_) };

declare 'RepeatedInterconnect',
    as ArrayRef[Interconnect()];

coerce 'RepeatedInterconnect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Interconnect'->new($_) } @$_ ] };

declare 'MapStringInterconnect',
    as HashRef[Interconnect()];

declare 'InterconnectType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Interconnect::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Interconnect::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Interconnect::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'InterconnectAttachment',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectAttachment'];

coerce 'InterconnectAttachment',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectAttachment'->new($_) };

declare 'RepeatedInterconnectAttachment',
    as ArrayRef[InterconnectAttachment()];

coerce 'RepeatedInterconnectAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectAttachment'->new($_) } @$_ ] };

declare 'MapStringInterconnectAttachment',
    as HashRef[InterconnectAttachment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectAttachment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectAttachment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectAttachment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Router',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Router'];

coerce 'Router',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Router'->new($_) };

declare 'RepeatedRouter',
    as ArrayRef[Router()];

coerce 'RepeatedRouter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Router'->new($_) } @$_ ] };

declare 'MapStringRouter',
    as HashRef[Router()];

declare 'Interface',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Router::Interface'];

coerce 'Interface',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Router::Interface'->new($_) };

declare 'RepeatedInterface',
    as ArrayRef[Interface()];

coerce 'RepeatedInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Router::Interface'->new($_) } @$_ ] };

declare 'MapStringInterface',
    as HashRef[Interface()];

declare 'BgpPeer',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Router::BgpPeer'];

coerce 'BgpPeer',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Router::BgpPeer'->new($_) };

declare 'RepeatedBgpPeer',
    as ArrayRef[BgpPeer()];

coerce 'RepeatedBgpPeer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Router::BgpPeer'->new($_) } @$_ ] };

declare 'MapStringBgpPeer',
    as HashRef[BgpPeer()];

declare 'Bgp',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Router::Bgp'];

coerce 'Bgp',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Router::Bgp'->new($_) };

declare 'RepeatedBgp',
    as ArrayRef[Bgp()];

coerce 'RepeatedBgp',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Router::Bgp'->new($_) } @$_ ] };

declare 'MapStringBgp',
    as HashRef[Bgp()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::Router::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::Router::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::Router::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LinkLayerAddress',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::LinkLayerAddress'];

coerce 'LinkLayerAddress',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::LinkLayerAddress'->new($_) };

declare 'RepeatedLinkLayerAddress',
    as ArrayRef[LinkLayerAddress()];

coerce 'RepeatedLinkLayerAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::LinkLayerAddress'->new($_) } @$_ ] };

declare 'MapStringLinkLayerAddress',
    as HashRef[LinkLayerAddress()];

declare 'SubnetStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::SubnetStatus'];

coerce 'SubnetStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::SubnetStatus'->new($_) };

declare 'RepeatedSubnetStatus',
    as ArrayRef[SubnetStatus()];

coerce 'RepeatedSubnetStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::SubnetStatus'->new($_) } @$_ ] };

declare 'MapStringSubnetStatus',
    as HashRef[SubnetStatus()];

declare 'InterconnectDiagnostics',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics'];

coerce 'InterconnectDiagnostics',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics'->new($_) };

declare 'RepeatedInterconnectDiagnostics',
    as ArrayRef[InterconnectDiagnostics()];

coerce 'RepeatedInterconnectDiagnostics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics'->new($_) } @$_ ] };

declare 'MapStringInterconnectDiagnostics',
    as HashRef[InterconnectDiagnostics()];

declare 'LinkStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkStatus'];

coerce 'LinkStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkStatus'->new($_) };

declare 'RepeatedLinkStatus',
    as ArrayRef[LinkStatus()];

coerce 'RepeatedLinkStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkStatus'->new($_) } @$_ ] };

declare 'MapStringLinkStatus',
    as HashRef[LinkStatus()];

declare 'PacketCounts',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::PacketCounts'];

coerce 'PacketCounts',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::PacketCounts'->new($_) };

declare 'RepeatedPacketCounts',
    as ArrayRef[PacketCounts()];

coerce 'RepeatedPacketCounts',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::PacketCounts'->new($_) } @$_ ] };

declare 'MapStringPacketCounts',
    as HashRef[PacketCounts()];

declare 'LinkLACPStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkLACPStatus'];

coerce 'LinkLACPStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkLACPStatus'->new($_) };

declare 'RepeatedLinkLACPStatus',
    as ArrayRef[LinkLACPStatus()];

coerce 'RepeatedLinkLACPStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkLACPStatus'->new($_) } @$_ ] };

declare 'MapStringLinkLACPStatus',
    as HashRef[LinkLACPStatus()];

declare 'State',
    as (Int | Str);

declare 'LinkLLDPStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkLLDPStatus'];

coerce 'LinkLLDPStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkLLDPStatus'->new($_) };

declare 'RepeatedLinkLLDPStatus',
    as ArrayRef[LinkLLDPStatus()];

coerce 'RepeatedLinkLLDPStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::InterconnectDiagnostics::LinkLLDPStatus'->new($_) } @$_ ] };

declare 'MapStringLinkLLDPStatus',
    as HashRef[LinkLLDPStatus()];

declare 'RouterStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::RouterStatus'];

coerce 'RouterStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::RouterStatus'->new($_) };

declare 'RepeatedRouterStatus',
    as ArrayRef[RouterStatus()];

coerce 'RepeatedRouterStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::RouterStatus'->new($_) } @$_ ] };

declare 'MapStringRouterStatus',
    as HashRef[RouterStatus()];

declare 'BgpPeerStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::RouterStatus::BgpPeerStatus'];

coerce 'BgpPeerStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::RouterStatus::BgpPeerStatus'->new($_) };

declare 'RepeatedBgpPeerStatus',
    as ArrayRef[BgpPeerStatus()];

coerce 'RepeatedBgpPeerStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::RouterStatus::BgpPeerStatus'->new($_) } @$_ ] };

declare 'MapStringBgpPeerStatus',
    as HashRef[BgpPeerStatus()];

declare 'BgpStatus',
    as (Int | Str);

declare 'PrefixCounter',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Resources::RouterStatus::PrefixCounter'];

coerce 'PrefixCounter',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Resources::RouterStatus::PrefixCounter'->new($_) };

declare 'RepeatedPrefixCounter',
    as ArrayRef[PrefixCounter()];

coerce 'RepeatedPrefixCounter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Resources::RouterStatus::PrefixCounter'->new($_) } @$_ ] };

declare 'MapStringPrefixCounter',
    as HashRef[PrefixCounter()];

1;

__END__

=head1 NAME

Google::Cloud::Edgenetwork::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
