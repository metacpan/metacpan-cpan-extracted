package Google::Cloud::Retail::V2::Promotion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Promotion',
    as InstanceOf['Google::Cloud::Retail::V2::Promotion::Promotion'];

coerce 'Promotion',
    from HashRef, via { 'Google::Cloud::Retail::V2::Promotion::Promotion'->new($_) };

declare 'RepeatedPromotion',
    as ArrayRef[Promotion()];

coerce 'RepeatedPromotion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::Promotion::Promotion'->new($_) } @$_ ] };

declare 'MapStringPromotion',
    as HashRef[Promotion()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2::Promotion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
