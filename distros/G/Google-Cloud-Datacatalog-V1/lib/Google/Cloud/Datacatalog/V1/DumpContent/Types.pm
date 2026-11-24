package Google::Cloud::Datacatalog::V1::DumpContent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TaggedEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry'];

coerce 'TaggedEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry'->new($_) };

declare 'RepeatedTaggedEntry',
    as ArrayRef[TaggedEntry()];

coerce 'RepeatedTaggedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DumpContent::TaggedEntry'->new($_) } @$_ ] };

declare 'MapStringTaggedEntry',
    as HashRef[TaggedEntry()];

declare 'DumpItem',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DumpContent::DumpItem'];

coerce 'DumpItem',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DumpContent::DumpItem'->new($_) };

declare 'RepeatedDumpItem',
    as ArrayRef[DumpItem()];

coerce 'RepeatedDumpItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DumpContent::DumpItem'->new($_) } @$_ ] };

declare 'MapStringDumpItem',
    as HashRef[DumpItem()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::DumpContent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
