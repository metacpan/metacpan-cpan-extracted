package Google::Cloud::Apphub::V1::Boundary::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Boundary',
    as InstanceOf['Google::Cloud::Apphub::V1::Boundary::Boundary'];

coerce 'Boundary',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Boundary::Boundary'->new($_) };

declare 'RepeatedBoundary',
    as ArrayRef[Boundary()];

coerce 'RepeatedBoundary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Boundary::Boundary'->new($_) } @$_ ] };

declare 'MapStringBoundary',
    as HashRef[Boundary()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::Boundary::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
