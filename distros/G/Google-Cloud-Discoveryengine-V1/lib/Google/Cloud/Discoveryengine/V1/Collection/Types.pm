package Google::Cloud::Discoveryengine::V1::Collection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Collection',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Collection::Collection'];

coerce 'Collection',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Collection::Collection'->new($_) };

declare 'RepeatedCollection',
    as ArrayRef[Collection()];

coerce 'RepeatedCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Collection::Collection'->new($_) } @$_ ] };

declare 'MapStringCollection',
    as HashRef[Collection()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Collection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
