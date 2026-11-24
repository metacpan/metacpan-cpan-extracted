package Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourceOwners',
    as InstanceOf['Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners'];

coerce 'ResourceOwners',
    from HashRef, via { 'Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners'->new($_) };

declare 'RepeatedResourceOwners',
    as ArrayRef[ResourceOwners()];

coerce 'RepeatedResourceOwners',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::ResourceOwners'->new($_) } @$_ ] };

declare 'MapStringResourceOwners',
    as HashRef[ResourceOwners()];

1;

__END__

=head1 NAME

Google::Cloud::Asset::V1::AssetEnrichmentResourceowners::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
