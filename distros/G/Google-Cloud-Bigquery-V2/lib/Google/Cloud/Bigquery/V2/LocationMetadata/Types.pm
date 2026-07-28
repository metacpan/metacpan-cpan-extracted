package Google::Cloud::Bigquery::V2::LocationMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::LocationMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
