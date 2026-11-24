package Google::Cloud::Oracledatabase::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComputeModel',
    as (Int | Str);

declare 'CustomerContact',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Common::CustomerContact'];

coerce 'CustomerContact',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Common::CustomerContact'->new($_) };

declare 'RepeatedCustomerContact',
    as ArrayRef[CustomerContact()];

coerce 'RepeatedCustomerContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Common::CustomerContact'->new($_) } @$_ ] };

declare 'MapStringCustomerContact',
    as HashRef[CustomerContact()];

declare 'IdentityConnector',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Common::IdentityConnector'];

coerce 'IdentityConnector',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Common::IdentityConnector'->new($_) };

declare 'RepeatedIdentityConnector',
    as ArrayRef[IdentityConnector()];

coerce 'RepeatedIdentityConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Common::IdentityConnector'->new($_) } @$_ ] };

declare 'MapStringIdentityConnector',
    as HashRef[IdentityConnector()];

declare 'ConnectionState',
    as (Int | Str);

declare 'DataCollectionOptionsCommon',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Common::DataCollectionOptionsCommon'];

coerce 'DataCollectionOptionsCommon',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Common::DataCollectionOptionsCommon'->new($_) };

declare 'RepeatedDataCollectionOptionsCommon',
    as ArrayRef[DataCollectionOptionsCommon()];

coerce 'RepeatedDataCollectionOptionsCommon',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Common::DataCollectionOptionsCommon'->new($_) } @$_ ] };

declare 'MapStringDataCollectionOptionsCommon',
    as HashRef[DataCollectionOptionsCommon()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
