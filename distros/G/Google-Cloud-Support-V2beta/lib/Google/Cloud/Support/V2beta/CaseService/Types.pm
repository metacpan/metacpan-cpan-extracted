package Google::Cloud::Support::V2beta::CaseService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetCaseRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::GetCaseRequest'];

coerce 'GetCaseRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::GetCaseRequest'->new($_) };

declare 'RepeatedGetCaseRequest',
    as ArrayRef[GetCaseRequest()];

coerce 'RepeatedGetCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::GetCaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetCaseRequest',
    as HashRef[GetCaseRequest()];

declare 'CreateCaseRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::CreateCaseRequest'];

coerce 'CreateCaseRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::CreateCaseRequest'->new($_) };

declare 'RepeatedCreateCaseRequest',
    as ArrayRef[CreateCaseRequest()];

coerce 'RepeatedCreateCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::CreateCaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCaseRequest',
    as HashRef[CreateCaseRequest()];

declare 'ListCasesRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::ListCasesRequest'];

coerce 'ListCasesRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::ListCasesRequest'->new($_) };

declare 'RepeatedListCasesRequest',
    as ArrayRef[ListCasesRequest()];

coerce 'RepeatedListCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::ListCasesRequest'->new($_) } @$_ ] };

declare 'MapStringListCasesRequest',
    as HashRef[ListCasesRequest()];

declare 'ListCasesResponse',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::ListCasesResponse'];

coerce 'ListCasesResponse',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::ListCasesResponse'->new($_) };

declare 'RepeatedListCasesResponse',
    as ArrayRef[ListCasesResponse()];

coerce 'RepeatedListCasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::ListCasesResponse'->new($_) } @$_ ] };

declare 'MapStringListCasesResponse',
    as HashRef[ListCasesResponse()];

declare 'SearchCasesRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::SearchCasesRequest'];

coerce 'SearchCasesRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::SearchCasesRequest'->new($_) };

declare 'RepeatedSearchCasesRequest',
    as ArrayRef[SearchCasesRequest()];

coerce 'RepeatedSearchCasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::SearchCasesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchCasesRequest',
    as HashRef[SearchCasesRequest()];

declare 'SearchCasesResponse',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::SearchCasesResponse'];

coerce 'SearchCasesResponse',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::SearchCasesResponse'->new($_) };

declare 'RepeatedSearchCasesResponse',
    as ArrayRef[SearchCasesResponse()];

coerce 'RepeatedSearchCasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::SearchCasesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchCasesResponse',
    as HashRef[SearchCasesResponse()];

declare 'EscalateCaseRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::EscalateCaseRequest'];

coerce 'EscalateCaseRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::EscalateCaseRequest'->new($_) };

declare 'RepeatedEscalateCaseRequest',
    as ArrayRef[EscalateCaseRequest()];

coerce 'RepeatedEscalateCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::EscalateCaseRequest'->new($_) } @$_ ] };

declare 'MapStringEscalateCaseRequest',
    as HashRef[EscalateCaseRequest()];

declare 'UpdateCaseRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::UpdateCaseRequest'];

coerce 'UpdateCaseRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::UpdateCaseRequest'->new($_) };

declare 'RepeatedUpdateCaseRequest',
    as ArrayRef[UpdateCaseRequest()];

coerce 'RepeatedUpdateCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::UpdateCaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCaseRequest',
    as HashRef[UpdateCaseRequest()];

declare 'CloseCaseRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::CloseCaseRequest'];

coerce 'CloseCaseRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::CloseCaseRequest'->new($_) };

declare 'RepeatedCloseCaseRequest',
    as ArrayRef[CloseCaseRequest()];

coerce 'RepeatedCloseCaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::CloseCaseRequest'->new($_) } @$_ ] };

declare 'MapStringCloseCaseRequest',
    as HashRef[CloseCaseRequest()];

declare 'SearchCaseClassificationsRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest'];

coerce 'SearchCaseClassificationsRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest'->new($_) };

declare 'RepeatedSearchCaseClassificationsRequest',
    as ArrayRef[SearchCaseClassificationsRequest()];

coerce 'RepeatedSearchCaseClassificationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchCaseClassificationsRequest',
    as HashRef[SearchCaseClassificationsRequest()];

declare 'SearchCaseClassificationsResponse',
    as InstanceOf['Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse'];

coerce 'SearchCaseClassificationsResponse',
    from HashRef, via { 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse'->new($_) };

declare 'RepeatedSearchCaseClassificationsResponse',
    as ArrayRef[SearchCaseClassificationsResponse()];

coerce 'RepeatedSearchCaseClassificationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchCaseClassificationsResponse',
    as HashRef[SearchCaseClassificationsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::CaseService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
