package Google::Cloud::Oracledatabase::V1::DbSystemShape::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbSystemShape',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape'];

coerce 'DbSystemShape',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape'->new($_) };

declare 'RepeatedDbSystemShape',
    as ArrayRef[DbSystemShape()];

coerce 'RepeatedDbSystemShape',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape'->new($_) } @$_ ] };

declare 'MapStringDbSystemShape',
    as HashRef[DbSystemShape()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystemShape::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
