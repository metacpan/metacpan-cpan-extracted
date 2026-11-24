package Google::Actions::Sdk::V2::LocalizedSettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LocalizedSettings',
    as InstanceOf['Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings'];

coerce 'LocalizedSettings',
    from HashRef, via { 'Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings'->new($_) };

declare 'RepeatedLocalizedSettings',
    as ArrayRef[LocalizedSettings()];

coerce 'RepeatedLocalizedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::LocalizedSettings::LocalizedSettings'->new($_) } @$_ ] };

declare 'MapStringLocalizedSettings',
    as HashRef[LocalizedSettings()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::LocalizedSettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
