package Google::Cloud::Retail::V2beta::UserEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserEvent',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEvent::UserEvent'];

coerce 'UserEvent',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent'->new($_) };

declare 'RepeatedUserEvent',
    as ArrayRef[UserEvent()];

coerce 'RepeatedUserEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent'->new($_) } @$_ ] };

declare 'MapStringUserEvent',
    as HashRef[UserEvent()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEvent::UserEvent::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'ProductDetail',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEvent::ProductDetail'];

coerce 'ProductDetail',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEvent::ProductDetail'->new($_) };

declare 'RepeatedProductDetail',
    as ArrayRef[ProductDetail()];

coerce 'RepeatedProductDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEvent::ProductDetail'->new($_) } @$_ ] };

declare 'MapStringProductDetail',
    as HashRef[ProductDetail()];

declare 'CompletionDetail',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEvent::CompletionDetail'];

coerce 'CompletionDetail',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEvent::CompletionDetail'->new($_) };

declare 'RepeatedCompletionDetail',
    as ArrayRef[CompletionDetail()];

coerce 'RepeatedCompletionDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEvent::CompletionDetail'->new($_) } @$_ ] };

declare 'MapStringCompletionDetail',
    as HashRef[CompletionDetail()];

declare 'PurchaseTransaction',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEvent::PurchaseTransaction'];

coerce 'PurchaseTransaction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEvent::PurchaseTransaction'->new($_) };

declare 'RepeatedPurchaseTransaction',
    as ArrayRef[PurchaseTransaction()];

coerce 'RepeatedPurchaseTransaction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEvent::PurchaseTransaction'->new($_) } @$_ ] };

declare 'MapStringPurchaseTransaction',
    as HashRef[PurchaseTransaction()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::UserEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
