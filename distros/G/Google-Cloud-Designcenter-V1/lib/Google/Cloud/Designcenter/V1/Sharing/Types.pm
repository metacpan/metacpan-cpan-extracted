package Google::Cloud::Designcenter::V1::Sharing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Share',
    as InstanceOf['Google::Cloud::Designcenter::V1::Sharing::Share'];

coerce 'Share',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Sharing::Share'->new($_) };

declare 'RepeatedShare',
    as ArrayRef[Share()];

coerce 'RepeatedShare',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Sharing::Share'->new($_) } @$_ ] };

declare 'MapStringShare',
    as HashRef[Share()];

declare 'State',
    as (Int | Str);

declare 'SharedTemplate',
    as InstanceOf['Google::Cloud::Designcenter::V1::Sharing::SharedTemplate'];

coerce 'SharedTemplate',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Sharing::SharedTemplate'->new($_) };

declare 'RepeatedSharedTemplate',
    as ArrayRef[SharedTemplate()];

coerce 'RepeatedSharedTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Sharing::SharedTemplate'->new($_) } @$_ ] };

declare 'MapStringSharedTemplate',
    as HashRef[SharedTemplate()];

declare 'SharedTemplateRevision',
    as InstanceOf['Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision'];

coerce 'SharedTemplateRevision',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision'->new($_) };

declare 'RepeatedSharedTemplateRevision',
    as ArrayRef[SharedTemplateRevision()];

coerce 'RepeatedSharedTemplateRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision'->new($_) } @$_ ] };

declare 'MapStringSharedTemplateRevision',
    as HashRef[SharedTemplateRevision()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Sharing::SharedTemplateRevision::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Sharing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
