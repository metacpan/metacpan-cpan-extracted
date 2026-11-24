package Google::Cloud::Ces::V1::ConnectorToolset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConnectorToolset',
    as InstanceOf['Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset'];

coerce 'ConnectorToolset',
    from HashRef, via { 'Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset'->new($_) };

declare 'RepeatedConnectorToolset',
    as ArrayRef[ConnectorToolset()];

coerce 'RepeatedConnectorToolset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset'->new($_) } @$_ ] };

declare 'MapStringConnectorToolset',
    as HashRef[ConnectorToolset()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::ConnectorToolset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
