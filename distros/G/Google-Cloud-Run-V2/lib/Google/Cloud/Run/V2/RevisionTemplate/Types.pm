package Google::Cloud::Run::V2::RevisionTemplate::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RevisionTemplate',
    as InstanceOf['Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate'];

coerce 'RevisionTemplate',
    from HashRef, via { 'Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate'->new($_) };

declare 'RepeatedRevisionTemplate',
    as ArrayRef[RevisionTemplate()];

coerce 'RepeatedRevisionTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate'->new($_) } @$_ ] };

declare 'MapStringRevisionTemplate',
    as HashRef[RevisionTemplate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::RevisionTemplate::RevisionTemplate::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::RevisionTemplate::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
