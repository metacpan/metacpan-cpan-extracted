package Google::Appengine::V1beta::Operation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadataV1Beta',
    as InstanceOf['Google::Appengine::V1beta::Operation::OperationMetadataV1Beta'];

coerce 'OperationMetadataV1Beta',
    from HashRef, via { 'Google::Appengine::V1beta::Operation::OperationMetadataV1Beta'->new($_) };

declare 'RepeatedOperationMetadataV1Beta',
    as ArrayRef[OperationMetadataV1Beta()];

coerce 'RepeatedOperationMetadataV1Beta',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Operation::OperationMetadataV1Beta'->new($_) } @$_ ] };

declare 'MapStringOperationMetadataV1Beta',
    as HashRef[OperationMetadataV1Beta()];

declare 'CreateVersionMetadataV1Beta',
    as InstanceOf['Google::Appengine::V1beta::Operation::CreateVersionMetadataV1Beta'];

coerce 'CreateVersionMetadataV1Beta',
    from HashRef, via { 'Google::Appengine::V1beta::Operation::CreateVersionMetadataV1Beta'->new($_) };

declare 'RepeatedCreateVersionMetadataV1Beta',
    as ArrayRef[CreateVersionMetadataV1Beta()];

coerce 'RepeatedCreateVersionMetadataV1Beta',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Operation::CreateVersionMetadataV1Beta'->new($_) } @$_ ] };

declare 'MapStringCreateVersionMetadataV1Beta',
    as HashRef[CreateVersionMetadataV1Beta()];

1;

__END__

=head1 NAME

Google::Appengine::V1beta::Operation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
