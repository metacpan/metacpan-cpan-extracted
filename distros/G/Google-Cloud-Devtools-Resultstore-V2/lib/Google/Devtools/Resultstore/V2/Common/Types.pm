package Google::Devtools::Resultstore::V2::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Language',
    as (Int | Str);

declare 'Status',
    as (Int | Str);

declare 'UploadStatus',
    as (Int | Str);

declare 'StatusAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::Common::StatusAttributes'];

coerce 'StatusAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Common::StatusAttributes'->new($_) };

declare 'RepeatedStatusAttributes',
    as ArrayRef[StatusAttributes()];

coerce 'RepeatedStatusAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Common::StatusAttributes'->new($_) } @$_ ] };

declare 'MapStringStatusAttributes',
    as HashRef[StatusAttributes()];

declare 'Property',
    as InstanceOf['Google::Devtools::Resultstore::V2::Common::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Common::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Common::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'Timing',
    as InstanceOf['Google::Devtools::Resultstore::V2::Common::Timing'];

coerce 'Timing',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Common::Timing'->new($_) };

declare 'RepeatedTiming',
    as ArrayRef[Timing()];

coerce 'RepeatedTiming',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Common::Timing'->new($_) } @$_ ] };

declare 'MapStringTiming',
    as HashRef[Timing()];

declare 'Dependency',
    as InstanceOf['Google::Devtools::Resultstore::V2::Common::Dependency'];

coerce 'Dependency',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Common::Dependency'->new($_) };

declare 'RepeatedDependency',
    as ArrayRef[Dependency()];

coerce 'RepeatedDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Common::Dependency'->new($_) } @$_ ] };

declare 'MapStringDependency',
    as HashRef[Dependency()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::Common::Dependency::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::Common::Dependency::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::Common::Dependency::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
