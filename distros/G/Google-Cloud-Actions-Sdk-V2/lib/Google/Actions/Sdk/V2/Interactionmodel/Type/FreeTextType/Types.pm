package Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FreeTextType',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType'];

coerce 'FreeTextType',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType'->new($_) };

declare 'RepeatedFreeTextType',
    as ArrayRef[FreeTextType()];

coerce 'RepeatedFreeTextType',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::FreeTextType'->new($_) } @$_ ] };

declare 'MapStringFreeTextType',
    as HashRef[FreeTextType()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::FreeTextType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
