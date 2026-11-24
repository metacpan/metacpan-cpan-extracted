package Google::Cloud::Discoveryengine::V1::UserStore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserStore',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserStore::UserStore'];

coerce 'UserStore',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore'->new($_) };

declare 'RepeatedUserStore',
    as ArrayRef[UserStore()];

coerce 'RepeatedUserStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore'->new($_) } @$_ ] };

declare 'MapStringUserStore',
    as HashRef[UserStore()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserStore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
