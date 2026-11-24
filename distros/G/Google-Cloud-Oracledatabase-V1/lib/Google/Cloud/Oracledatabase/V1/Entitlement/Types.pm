package Google::Cloud::Oracledatabase::V1::Entitlement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Entitlement',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement'];

coerce 'Entitlement',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement'->new($_) };

declare 'RepeatedEntitlement',
    as ArrayRef[Entitlement()];

coerce 'RepeatedEntitlement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Entitlement::Entitlement'->new($_) } @$_ ] };

declare 'MapStringEntitlement',
    as HashRef[Entitlement()];

declare 'State',
    as (Int | Str);

declare 'CloudAccountDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Entitlement::CloudAccountDetails'];

coerce 'CloudAccountDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Entitlement::CloudAccountDetails'->new($_) };

declare 'RepeatedCloudAccountDetails',
    as ArrayRef[CloudAccountDetails()];

coerce 'RepeatedCloudAccountDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Entitlement::CloudAccountDetails'->new($_) } @$_ ] };

declare 'MapStringCloudAccountDetails',
    as HashRef[CloudAccountDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::Entitlement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
