package Google::Cloud::Netapp::V1::Ontap::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecuteOntapPostRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest'];

coerce 'ExecuteOntapPostRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest'->new($_) };

declare 'RepeatedExecuteOntapPostRequest',
    as ArrayRef[ExecuteOntapPostRequest()];

coerce 'RepeatedExecuteOntapPostRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapPostRequest',
    as HashRef[ExecuteOntapPostRequest()];

declare 'ExecuteOntapPostResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostResponse'];

coerce 'ExecuteOntapPostResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostResponse'->new($_) };

declare 'RepeatedExecuteOntapPostResponse',
    as ArrayRef[ExecuteOntapPostResponse()];

coerce 'RepeatedExecuteOntapPostResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPostResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapPostResponse',
    as HashRef[ExecuteOntapPostResponse()];

declare 'ExecuteOntapGetRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetRequest'];

coerce 'ExecuteOntapGetRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetRequest'->new($_) };

declare 'RepeatedExecuteOntapGetRequest',
    as ArrayRef[ExecuteOntapGetRequest()];

coerce 'RepeatedExecuteOntapGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapGetRequest',
    as HashRef[ExecuteOntapGetRequest()];

declare 'ExecuteOntapGetResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetResponse'];

coerce 'ExecuteOntapGetResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetResponse'->new($_) };

declare 'RepeatedExecuteOntapGetResponse',
    as ArrayRef[ExecuteOntapGetResponse()];

coerce 'RepeatedExecuteOntapGetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapGetResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapGetResponse',
    as HashRef[ExecuteOntapGetResponse()];

declare 'ExecuteOntapDeleteRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteRequest'];

coerce 'ExecuteOntapDeleteRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteRequest'->new($_) };

declare 'RepeatedExecuteOntapDeleteRequest',
    as ArrayRef[ExecuteOntapDeleteRequest()];

coerce 'RepeatedExecuteOntapDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapDeleteRequest',
    as HashRef[ExecuteOntapDeleteRequest()];

declare 'ExecuteOntapDeleteResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteResponse'];

coerce 'ExecuteOntapDeleteResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteResponse'->new($_) };

declare 'RepeatedExecuteOntapDeleteResponse',
    as ArrayRef[ExecuteOntapDeleteResponse()];

coerce 'RepeatedExecuteOntapDeleteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapDeleteResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapDeleteResponse',
    as HashRef[ExecuteOntapDeleteResponse()];

declare 'ExecuteOntapPatchRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchRequest'];

coerce 'ExecuteOntapPatchRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchRequest'->new($_) };

declare 'RepeatedExecuteOntapPatchRequest',
    as ArrayRef[ExecuteOntapPatchRequest()];

coerce 'RepeatedExecuteOntapPatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapPatchRequest',
    as HashRef[ExecuteOntapPatchRequest()];

declare 'ExecuteOntapPatchResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchResponse'];

coerce 'ExecuteOntapPatchResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchResponse'->new($_) };

declare 'RepeatedExecuteOntapPatchResponse',
    as ArrayRef[ExecuteOntapPatchResponse()];

coerce 'RepeatedExecuteOntapPatchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Ontap::ExecuteOntapPatchResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteOntapPatchResponse',
    as HashRef[ExecuteOntapPatchResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Ontap::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
