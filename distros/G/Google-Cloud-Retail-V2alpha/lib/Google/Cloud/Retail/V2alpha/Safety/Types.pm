package Google::Cloud::Retail::V2alpha::Safety::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HarmCategory',
    as (Int | Str);

declare 'SafetySetting',
    as InstanceOf['Google::Cloud::Retail::V2alpha::Safety::SafetySetting'];

coerce 'SafetySetting',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::Safety::SafetySetting'->new($_) };

declare 'RepeatedSafetySetting',
    as ArrayRef[SafetySetting()];

coerce 'RepeatedSafetySetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::Safety::SafetySetting'->new($_) } @$_ ] };

declare 'MapStringSafetySetting',
    as HashRef[SafetySetting()];

declare 'HarmBlockThreshold',
    as (Int | Str);

declare 'HarmBlockMethod',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::Safety::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
