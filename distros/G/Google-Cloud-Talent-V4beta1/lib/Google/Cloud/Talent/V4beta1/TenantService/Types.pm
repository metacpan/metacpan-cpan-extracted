package Google::Cloud::Talent::V4beta1::TenantService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateTenantRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest'];

coerce 'CreateTenantRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest'->new($_) };

declare 'RepeatedCreateTenantRequest',
    as ArrayRef[CreateTenantRequest()];

coerce 'RepeatedCreateTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::TenantService::CreateTenantRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTenantRequest',
    as HashRef[CreateTenantRequest()];

declare 'GetTenantRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::TenantService::GetTenantRequest'];

coerce 'GetTenantRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::TenantService::GetTenantRequest'->new($_) };

declare 'RepeatedGetTenantRequest',
    as ArrayRef[GetTenantRequest()];

coerce 'RepeatedGetTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::TenantService::GetTenantRequest'->new($_) } @$_ ] };

declare 'MapStringGetTenantRequest',
    as HashRef[GetTenantRequest()];

declare 'UpdateTenantRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::TenantService::UpdateTenantRequest'];

coerce 'UpdateTenantRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::TenantService::UpdateTenantRequest'->new($_) };

declare 'RepeatedUpdateTenantRequest',
    as ArrayRef[UpdateTenantRequest()];

coerce 'RepeatedUpdateTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::TenantService::UpdateTenantRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTenantRequest',
    as HashRef[UpdateTenantRequest()];

declare 'DeleteTenantRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::TenantService::DeleteTenantRequest'];

coerce 'DeleteTenantRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::TenantService::DeleteTenantRequest'->new($_) };

declare 'RepeatedDeleteTenantRequest',
    as ArrayRef[DeleteTenantRequest()];

coerce 'RepeatedDeleteTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::TenantService::DeleteTenantRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTenantRequest',
    as HashRef[DeleteTenantRequest()];

declare 'ListTenantsRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::TenantService::ListTenantsRequest'];

coerce 'ListTenantsRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::TenantService::ListTenantsRequest'->new($_) };

declare 'RepeatedListTenantsRequest',
    as ArrayRef[ListTenantsRequest()];

coerce 'RepeatedListTenantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::TenantService::ListTenantsRequest'->new($_) } @$_ ] };

declare 'MapStringListTenantsRequest',
    as HashRef[ListTenantsRequest()];

declare 'ListTenantsResponse',
    as InstanceOf['Google::Cloud::Talent::V4beta1::TenantService::ListTenantsResponse'];

coerce 'ListTenantsResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::TenantService::ListTenantsResponse'->new($_) };

declare 'RepeatedListTenantsResponse',
    as ArrayRef[ListTenantsResponse()];

coerce 'RepeatedListTenantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::TenantService::ListTenantsResponse'->new($_) } @$_ ] };

declare 'MapStringListTenantsResponse',
    as HashRef[ListTenantsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::TenantService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
