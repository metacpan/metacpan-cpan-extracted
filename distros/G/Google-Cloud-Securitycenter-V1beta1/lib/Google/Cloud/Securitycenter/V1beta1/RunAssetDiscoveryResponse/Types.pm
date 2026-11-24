package Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunAssetDiscoveryResponse',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse'];

coerce 'RunAssetDiscoveryResponse',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse'->new($_) };

declare 'RepeatedRunAssetDiscoveryResponse',
    as ArrayRef[RunAssetDiscoveryResponse()];

coerce 'RepeatedRunAssetDiscoveryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::RunAssetDiscoveryResponse'->new($_) } @$_ ] };

declare 'MapStringRunAssetDiscoveryResponse',
    as HashRef[RunAssetDiscoveryResponse()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
