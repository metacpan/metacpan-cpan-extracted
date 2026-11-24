package Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Type',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type'];

coerce 'Type',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type'->new($_) };

declare 'RepeatedType',
    as ArrayRef[Type()];

coerce 'RepeatedType',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type'->new($_) } @$_ ] };

declare 'MapStringType',
    as HashRef[Type()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
