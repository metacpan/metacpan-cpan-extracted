package Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UrlFilteringProfile',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilteringProfile'];

coerce 'UrlFilteringProfile',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilteringProfile'->new($_) };

declare 'RepeatedUrlFilteringProfile',
    as ArrayRef[UrlFilteringProfile()];

coerce 'RepeatedUrlFilteringProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilteringProfile'->new($_) } @$_ ] };

declare 'MapStringUrlFilteringProfile',
    as HashRef[UrlFilteringProfile()];

declare 'UrlFilter',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilter'];

coerce 'UrlFilter',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilter'->new($_) };

declare 'RepeatedUrlFilter',
    as ArrayRef[UrlFilter()];

coerce 'RepeatedUrlFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::UrlFilter'->new($_) } @$_ ] };

declare 'MapStringUrlFilter',
    as HashRef[UrlFilter()];

declare 'UrlFilteringAction',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
