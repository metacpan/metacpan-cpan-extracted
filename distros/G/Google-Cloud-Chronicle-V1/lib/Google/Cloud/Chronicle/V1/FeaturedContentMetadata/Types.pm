package Google::Cloud::Chronicle::V1::FeaturedContentMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FeaturedContentMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata'];

coerce 'FeaturedContentMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata'->new($_) };

declare 'RepeatedFeaturedContentMetadata',
    as ArrayRef[FeaturedContentMetadata()];

coerce 'RepeatedFeaturedContentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FeaturedContentMetadata::FeaturedContentMetadata'->new($_) } @$_ ] };

declare 'MapStringFeaturedContentMetadata',
    as HashRef[FeaturedContentMetadata()];

declare 'ContentSourceType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::FeaturedContentMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
