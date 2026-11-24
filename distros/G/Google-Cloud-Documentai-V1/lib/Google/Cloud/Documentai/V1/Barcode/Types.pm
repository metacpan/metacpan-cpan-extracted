package Google::Cloud::Documentai::V1::Barcode::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Barcode',
    as InstanceOf['Google::Cloud::Documentai::V1::Barcode::Barcode'];

coerce 'Barcode',
    from HashRef, via { 'Google::Cloud::Documentai::V1::Barcode::Barcode'->new($_) };

declare 'RepeatedBarcode',
    as ArrayRef[Barcode()];

coerce 'RepeatedBarcode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::Barcode::Barcode'->new($_) } @$_ ] };

declare 'MapStringBarcode',
    as HashRef[Barcode()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::Barcode::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
