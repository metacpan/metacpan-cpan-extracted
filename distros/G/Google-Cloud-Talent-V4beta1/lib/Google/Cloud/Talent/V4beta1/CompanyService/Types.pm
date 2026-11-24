package Google::Cloud::Talent::V4beta1::CompanyService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCompanyRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest'];

coerce 'CreateCompanyRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest'->new($_) };

declare 'RepeatedCreateCompanyRequest',
    as ArrayRef[CreateCompanyRequest()];

coerce 'RepeatedCreateCompanyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompanyService::CreateCompanyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCompanyRequest',
    as HashRef[CreateCompanyRequest()];

declare 'GetCompanyRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompanyService::GetCompanyRequest'];

coerce 'GetCompanyRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompanyService::GetCompanyRequest'->new($_) };

declare 'RepeatedGetCompanyRequest',
    as ArrayRef[GetCompanyRequest()];

coerce 'RepeatedGetCompanyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompanyService::GetCompanyRequest'->new($_) } @$_ ] };

declare 'MapStringGetCompanyRequest',
    as HashRef[GetCompanyRequest()];

declare 'UpdateCompanyRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompanyService::UpdateCompanyRequest'];

coerce 'UpdateCompanyRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompanyService::UpdateCompanyRequest'->new($_) };

declare 'RepeatedUpdateCompanyRequest',
    as ArrayRef[UpdateCompanyRequest()];

coerce 'RepeatedUpdateCompanyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompanyService::UpdateCompanyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCompanyRequest',
    as HashRef[UpdateCompanyRequest()];

declare 'DeleteCompanyRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompanyService::DeleteCompanyRequest'];

coerce 'DeleteCompanyRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompanyService::DeleteCompanyRequest'->new($_) };

declare 'RepeatedDeleteCompanyRequest',
    as ArrayRef[DeleteCompanyRequest()];

coerce 'RepeatedDeleteCompanyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompanyService::DeleteCompanyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCompanyRequest',
    as HashRef[DeleteCompanyRequest()];

declare 'ListCompaniesRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesRequest'];

coerce 'ListCompaniesRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesRequest'->new($_) };

declare 'RepeatedListCompaniesRequest',
    as ArrayRef[ListCompaniesRequest()];

coerce 'RepeatedListCompaniesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesRequest'->new($_) } @$_ ] };

declare 'MapStringListCompaniesRequest',
    as HashRef[ListCompaniesRequest()];

declare 'ListCompaniesResponse',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesResponse'];

coerce 'ListCompaniesResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesResponse'->new($_) };

declare 'RepeatedListCompaniesResponse',
    as ArrayRef[ListCompaniesResponse()];

coerce 'RepeatedListCompaniesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompanyService::ListCompaniesResponse'->new($_) } @$_ ] };

declare 'MapStringListCompaniesResponse',
    as HashRef[ListCompaniesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::CompanyService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
