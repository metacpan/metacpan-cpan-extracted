package Google::Cloud::Ces::V1beta::Omnichannel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Omnichannel',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel'];

coerce 'Omnichannel',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel'->new($_) };

declare 'RepeatedOmnichannel',
    as ArrayRef[Omnichannel()];

coerce 'RepeatedOmnichannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::Omnichannel'->new($_) } @$_ ] };

declare 'MapStringOmnichannel',
    as HashRef[Omnichannel()];

declare 'OmnichannelIntegrationConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig'];

coerce 'OmnichannelIntegrationConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig'->new($_) };

declare 'RepeatedOmnichannelIntegrationConfig',
    as ArrayRef[OmnichannelIntegrationConfig()];

coerce 'RepeatedOmnichannelIntegrationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig'->new($_) } @$_ ] };

declare 'MapStringOmnichannelIntegrationConfig',
    as HashRef[OmnichannelIntegrationConfig()];

declare 'ChannelConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfig'];

coerce 'ChannelConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfig'->new($_) };

declare 'RepeatedChannelConfig',
    as ArrayRef[ChannelConfig()];

coerce 'RepeatedChannelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfig'->new($_) } @$_ ] };

declare 'MapStringChannelConfig',
    as HashRef[ChannelConfig()];

declare 'WhatsappConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::WhatsappConfig'];

coerce 'WhatsappConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::WhatsappConfig'->new($_) };

declare 'RepeatedWhatsappConfig',
    as ArrayRef[WhatsappConfig()];

coerce 'RepeatedWhatsappConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::WhatsappConfig'->new($_) } @$_ ] };

declare 'MapStringWhatsappConfig',
    as HashRef[WhatsappConfig()];

declare 'SubscriberConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfig'];

coerce 'SubscriberConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfig'->new($_) };

declare 'RepeatedSubscriberConfig',
    as ArrayRef[SubscriberConfig()];

coerce 'RepeatedSubscriberConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfig'->new($_) } @$_ ] };

declare 'MapStringSubscriberConfig',
    as HashRef[SubscriberConfig()];

declare 'CesAppConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::CesAppConfig'];

coerce 'CesAppConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::CesAppConfig'->new($_) };

declare 'RepeatedCesAppConfig',
    as ArrayRef[CesAppConfig()];

coerce 'RepeatedCesAppConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::CesAppConfig'->new($_) } @$_ ] };

declare 'MapStringCesAppConfig',
    as HashRef[CesAppConfig()];

declare 'RoutingConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfig'];

coerce 'RoutingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfig'->new($_) };

declare 'RepeatedRoutingConfig',
    as ArrayRef[RoutingConfig()];

coerce 'RepeatedRoutingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfig'->new($_) } @$_ ] };

declare 'MapStringRoutingConfig',
    as HashRef[RoutingConfig()];

declare 'ChannelConfigsEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfigsEntry'];

coerce 'ChannelConfigsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfigsEntry'->new($_) };

declare 'RepeatedChannelConfigsEntry',
    as ArrayRef[ChannelConfigsEntry()];

coerce 'RepeatedChannelConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::ChannelConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringChannelConfigsEntry',
    as HashRef[ChannelConfigsEntry()];

declare 'SubscriberConfigsEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfigsEntry'];

coerce 'SubscriberConfigsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfigsEntry'->new($_) };

declare 'RepeatedSubscriberConfigsEntry',
    as ArrayRef[SubscriberConfigsEntry()];

coerce 'RepeatedSubscriberConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::SubscriberConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringSubscriberConfigsEntry',
    as HashRef[SubscriberConfigsEntry()];

declare 'RoutingConfigsEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfigsEntry'];

coerce 'RoutingConfigsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfigsEntry'->new($_) };

declare 'RepeatedRoutingConfigsEntry',
    as ArrayRef[RoutingConfigsEntry()];

coerce 'RepeatedRoutingConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Omnichannel::OmnichannelIntegrationConfig::RoutingConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringRoutingConfigsEntry',
    as HashRef[RoutingConfigsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Omnichannel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
