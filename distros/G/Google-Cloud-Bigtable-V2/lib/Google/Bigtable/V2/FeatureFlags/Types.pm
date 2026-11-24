package Google::Bigtable::V2::FeatureFlags::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FeatureFlags',
    as InstanceOf['Google::Bigtable::V2::FeatureFlags::FeatureFlags'];

coerce 'FeatureFlags',
    from HashRef, via { 'Google::Bigtable::V2::FeatureFlags::FeatureFlags'->new($_) };

declare 'RepeatedFeatureFlags',
    as ArrayRef[FeatureFlags()];

coerce 'RepeatedFeatureFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::FeatureFlags::FeatureFlags'->new($_) } @$_ ] };

declare 'MapStringFeatureFlags',
    as HashRef[FeatureFlags()];

1;

__END__

=head1 NAME

Google::Bigtable::V2::FeatureFlags::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
