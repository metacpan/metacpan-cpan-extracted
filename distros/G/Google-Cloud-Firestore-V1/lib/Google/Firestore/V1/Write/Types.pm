package Google::Firestore::V1::Write::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Write',
    as InstanceOf['Google::Firestore::V1::Write::Write'];

coerce 'Write',
    from HashRef, via { 'Google::Firestore::V1::Write::Write'->new($_) };

declare 'RepeatedWrite',
    as ArrayRef[Write()];

coerce 'RepeatedWrite',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::Write'->new($_) } @$_ ] };

declare 'MapStringWrite',
    as HashRef[Write()];

declare 'DocumentTransform',
    as InstanceOf['Google::Firestore::V1::Write::DocumentTransform'];

coerce 'DocumentTransform',
    from HashRef, via { 'Google::Firestore::V1::Write::DocumentTransform'->new($_) };

declare 'RepeatedDocumentTransform',
    as ArrayRef[DocumentTransform()];

coerce 'RepeatedDocumentTransform',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::DocumentTransform'->new($_) } @$_ ] };

declare 'MapStringDocumentTransform',
    as HashRef[DocumentTransform()];

declare 'FieldTransform',
    as InstanceOf['Google::Firestore::V1::Write::DocumentTransform::FieldTransform'];

coerce 'FieldTransform',
    from HashRef, via { 'Google::Firestore::V1::Write::DocumentTransform::FieldTransform'->new($_) };

declare 'RepeatedFieldTransform',
    as ArrayRef[FieldTransform()];

coerce 'RepeatedFieldTransform',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::DocumentTransform::FieldTransform'->new($_) } @$_ ] };

declare 'MapStringFieldTransform',
    as HashRef[FieldTransform()];

declare 'ServerValue',
    as (Int | Str);

declare 'WriteResult',
    as InstanceOf['Google::Firestore::V1::Write::WriteResult'];

coerce 'WriteResult',
    from HashRef, via { 'Google::Firestore::V1::Write::WriteResult'->new($_) };

declare 'RepeatedWriteResult',
    as ArrayRef[WriteResult()];

coerce 'RepeatedWriteResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::WriteResult'->new($_) } @$_ ] };

declare 'MapStringWriteResult',
    as HashRef[WriteResult()];

declare 'DocumentChange',
    as InstanceOf['Google::Firestore::V1::Write::DocumentChange'];

coerce 'DocumentChange',
    from HashRef, via { 'Google::Firestore::V1::Write::DocumentChange'->new($_) };

declare 'RepeatedDocumentChange',
    as ArrayRef[DocumentChange()];

coerce 'RepeatedDocumentChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::DocumentChange'->new($_) } @$_ ] };

declare 'MapStringDocumentChange',
    as HashRef[DocumentChange()];

declare 'DocumentDelete',
    as InstanceOf['Google::Firestore::V1::Write::DocumentDelete'];

coerce 'DocumentDelete',
    from HashRef, via { 'Google::Firestore::V1::Write::DocumentDelete'->new($_) };

declare 'RepeatedDocumentDelete',
    as ArrayRef[DocumentDelete()];

coerce 'RepeatedDocumentDelete',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::DocumentDelete'->new($_) } @$_ ] };

declare 'MapStringDocumentDelete',
    as HashRef[DocumentDelete()];

declare 'DocumentRemove',
    as InstanceOf['Google::Firestore::V1::Write::DocumentRemove'];

coerce 'DocumentRemove',
    from HashRef, via { 'Google::Firestore::V1::Write::DocumentRemove'->new($_) };

declare 'RepeatedDocumentRemove',
    as ArrayRef[DocumentRemove()];

coerce 'RepeatedDocumentRemove',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::DocumentRemove'->new($_) } @$_ ] };

declare 'MapStringDocumentRemove',
    as HashRef[DocumentRemove()];

declare 'ExistenceFilter',
    as InstanceOf['Google::Firestore::V1::Write::ExistenceFilter'];

coerce 'ExistenceFilter',
    from HashRef, via { 'Google::Firestore::V1::Write::ExistenceFilter'->new($_) };

declare 'RepeatedExistenceFilter',
    as ArrayRef[ExistenceFilter()];

coerce 'RepeatedExistenceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::Write::ExistenceFilter'->new($_) } @$_ ] };

declare 'MapStringExistenceFilter',
    as HashRef[ExistenceFilter()];

1;

__END__

=head1 NAME

Google::Firestore::V1::Write::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
