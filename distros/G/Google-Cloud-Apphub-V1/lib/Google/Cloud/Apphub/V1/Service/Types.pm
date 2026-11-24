package Google::Cloud::Apphub::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Cloud::Apphub::V1::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'State',
    as (Int | Str);

declare 'ServiceReference',
    as InstanceOf['Google::Cloud::Apphub::V1::Service::ServiceReference'];

coerce 'ServiceReference',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Service::ServiceReference'->new($_) };

declare 'RepeatedServiceReference',
    as ArrayRef[ServiceReference()];

coerce 'RepeatedServiceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Service::ServiceReference'->new($_) } @$_ ] };

declare 'MapStringServiceReference',
    as HashRef[ServiceReference()];

declare 'ServiceProperties',
    as InstanceOf['Google::Cloud::Apphub::V1::Service::ServiceProperties'];

coerce 'ServiceProperties',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Service::ServiceProperties'->new($_) };

declare 'RepeatedServiceProperties',
    as ArrayRef[ServiceProperties()];

coerce 'RepeatedServiceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Service::ServiceProperties'->new($_) } @$_ ] };

declare 'MapStringServiceProperties',
    as HashRef[ServiceProperties()];

declare 'ExtendedMetadataEntry',
    as InstanceOf['Google::Cloud::Apphub::V1::Service::ServiceProperties::ExtendedMetadataEntry'];

coerce 'ExtendedMetadataEntry',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Service::ServiceProperties::ExtendedMetadataEntry'->new($_) };

declare 'RepeatedExtendedMetadataEntry',
    as ArrayRef[ExtendedMetadataEntry()];

coerce 'RepeatedExtendedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Service::ServiceProperties::ExtendedMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringExtendedMetadataEntry',
    as HashRef[ExtendedMetadataEntry()];

declare 'DiscoveredService',
    as InstanceOf['Google::Cloud::Apphub::V1::Service::DiscoveredService'];

coerce 'DiscoveredService',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Service::DiscoveredService'->new($_) };

declare 'RepeatedDiscoveredService',
    as ArrayRef[DiscoveredService()];

coerce 'RepeatedDiscoveredService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Service::DiscoveredService'->new($_) } @$_ ] };

declare 'MapStringDiscoveredService',
    as HashRef[DiscoveredService()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
