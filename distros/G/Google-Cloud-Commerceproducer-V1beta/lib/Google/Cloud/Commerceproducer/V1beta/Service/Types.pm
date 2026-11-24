package Google::Cloud::Commerceproducer::V1beta::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'ProductType',
    as (Int | Str);

declare 'DocumentRequirement',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement'];

coerce 'DocumentRequirement',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement'->new($_) };

declare 'RepeatedDocumentRequirement',
    as ArrayRef[DocumentRequirement()];

coerce 'RepeatedDocumentRequirement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement'->new($_) } @$_ ] };

declare 'MapStringDocumentRequirement',
    as HashRef[DocumentRequirement()];

declare 'DocumentTypeRequirement',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement::DocumentTypeRequirement'];

coerce 'DocumentTypeRequirement',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement::DocumentTypeRequirement'->new($_) };

declare 'RepeatedDocumentTypeRequirement',
    as ArrayRef[DocumentTypeRequirement()];

coerce 'RepeatedDocumentTypeRequirement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Service::Service::DocumentRequirement::DocumentTypeRequirement'->new($_) } @$_ ] };

declare 'MapStringDocumentTypeRequirement',
    as HashRef[DocumentTypeRequirement()];

declare 'RequirementLevel',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
