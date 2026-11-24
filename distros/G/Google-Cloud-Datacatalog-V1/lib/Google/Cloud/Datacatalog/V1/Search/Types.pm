package Google::Cloud::Datacatalog::V1::Search::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SearchResultType',
    as (Int | Str);

declare 'SearchCatalogResult',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult'];

coerce 'SearchCatalogResult',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult'->new($_) };

declare 'RepeatedSearchCatalogResult',
    as ArrayRef[SearchCatalogResult()];

coerce 'RepeatedSearchCatalogResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Search::SearchCatalogResult'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogResult',
    as HashRef[SearchCatalogResult()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Search::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
