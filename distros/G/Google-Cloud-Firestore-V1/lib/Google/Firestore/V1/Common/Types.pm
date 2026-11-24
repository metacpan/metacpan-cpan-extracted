package Google::Firestore::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocumentMask',
    as InstanceOf['Google::Firestore::V1::Common::DocumentMask'];

coerce 'DocumentMask',
    from HashRef, via { 'Google::Firestore::V1::Common::DocumentMask'->new($_) };

declare 'RepeatedDocumentMask',
    as ArrayRef[DocumentMask()];

coerce 'RepeatedDocumentMask',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Common::DocumentMask'->new($_) } @$_ ] };

declare 'MapStringDocumentMask',
    as HashRef[DocumentMask()];

declare 'Precondition',
    as InstanceOf['Google::Firestore::V1::Common::Precondition'];

coerce 'Precondition',
    from HashRef, via { 'Google::Firestore::V1::Common::Precondition'->new($_) };

declare 'RepeatedPrecondition',
    as ArrayRef[Precondition()];

coerce 'RepeatedPrecondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Common::Precondition'->new($_) } @$_ ] };

declare 'MapStringPrecondition',
    as HashRef[Precondition()];

declare 'TransactionOptions',
    as InstanceOf['Google::Firestore::V1::Common::TransactionOptions'];

coerce 'TransactionOptions',
    from HashRef, via { 'Google::Firestore::V1::Common::TransactionOptions'->new($_) };

declare 'RepeatedTransactionOptions',
    as ArrayRef[TransactionOptions()];

coerce 'RepeatedTransactionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Common::TransactionOptions'->new($_) } @$_ ] };

declare 'MapStringTransactionOptions',
    as HashRef[TransactionOptions()];

declare 'ConcurrencyMode',
    as (Int | Str);

declare 'ReadWrite',
    as InstanceOf['Google::Firestore::V1::Common::TransactionOptions::ReadWrite'];

coerce 'ReadWrite',
    from HashRef, via { 'Google::Firestore::V1::Common::TransactionOptions::ReadWrite'->new($_) };

declare 'RepeatedReadWrite',
    as ArrayRef[ReadWrite()];

coerce 'RepeatedReadWrite',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Common::TransactionOptions::ReadWrite'->new($_) } @$_ ] };

declare 'MapStringReadWrite',
    as HashRef[ReadWrite()];

declare 'ReadOnly',
    as InstanceOf['Google::Firestore::V1::Common::TransactionOptions::ReadOnly'];

coerce 'ReadOnly',
    from HashRef, via { 'Google::Firestore::V1::Common::TransactionOptions::ReadOnly'->new($_) };

declare 'RepeatedReadOnly',
    as ArrayRef[ReadOnly()];

coerce 'RepeatedReadOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Common::TransactionOptions::ReadOnly'->new($_) } @$_ ] };

declare 'MapStringReadOnly',
    as HashRef[ReadOnly()];

declare 'RequestOptions',
    as InstanceOf['Google::Firestore::V1::Common::RequestOptions'];

coerce 'RequestOptions',
    from HashRef, via { 'Google::Firestore::V1::Common::RequestOptions'->new($_) };

declare 'RepeatedRequestOptions',
    as ArrayRef[RequestOptions()];

coerce 'RepeatedRequestOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Common::RequestOptions'->new($_) } @$_ ] };

declare 'MapStringRequestOptions',
    as HashRef[RequestOptions()];

1;

__END__

=head1 NAME

Google::Firestore::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
