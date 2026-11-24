package Google::Cloud::Agentregistry::V1::Properties::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Interface',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Properties::Interface'];

coerce 'Interface',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Properties::Interface'->new($_) };

declare 'RepeatedInterface',
    as ArrayRef[Interface()];

coerce 'RepeatedInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Properties::Interface'->new($_) } @$_ ] };

declare 'MapStringInterface',
    as HashRef[Interface()];

declare 'ProtocolBinding',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Properties::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
