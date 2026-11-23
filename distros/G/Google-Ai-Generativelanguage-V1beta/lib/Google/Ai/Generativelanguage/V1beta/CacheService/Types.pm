package Google::Ai::Generativelanguage::V1beta::CacheService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCachedContentsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest'];

coerce 'ListCachedContentsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest'->new($_) };

declare 'RepeatedListCachedContentsRequest',
    as ArrayRef[ListCachedContentsRequest()];

coerce 'RepeatedListCachedContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest'->new($_) } @$_ ] };

declare 'MapStringListCachedContentsRequest',
    as HashRef[ListCachedContentsRequest()];

declare 'ListCachedContentsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse'];

coerce 'ListCachedContentsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse'->new($_) };

declare 'RepeatedListCachedContentsResponse',
    as ArrayRef[ListCachedContentsResponse()];

coerce 'RepeatedListCachedContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse'->new($_) } @$_ ] };

declare 'MapStringListCachedContentsResponse',
    as HashRef[ListCachedContentsResponse()];

declare 'CreateCachedContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest'];

coerce 'CreateCachedContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest'->new($_) };

declare 'RepeatedCreateCachedContentRequest',
    as ArrayRef[CreateCachedContentRequest()];

coerce 'RepeatedCreateCachedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCachedContentRequest',
    as HashRef[CreateCachedContentRequest()];

declare 'GetCachedContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest'];

coerce 'GetCachedContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest'->new($_) };

declare 'RepeatedGetCachedContentRequest',
    as ArrayRef[GetCachedContentRequest()];

coerce 'RepeatedGetCachedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest'->new($_) } @$_ ] };

declare 'MapStringGetCachedContentRequest',
    as HashRef[GetCachedContentRequest()];

declare 'UpdateCachedContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest'];

coerce 'UpdateCachedContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest'->new($_) };

declare 'RepeatedUpdateCachedContentRequest',
    as ArrayRef[UpdateCachedContentRequest()];

coerce 'RepeatedUpdateCachedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCachedContentRequest',
    as HashRef[UpdateCachedContentRequest()];

declare 'DeleteCachedContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest'];

coerce 'DeleteCachedContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest'->new($_) };

declare 'RepeatedDeleteCachedContentRequest',
    as ArrayRef[DeleteCachedContentRequest()];

coerce 'RepeatedDeleteCachedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCachedContentRequest',
    as HashRef[DeleteCachedContentRequest()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
