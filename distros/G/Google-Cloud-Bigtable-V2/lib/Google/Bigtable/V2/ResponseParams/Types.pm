package Google::Bigtable::V2::ResponseParams::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResponseParams',
    as InstanceOf['Google::Bigtable::V2::ResponseParams::ResponseParams'];

coerce 'ResponseParams',
    from HashRef, via { 'Google::Bigtable::V2::ResponseParams::ResponseParams'->new($_) };

declare 'RepeatedResponseParams',
    as ArrayRef[ResponseParams()];

coerce 'RepeatedResponseParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::ResponseParams::ResponseParams'->new($_) } @$_ ] };

declare 'MapStringResponseParams',
    as HashRef[ResponseParams()];

1;

__END__

=head1 NAME

Google::Bigtable::V2::ResponseParams::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
