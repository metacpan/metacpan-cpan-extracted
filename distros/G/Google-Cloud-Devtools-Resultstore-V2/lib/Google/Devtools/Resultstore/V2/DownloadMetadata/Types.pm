package Google::Devtools::Resultstore::V2::DownloadMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DownloadMetadata',
    as InstanceOf['Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata'];

coerce 'DownloadMetadata',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata'->new($_) };

declare 'RepeatedDownloadMetadata',
    as ArrayRef[DownloadMetadata()];

coerce 'RepeatedDownloadMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::DownloadMetadata::DownloadMetadata'->new($_) } @$_ ] };

declare 'MapStringDownloadMetadata',
    as HashRef[DownloadMetadata()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::DownloadMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
