package Google::Devtools::Resultstore::V2::Target::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TargetType',
    as (Int | Str);

declare 'TestSize',
    as (Int | Str);

declare 'Target',
    as InstanceOf['Google::Devtools::Resultstore::V2::Target::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Target::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Target::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::Target::Target::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Target::Target::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Target::Target::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'TargetAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::Target::TargetAttributes'];

coerce 'TargetAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Target::TargetAttributes'->new($_) };

declare 'RepeatedTargetAttributes',
    as ArrayRef[TargetAttributes()];

coerce 'RepeatedTargetAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Target::TargetAttributes'->new($_) } @$_ ] };

declare 'MapStringTargetAttributes',
    as HashRef[TargetAttributes()];

declare 'TestAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::Target::TestAttributes'];

coerce 'TestAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Target::TestAttributes'->new($_) };

declare 'RepeatedTestAttributes',
    as ArrayRef[TestAttributes()];

coerce 'RepeatedTestAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Target::TestAttributes'->new($_) } @$_ ] };

declare 'MapStringTestAttributes',
    as HashRef[TestAttributes()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::Target::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
