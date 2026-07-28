package Google::Ai::Generativelanguage::V1::Model::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Model',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Model::Model'];

coerce 'Model',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Model::Model'->new($_) };

declare 'RepeatedModel',
    as ArrayRef[Model()];

coerce 'RepeatedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Model::Model'->new($_) } @$_ ] };

declare 'MapStringModel',
    as HashRef[Model()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1::Model::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
