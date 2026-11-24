package Google::Cloud::Video::Stitcher::V1::FetchOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FetchOptions',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions'];

coerce 'FetchOptions',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions'->new($_) };

declare 'RepeatedFetchOptions',
    as ArrayRef[FetchOptions()];

coerce 'RepeatedFetchOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions'->new($_) } @$_ ] };

declare 'MapStringFetchOptions',
    as HashRef[FetchOptions()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Stitcher::V1::FetchOptions::FetchOptions::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Stitcher::V1::FetchOptions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
