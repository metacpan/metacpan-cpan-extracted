package Google::Cloud::Apphub::V1::ExtendedMetadataSchema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExtendedMetadataSchema',
    as InstanceOf['Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema'];

coerce 'ExtendedMetadataSchema',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema'->new($_) };

declare 'RepeatedExtendedMetadataSchema',
    as ArrayRef[ExtendedMetadataSchema()];

coerce 'RepeatedExtendedMetadataSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ExtendedMetadataSchema::ExtendedMetadataSchema'->new($_) } @$_ ] };

declare 'MapStringExtendedMetadataSchema',
    as HashRef[ExtendedMetadataSchema()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::ExtendedMetadataSchema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
