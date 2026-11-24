package Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSynonymSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest'];

coerce 'CreateSynonymSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest'->new($_) };

declare 'RepeatedCreateSynonymSetRequest',
    as ArrayRef[CreateSynonymSetRequest()];

coerce 'RepeatedCreateSynonymSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSynonymSetRequest',
    as HashRef[CreateSynonymSetRequest()];

declare 'GetSynonymSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::GetSynonymSetRequest'];

coerce 'GetSynonymSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::GetSynonymSetRequest'->new($_) };

declare 'RepeatedGetSynonymSetRequest',
    as ArrayRef[GetSynonymSetRequest()];

coerce 'RepeatedGetSynonymSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::GetSynonymSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetSynonymSetRequest',
    as HashRef[GetSynonymSetRequest()];

declare 'ListSynonymSetsRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsRequest'];

coerce 'ListSynonymSetsRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsRequest'->new($_) };

declare 'RepeatedListSynonymSetsRequest',
    as ArrayRef[ListSynonymSetsRequest()];

coerce 'RepeatedListSynonymSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListSynonymSetsRequest',
    as HashRef[ListSynonymSetsRequest()];

declare 'ListSynonymSetsResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsResponse'];

coerce 'ListSynonymSetsResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsResponse'->new($_) };

declare 'RepeatedListSynonymSetsResponse',
    as ArrayRef[ListSynonymSetsResponse()];

coerce 'RepeatedListSynonymSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::ListSynonymSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListSynonymSetsResponse',
    as HashRef[ListSynonymSetsResponse()];

declare 'UpdateSynonymSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::UpdateSynonymSetRequest'];

coerce 'UpdateSynonymSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::UpdateSynonymSetRequest'->new($_) };

declare 'RepeatedUpdateSynonymSetRequest',
    as ArrayRef[UpdateSynonymSetRequest()];

coerce 'RepeatedUpdateSynonymSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::UpdateSynonymSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSynonymSetRequest',
    as HashRef[UpdateSynonymSetRequest()];

declare 'DeleteSynonymSetRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::DeleteSynonymSetRequest'];

coerce 'DeleteSynonymSetRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::DeleteSynonymSetRequest'->new($_) };

declare 'RepeatedDeleteSynonymSetRequest',
    as ArrayRef[DeleteSynonymSetRequest()];

coerce 'RepeatedDeleteSynonymSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::DeleteSynonymSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSynonymSetRequest',
    as HashRef[DeleteSynonymSetRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
