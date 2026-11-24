package Google::Devtools::Resultstore::V2::FileSet::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FileSet',
    as InstanceOf['Google::Devtools::Resultstore::V2::FileSet::FileSet'];

coerce 'FileSet',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::FileSet::FileSet'->new($_) };

declare 'RepeatedFileSet',
    as ArrayRef[FileSet()];

coerce 'RepeatedFileSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::FileSet::FileSet'->new($_) } @$_ ] };

declare 'MapStringFileSet',
    as HashRef[FileSet()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::FileSet::FileSet::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::FileSet::FileSet::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::FileSet::FileSet::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::FileSet::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
