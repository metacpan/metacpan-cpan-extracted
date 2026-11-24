package Google::Cloud::Ces::V1::Toolset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Toolset',
    as InstanceOf['Google::Cloud::Ces::V1::Toolset::Toolset'];

coerce 'Toolset',
    from HashRef, via { 'Google::Cloud::Ces::V1::Toolset::Toolset'->new($_) };

declare 'RepeatedToolset',
    as ArrayRef[Toolset()];

coerce 'RepeatedToolset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Toolset::Toolset'->new($_) } @$_ ] };

declare 'MapStringToolset',
    as HashRef[Toolset()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Toolset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
