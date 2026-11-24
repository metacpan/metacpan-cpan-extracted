package Google::Cloud::Oracledatabase::V1::MinorVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MinorVersion',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion'];

coerce 'MinorVersion',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion'->new($_) };

declare 'RepeatedMinorVersion',
    as ArrayRef[MinorVersion()];

coerce 'RepeatedMinorVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::MinorVersion::MinorVersion'->new($_) } @$_ ] };

declare 'MapStringMinorVersion',
    as HashRef[MinorVersion()];

declare 'ListMinorVersionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsRequest'];

coerce 'ListMinorVersionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsRequest'->new($_) };

declare 'RepeatedListMinorVersionsRequest',
    as ArrayRef[ListMinorVersionsRequest()];

coerce 'RepeatedListMinorVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListMinorVersionsRequest',
    as HashRef[ListMinorVersionsRequest()];

declare 'ListMinorVersionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsResponse'];

coerce 'ListMinorVersionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsResponse'->new($_) };

declare 'RepeatedListMinorVersionsResponse',
    as ArrayRef[ListMinorVersionsResponse()];

coerce 'RepeatedListMinorVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::MinorVersion::ListMinorVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListMinorVersionsResponse',
    as HashRef[ListMinorVersionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::MinorVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
