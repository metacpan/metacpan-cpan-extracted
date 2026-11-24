package Google::Cloud::Run::V2::Revision::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetRevisionRequest',
    as InstanceOf['Google::Cloud::Run::V2::Revision::GetRevisionRequest'];

coerce 'GetRevisionRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::GetRevisionRequest'->new($_) };

declare 'RepeatedGetRevisionRequest',
    as ArrayRef[GetRevisionRequest()];

coerce 'RepeatedGetRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::GetRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetRevisionRequest',
    as HashRef[GetRevisionRequest()];

declare 'ListRevisionsRequest',
    as InstanceOf['Google::Cloud::Run::V2::Revision::ListRevisionsRequest'];

coerce 'ListRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::ListRevisionsRequest'->new($_) };

declare 'RepeatedListRevisionsRequest',
    as ArrayRef[ListRevisionsRequest()];

coerce 'RepeatedListRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::ListRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListRevisionsRequest',
    as HashRef[ListRevisionsRequest()];

declare 'ListRevisionsResponse',
    as InstanceOf['Google::Cloud::Run::V2::Revision::ListRevisionsResponse'];

coerce 'ListRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::ListRevisionsResponse'->new($_) };

declare 'RepeatedListRevisionsResponse',
    as ArrayRef[ListRevisionsResponse()];

coerce 'RepeatedListRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::ListRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListRevisionsResponse',
    as HashRef[ListRevisionsResponse()];

declare 'DeleteRevisionRequest',
    as InstanceOf['Google::Cloud::Run::V2::Revision::DeleteRevisionRequest'];

coerce 'DeleteRevisionRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::DeleteRevisionRequest'->new($_) };

declare 'RepeatedDeleteRevisionRequest',
    as ArrayRef[DeleteRevisionRequest()];

coerce 'RepeatedDeleteRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::DeleteRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRevisionRequest',
    as HashRef[DeleteRevisionRequest()];

declare 'Revision',
    as InstanceOf['Google::Cloud::Run::V2::Revision::Revision'];

coerce 'Revision',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::Revision'->new($_) };

declare 'RepeatedRevision',
    as ArrayRef[Revision()];

coerce 'RepeatedRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::Revision'->new($_) } @$_ ] };

declare 'MapStringRevision',
    as HashRef[Revision()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Revision::Revision::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::Revision::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::Revision::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Revision::Revision::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Revision::Revision::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Revision::Revision::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Revision::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
