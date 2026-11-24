package Google::Cloud::Datacatalog::V1::Policytagmanager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Taxonomy',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy'];

coerce 'Taxonomy',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy'->new($_) };

declare 'RepeatedTaxonomy',
    as ArrayRef[Taxonomy()];

coerce 'RepeatedTaxonomy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy'->new($_) } @$_ ] };

declare 'MapStringTaxonomy',
    as HashRef[Taxonomy()];

declare 'PolicyType',
    as (Int | Str);

declare 'Service',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::Taxonomy::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'PolicyTag',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag'];

coerce 'PolicyTag',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag'->new($_) };

declare 'RepeatedPolicyTag',
    as ArrayRef[PolicyTag()];

coerce 'RepeatedPolicyTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::PolicyTag'->new($_) } @$_ ] };

declare 'MapStringPolicyTag',
    as HashRef[PolicyTag()];

declare 'CreateTaxonomyRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest'];

coerce 'CreateTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest'->new($_) };

declare 'RepeatedCreateTaxonomyRequest',
    as ArrayRef[CreateTaxonomyRequest()];

coerce 'RepeatedCreateTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::CreateTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTaxonomyRequest',
    as HashRef[CreateTaxonomyRequest()];

declare 'DeleteTaxonomyRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::DeleteTaxonomyRequest'];

coerce 'DeleteTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::DeleteTaxonomyRequest'->new($_) };

declare 'RepeatedDeleteTaxonomyRequest',
    as ArrayRef[DeleteTaxonomyRequest()];

coerce 'RepeatedDeleteTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::DeleteTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTaxonomyRequest',
    as HashRef[DeleteTaxonomyRequest()];

declare 'UpdateTaxonomyRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::UpdateTaxonomyRequest'];

coerce 'UpdateTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::UpdateTaxonomyRequest'->new($_) };

declare 'RepeatedUpdateTaxonomyRequest',
    as ArrayRef[UpdateTaxonomyRequest()];

coerce 'RepeatedUpdateTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::UpdateTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTaxonomyRequest',
    as HashRef[UpdateTaxonomyRequest()];

declare 'ListTaxonomiesRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesRequest'];

coerce 'ListTaxonomiesRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesRequest'->new($_) };

declare 'RepeatedListTaxonomiesRequest',
    as ArrayRef[ListTaxonomiesRequest()];

coerce 'RepeatedListTaxonomiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesRequest'->new($_) } @$_ ] };

declare 'MapStringListTaxonomiesRequest',
    as HashRef[ListTaxonomiesRequest()];

declare 'ListTaxonomiesResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesResponse'];

coerce 'ListTaxonomiesResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesResponse'->new($_) };

declare 'RepeatedListTaxonomiesResponse',
    as ArrayRef[ListTaxonomiesResponse()];

coerce 'RepeatedListTaxonomiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListTaxonomiesResponse'->new($_) } @$_ ] };

declare 'MapStringListTaxonomiesResponse',
    as HashRef[ListTaxonomiesResponse()];

declare 'GetTaxonomyRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::GetTaxonomyRequest'];

coerce 'GetTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::GetTaxonomyRequest'->new($_) };

declare 'RepeatedGetTaxonomyRequest',
    as ArrayRef[GetTaxonomyRequest()];

coerce 'RepeatedGetTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::GetTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringGetTaxonomyRequest',
    as HashRef[GetTaxonomyRequest()];

declare 'CreatePolicyTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::CreatePolicyTagRequest'];

coerce 'CreatePolicyTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::CreatePolicyTagRequest'->new($_) };

declare 'RepeatedCreatePolicyTagRequest',
    as ArrayRef[CreatePolicyTagRequest()];

coerce 'RepeatedCreatePolicyTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::CreatePolicyTagRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePolicyTagRequest',
    as HashRef[CreatePolicyTagRequest()];

declare 'DeletePolicyTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::DeletePolicyTagRequest'];

coerce 'DeletePolicyTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::DeletePolicyTagRequest'->new($_) };

declare 'RepeatedDeletePolicyTagRequest',
    as ArrayRef[DeletePolicyTagRequest()];

coerce 'RepeatedDeletePolicyTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::DeletePolicyTagRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePolicyTagRequest',
    as HashRef[DeletePolicyTagRequest()];

declare 'UpdatePolicyTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::UpdatePolicyTagRequest'];

coerce 'UpdatePolicyTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::UpdatePolicyTagRequest'->new($_) };

declare 'RepeatedUpdatePolicyTagRequest',
    as ArrayRef[UpdatePolicyTagRequest()];

coerce 'RepeatedUpdatePolicyTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::UpdatePolicyTagRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyTagRequest',
    as HashRef[UpdatePolicyTagRequest()];

declare 'ListPolicyTagsRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsRequest'];

coerce 'ListPolicyTagsRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsRequest'->new($_) };

declare 'RepeatedListPolicyTagsRequest',
    as ArrayRef[ListPolicyTagsRequest()];

coerce 'RepeatedListPolicyTagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsRequest'->new($_) } @$_ ] };

declare 'MapStringListPolicyTagsRequest',
    as HashRef[ListPolicyTagsRequest()];

declare 'ListPolicyTagsResponse',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsResponse'];

coerce 'ListPolicyTagsResponse',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsResponse'->new($_) };

declare 'RepeatedListPolicyTagsResponse',
    as ArrayRef[ListPolicyTagsResponse()];

coerce 'RepeatedListPolicyTagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::ListPolicyTagsResponse'->new($_) } @$_ ] };

declare 'MapStringListPolicyTagsResponse',
    as HashRef[ListPolicyTagsResponse()];

declare 'GetPolicyTagRequest',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Policytagmanager::GetPolicyTagRequest'];

coerce 'GetPolicyTagRequest',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Policytagmanager::GetPolicyTagRequest'->new($_) };

declare 'RepeatedGetPolicyTagRequest',
    as ArrayRef[GetPolicyTagRequest()];

coerce 'RepeatedGetPolicyTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Policytagmanager::GetPolicyTagRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyTagRequest',
    as HashRef[GetPolicyTagRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Policytagmanager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
