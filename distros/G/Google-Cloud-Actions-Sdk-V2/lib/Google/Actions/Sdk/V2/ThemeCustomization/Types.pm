package Google::Actions::Sdk::V2::ThemeCustomization::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ThemeCustomization',
    as InstanceOf['Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization'];

coerce 'ThemeCustomization',
    from HashRef, via { 'Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization'->new($_) };

declare 'RepeatedThemeCustomization',
    as ArrayRef[ThemeCustomization()];

coerce 'RepeatedThemeCustomization',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization'->new($_) } @$_ ] };

declare 'MapStringThemeCustomization',
    as HashRef[ThemeCustomization()];

declare 'ImageCornerStyle',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::ThemeCustomization::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
