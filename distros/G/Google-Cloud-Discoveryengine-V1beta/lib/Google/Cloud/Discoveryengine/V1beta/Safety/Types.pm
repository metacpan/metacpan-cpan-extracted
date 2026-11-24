package Google::Cloud::Discoveryengine::V1beta::Safety::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HarmCategory',
    as (Int | Str);

declare 'SafetyRating',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating'];

coerce 'SafetyRating',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating'->new($_) };

declare 'RepeatedSafetyRating',
    as ArrayRef[SafetyRating()];

coerce 'RepeatedSafetyRating',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Safety::SafetyRating'->new($_) } @$_ ] };

declare 'MapStringSafetyRating',
    as HashRef[SafetyRating()];

declare 'HarmProbability',
    as (Int | Str);

declare 'HarmSeverity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Safety::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
