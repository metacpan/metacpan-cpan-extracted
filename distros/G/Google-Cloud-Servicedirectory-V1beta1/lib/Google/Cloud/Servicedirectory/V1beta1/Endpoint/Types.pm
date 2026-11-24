package Google::Cloud::Servicedirectory::V1beta1::Endpoint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Endpoint',
    as InstanceOf['Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1beta1::Endpoint::Endpoint::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Servicedirectory::V1beta1::Endpoint::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
