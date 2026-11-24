package Google::Cloud::Discoveryengine::V1::IdentityMappingStore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IdentityMappingStore',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore'];

coerce 'IdentityMappingStore',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore'->new($_) };

declare 'RepeatedIdentityMappingStore',
    as ArrayRef[IdentityMappingStore()];

coerce 'RepeatedIdentityMappingStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore'->new($_) } @$_ ] };

declare 'MapStringIdentityMappingStore',
    as HashRef[IdentityMappingStore()];

declare 'IdentityMappingEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingEntry'];

coerce 'IdentityMappingEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingEntry'->new($_) };

declare 'RepeatedIdentityMappingEntry',
    as ArrayRef[IdentityMappingEntry()];

coerce 'RepeatedIdentityMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingEntry'->new($_) } @$_ ] };

declare 'MapStringIdentityMappingEntry',
    as HashRef[IdentityMappingEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::IdentityMappingStore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
