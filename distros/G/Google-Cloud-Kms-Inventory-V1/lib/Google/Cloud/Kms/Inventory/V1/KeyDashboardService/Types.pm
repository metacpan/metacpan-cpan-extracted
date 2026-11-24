package Google::Cloud::Kms::Inventory::V1::KeyDashboardService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCryptoKeysRequest',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest'];

coerce 'ListCryptoKeysRequest',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest'->new($_) };

declare 'RepeatedListCryptoKeysRequest',
    as ArrayRef[ListCryptoKeysRequest()];

coerce 'RepeatedListCryptoKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListCryptoKeysRequest',
    as HashRef[ListCryptoKeysRequest()];

declare 'ListCryptoKeysResponse',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysResponse'];

coerce 'ListCryptoKeysResponse',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysResponse'->new($_) };

declare 'RepeatedListCryptoKeysResponse',
    as ArrayRef[ListCryptoKeysResponse()];

coerce 'RepeatedListCryptoKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyDashboardService::ListCryptoKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListCryptoKeysResponse',
    as HashRef[ListCryptoKeysResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::Inventory::V1::KeyDashboardService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
