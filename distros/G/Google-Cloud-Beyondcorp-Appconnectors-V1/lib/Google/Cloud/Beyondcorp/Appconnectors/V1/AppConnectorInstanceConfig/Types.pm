package Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AppConnectorInstanceConfig',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig'];

coerce 'AppConnectorInstanceConfig',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig'->new($_) };

declare 'RepeatedAppConnectorInstanceConfig',
    as ArrayRef[AppConnectorInstanceConfig()];

coerce 'RepeatedAppConnectorInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringAppConnectorInstanceConfig',
    as HashRef[AppConnectorInstanceConfig()];

declare 'NotificationConfig',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig'];

coerce 'NotificationConfig',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig'->new($_) };

declare 'RepeatedNotificationConfig',
    as ArrayRef[NotificationConfig()];

coerce 'RepeatedNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig'->new($_) } @$_ ] };

declare 'MapStringNotificationConfig',
    as HashRef[NotificationConfig()];

declare 'CloudPubSubNotificationConfig',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig::CloudPubSubNotificationConfig'];

coerce 'CloudPubSubNotificationConfig',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig::CloudPubSubNotificationConfig'->new($_) };

declare 'RepeatedCloudPubSubNotificationConfig',
    as ArrayRef[CloudPubSubNotificationConfig()];

coerce 'RepeatedCloudPubSubNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig::CloudPubSubNotificationConfig'->new($_) } @$_ ] };

declare 'MapStringCloudPubSubNotificationConfig',
    as HashRef[CloudPubSubNotificationConfig()];

declare 'ImageConfig',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::ImageConfig'];

coerce 'ImageConfig',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::ImageConfig'->new($_) };

declare 'RepeatedImageConfig',
    as ArrayRef[ImageConfig()];

coerce 'RepeatedImageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::ImageConfig'->new($_) } @$_ ] };

declare 'MapStringImageConfig',
    as HashRef[ImageConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
