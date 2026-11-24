package Google::Actions::Sdk::V2::Settings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Settings',
    as InstanceOf['Google::Actions::Sdk::V2::Settings::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Actions::Sdk::V2::Settings::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Settings::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'Category',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Settings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
