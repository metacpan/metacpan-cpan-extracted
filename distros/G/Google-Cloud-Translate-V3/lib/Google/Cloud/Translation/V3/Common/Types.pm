package Google::Cloud::Translation::V3::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationState',
    as (Int | Str);

declare 'GcsInputSource',
    as InstanceOf['Google::Cloud::Translation::V3::Common::GcsInputSource'];

coerce 'GcsInputSource',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::GcsInputSource'->new($_) };

declare 'RepeatedGcsInputSource',
    as ArrayRef[GcsInputSource()];

coerce 'RepeatedGcsInputSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::GcsInputSource'->new($_) } @$_ ] };

declare 'MapStringGcsInputSource',
    as HashRef[GcsInputSource()];

declare 'FileInputSource',
    as InstanceOf['Google::Cloud::Translation::V3::Common::FileInputSource'];

coerce 'FileInputSource',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::FileInputSource'->new($_) };

declare 'RepeatedFileInputSource',
    as ArrayRef[FileInputSource()];

coerce 'RepeatedFileInputSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::FileInputSource'->new($_) } @$_ ] };

declare 'MapStringFileInputSource',
    as HashRef[FileInputSource()];

declare 'GcsOutputDestination',
    as InstanceOf['Google::Cloud::Translation::V3::Common::GcsOutputDestination'];

coerce 'GcsOutputDestination',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::GcsOutputDestination'->new($_) };

declare 'RepeatedGcsOutputDestination',
    as ArrayRef[GcsOutputDestination()];

coerce 'RepeatedGcsOutputDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::GcsOutputDestination'->new($_) } @$_ ] };

declare 'MapStringGcsOutputDestination',
    as HashRef[GcsOutputDestination()];

declare 'GlossaryEntry',
    as InstanceOf['Google::Cloud::Translation::V3::Common::GlossaryEntry'];

coerce 'GlossaryEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::GlossaryEntry'->new($_) };

declare 'RepeatedGlossaryEntry',
    as ArrayRef[GlossaryEntry()];

coerce 'RepeatedGlossaryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::GlossaryEntry'->new($_) } @$_ ] };

declare 'MapStringGlossaryEntry',
    as HashRef[GlossaryEntry()];

declare 'GlossaryTermsPair',
    as InstanceOf['Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsPair'];

coerce 'GlossaryTermsPair',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsPair'->new($_) };

declare 'RepeatedGlossaryTermsPair',
    as ArrayRef[GlossaryTermsPair()];

coerce 'RepeatedGlossaryTermsPair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsPair'->new($_) } @$_ ] };

declare 'MapStringGlossaryTermsPair',
    as HashRef[GlossaryTermsPair()];

declare 'GlossaryTermsSet',
    as InstanceOf['Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsSet'];

coerce 'GlossaryTermsSet',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsSet'->new($_) };

declare 'RepeatedGlossaryTermsSet',
    as ArrayRef[GlossaryTermsSet()];

coerce 'RepeatedGlossaryTermsSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::GlossaryEntry::GlossaryTermsSet'->new($_) } @$_ ] };

declare 'MapStringGlossaryTermsSet',
    as HashRef[GlossaryTermsSet()];

declare 'GlossaryTerm',
    as InstanceOf['Google::Cloud::Translation::V3::Common::GlossaryTerm'];

coerce 'GlossaryTerm',
    from HashRef, via { 'Google::Cloud::Translation::V3::Common::GlossaryTerm'->new($_) };

declare 'RepeatedGlossaryTerm',
    as ArrayRef[GlossaryTerm()];

coerce 'RepeatedGlossaryTerm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::Common::GlossaryTerm'->new($_) } @$_ ] };

declare 'MapStringGlossaryTerm',
    as HashRef[GlossaryTerm()];

1;

__END__

=head1 NAME

Google::Cloud::Translation::V3::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
