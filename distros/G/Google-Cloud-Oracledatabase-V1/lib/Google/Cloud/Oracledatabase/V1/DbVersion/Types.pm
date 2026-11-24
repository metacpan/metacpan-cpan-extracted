package Google::Cloud::Oracledatabase::V1::DbVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbVersion',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion'];

coerce 'DbVersion',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion'->new($_) };

declare 'RepeatedDbVersion',
    as ArrayRef[DbVersion()];

coerce 'RepeatedDbVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbVersion::DbVersion'->new($_) } @$_ ] };

declare 'MapStringDbVersion',
    as HashRef[DbVersion()];

declare 'DbVersionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbVersion::DbVersionProperties'];

coerce 'DbVersionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbVersion::DbVersionProperties'->new($_) };

declare 'RepeatedDbVersionProperties',
    as ArrayRef[DbVersionProperties()];

coerce 'RepeatedDbVersionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbVersion::DbVersionProperties'->new($_) } @$_ ] };

declare 'MapStringDbVersionProperties',
    as HashRef[DbVersionProperties()];

declare 'ListDbVersionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsRequest'];

coerce 'ListDbVersionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsRequest'->new($_) };

declare 'RepeatedListDbVersionsRequest',
    as ArrayRef[ListDbVersionsRequest()];

coerce 'RepeatedListDbVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDbVersionsRequest',
    as HashRef[ListDbVersionsRequest()];

declare 'ListDbVersionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsResponse'];

coerce 'ListDbVersionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsResponse'->new($_) };

declare 'RepeatedListDbVersionsResponse',
    as ArrayRef[ListDbVersionsResponse()];

coerce 'RepeatedListDbVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbVersion::ListDbVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDbVersionsResponse',
    as HashRef[ListDbVersionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
