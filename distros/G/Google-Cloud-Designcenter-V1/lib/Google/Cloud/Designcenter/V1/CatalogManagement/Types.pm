package Google::Cloud::Designcenter::V1::CatalogManagement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Space',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagement::Space'];

coerce 'Space',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagement::Space'->new($_) };

declare 'RepeatedSpace',
    as ArrayRef[Space()];

coerce 'RepeatedSpace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagement::Space'->new($_) } @$_ ] };

declare 'MapStringSpace',
    as HashRef[Space()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagement::Space::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagement::Space::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagement::Space::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'Catalog',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagement::Catalog'];

coerce 'Catalog',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagement::Catalog'->new($_) };

declare 'RepeatedCatalog',
    as ArrayRef[Catalog()];

coerce 'RepeatedCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagement::Catalog'->new($_) } @$_ ] };

declare 'MapStringCatalog',
    as HashRef[Catalog()];

declare 'CatalogTemplate',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplate'];

coerce 'CatalogTemplate',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplate'->new($_) };

declare 'RepeatedCatalogTemplate',
    as ArrayRef[CatalogTemplate()];

coerce 'RepeatedCatalogTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplate'->new($_) } @$_ ] };

declare 'MapStringCatalogTemplate',
    as HashRef[CatalogTemplate()];

declare 'CatalogTemplateRevision',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision'];

coerce 'CatalogTemplateRevision',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision'->new($_) };

declare 'RepeatedCatalogTemplateRevision',
    as ArrayRef[CatalogTemplateRevision()];

coerce 'RepeatedCatalogTemplateRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision'->new($_) } @$_ ] };

declare 'MapStringCatalogTemplateRevision',
    as HashRef[CatalogTemplateRevision()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagement::CatalogTemplateRevision::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::CatalogManagement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
