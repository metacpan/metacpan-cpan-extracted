package Google::Appengine::V1::Operation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadataV1',
    as InstanceOf['Google::Appengine::V1::Operation::OperationMetadataV1'];

coerce 'OperationMetadataV1',
    from HashRef, via { 'Google::Appengine::V1::Operation::OperationMetadataV1'->new($_) };

declare 'RepeatedOperationMetadataV1',
    as ArrayRef[OperationMetadataV1()];

coerce 'RepeatedOperationMetadataV1',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Operation::OperationMetadataV1'->new($_) } @$_ ] };

declare 'MapStringOperationMetadataV1',
    as HashRef[OperationMetadataV1()];

declare 'CreateVersionMetadataV1',
    as InstanceOf['Google::Appengine::V1::Operation::CreateVersionMetadataV1'];

coerce 'CreateVersionMetadataV1',
    from HashRef, via { 'Google::Appengine::V1::Operation::CreateVersionMetadataV1'->new($_) };

declare 'RepeatedCreateVersionMetadataV1',
    as ArrayRef[CreateVersionMetadataV1()];

coerce 'RepeatedCreateVersionMetadataV1',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Operation::CreateVersionMetadataV1'->new($_) } @$_ ] };

declare 'MapStringCreateVersionMetadataV1',
    as HashRef[CreateVersionMetadataV1()];

1;

__END__

=head1 NAME

Google::Appengine::V1::Operation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
