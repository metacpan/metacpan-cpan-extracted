package Google::Cloud::Agentregistry::V1::Endpoint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Endpoint',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Endpoint::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Endpoint::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Endpoint::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Endpoint::Endpoint::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Endpoint::Endpoint::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Endpoint::Endpoint::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Endpoint::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
