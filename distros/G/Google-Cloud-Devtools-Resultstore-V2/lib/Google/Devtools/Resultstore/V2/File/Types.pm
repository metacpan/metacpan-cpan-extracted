package Google::Devtools::Resultstore::V2::File::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'File',
    as InstanceOf['Google::Devtools::Resultstore::V2::File::File'];

coerce 'File',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::File::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::File::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'HashType',
    as (Int | Str);

declare 'ArchiveEntry',
    as InstanceOf['Google::Devtools::Resultstore::V2::File::ArchiveEntry'];

coerce 'ArchiveEntry',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::File::ArchiveEntry'->new($_) };

declare 'RepeatedArchiveEntry',
    as ArrayRef[ArchiveEntry()];

coerce 'RepeatedArchiveEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::File::ArchiveEntry'->new($_) } @$_ ] };

declare 'MapStringArchiveEntry',
    as HashRef[ArchiveEntry()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::File::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
