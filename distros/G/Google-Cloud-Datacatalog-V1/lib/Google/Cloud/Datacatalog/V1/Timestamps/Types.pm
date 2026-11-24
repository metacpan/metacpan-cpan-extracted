package Google::Cloud::Datacatalog::V1::Timestamps::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SystemTimestamps',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps'];

coerce 'SystemTimestamps',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps'->new($_) };

declare 'RepeatedSystemTimestamps',
    as ArrayRef[SystemTimestamps()];

coerce 'RepeatedSystemTimestamps',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Timestamps::SystemTimestamps'->new($_) } @$_ ] };

declare 'MapStringSystemTimestamps',
    as HashRef[SystemTimestamps()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Timestamps::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
