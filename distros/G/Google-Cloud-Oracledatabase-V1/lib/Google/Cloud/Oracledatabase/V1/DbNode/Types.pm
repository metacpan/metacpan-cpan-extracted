package Google::Cloud::Oracledatabase::V1::DbNode::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbNode',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbNode::DbNode'];

coerce 'DbNode',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbNode::DbNode'->new($_) };

declare 'RepeatedDbNode',
    as ArrayRef[DbNode()];

coerce 'RepeatedDbNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbNode::DbNode'->new($_) } @$_ ] };

declare 'MapStringDbNode',
    as HashRef[DbNode()];

declare 'DbNodeProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbNode::DbNodeProperties'];

coerce 'DbNodeProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbNode::DbNodeProperties'->new($_) };

declare 'RepeatedDbNodeProperties',
    as ArrayRef[DbNodeProperties()];

coerce 'RepeatedDbNodeProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbNode::DbNodeProperties'->new($_) } @$_ ] };

declare 'MapStringDbNodeProperties',
    as HashRef[DbNodeProperties()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbNode::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
