package Google::Devtools::Resultstore::V2::UploadMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UploadMetadata',
    as InstanceOf['Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata'];

coerce 'UploadMetadata',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata'->new($_) };

declare 'RepeatedUploadMetadata',
    as ArrayRef[UploadMetadata()];

coerce 'RepeatedUploadMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::UploadMetadata::UploadMetadata'->new($_) } @$_ ] };

declare 'MapStringUploadMetadata',
    as HashRef[UploadMetadata()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::UploadMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
