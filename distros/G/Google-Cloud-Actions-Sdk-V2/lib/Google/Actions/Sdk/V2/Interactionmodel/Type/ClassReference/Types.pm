package Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClassReference',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference'];

coerce 'ClassReference',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference'->new($_) };

declare 'RepeatedClassReference',
    as ArrayRef[ClassReference()];

coerce 'RepeatedClassReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference'->new($_) } @$_ ] };

declare 'MapStringClassReference',
    as HashRef[ClassReference()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
