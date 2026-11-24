package Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetBindingMatchingResourceRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest'];

coerce 'GetBindingMatchingResourceRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest'->new($_) };

declare 'RepeatedGetBindingMatchingResourceRequest',
    as ArrayRef[GetBindingMatchingResourceRequest()];

coerce 'RepeatedGetBindingMatchingResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetBindingMatchingResourceRequest',
    as HashRef[GetBindingMatchingResourceRequest()];

declare 'ListBindingMatchingResourcesRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesRequest'];

coerce 'ListBindingMatchingResourcesRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesRequest'->new($_) };

declare 'RepeatedListBindingMatchingResourcesRequest',
    as ArrayRef[ListBindingMatchingResourcesRequest()];

coerce 'RepeatedListBindingMatchingResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListBindingMatchingResourcesRequest',
    as HashRef[ListBindingMatchingResourcesRequest()];

declare 'ListBindingMatchingResourcesResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesResponse'];

coerce 'ListBindingMatchingResourcesResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesResponse'->new($_) };

declare 'RepeatedListBindingMatchingResourcesResponse',
    as ArrayRef[ListBindingMatchingResourcesResponse()];

coerce 'RepeatedListBindingMatchingResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListBindingMatchingResourcesResponse',
    as HashRef[ListBindingMatchingResourcesResponse()];

declare 'BindingMatchingResource',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::BindingMatchingResource'];

coerce 'BindingMatchingResource',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::BindingMatchingResource'->new($_) };

declare 'RepeatedBindingMatchingResource',
    as ArrayRef[BindingMatchingResource()];

coerce 'RepeatedBindingMatchingResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::BindingMatchingResource'->new($_) } @$_ ] };

declare 'MapStringBindingMatchingResource',
    as HashRef[BindingMatchingResource()];

declare 'AutoProtectionDetails',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::AutoProtectionDetails'];

coerce 'AutoProtectionDetails',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::AutoProtectionDetails'->new($_) };

declare 'RepeatedAutoProtectionDetails',
    as ArrayRef[AutoProtectionDetails()];

coerce 'RepeatedAutoProtectionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::AutoProtectionDetails'->new($_) } @$_ ] };

declare 'MapStringAutoProtectionDetails',
    as HashRef[AutoProtectionDetails()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
