package Google::Cloud::Ces::V1beta::Mocks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MockedToolCall',
    as InstanceOf['Google::Cloud::Ces::V1beta::Mocks::MockedToolCall'];

coerce 'MockedToolCall',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Mocks::MockedToolCall'->new($_) };

declare 'RepeatedMockedToolCall',
    as ArrayRef[MockedToolCall()];

coerce 'RepeatedMockedToolCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Mocks::MockedToolCall'->new($_) } @$_ ] };

declare 'MapStringMockedToolCall',
    as HashRef[MockedToolCall()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Mocks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
