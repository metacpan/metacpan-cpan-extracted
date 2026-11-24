package Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeployPolicyNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent'];

coerce 'DeployPolicyNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent'->new($_) };

declare 'RepeatedDeployPolicyNotificationEvent',
    as ArrayRef[DeployPolicyNotificationEvent()];

coerce 'RepeatedDeployPolicyNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringDeployPolicyNotificationEvent',
    as HashRef[DeployPolicyNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
