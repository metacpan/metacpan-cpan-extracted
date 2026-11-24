package Google::Cloud::Commerceproducer::V1beta::SkuGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SkuGroup',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup'];

coerce 'SkuGroup',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup'->new($_) };

declare 'RepeatedSkuGroup',
    as ArrayRef[SkuGroup()];

coerce 'RepeatedSkuGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::SkuGroup::SkuGroup'->new($_) } @$_ ] };

declare 'MapStringSkuGroup',
    as HashRef[SkuGroup()];

1;

__END__

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::SkuGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
