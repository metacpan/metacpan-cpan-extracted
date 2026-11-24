package Google::Devtools::Resultstore::V2::ConfiguredTarget::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConfiguredTarget',
    as InstanceOf['Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget'];

coerce 'ConfiguredTarget',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget'->new($_) };

declare 'RepeatedConfiguredTarget',
    as ArrayRef[ConfiguredTarget()];

coerce 'RepeatedConfiguredTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget'->new($_) } @$_ ] };

declare 'MapStringConfiguredTarget',
    as HashRef[ConfiguredTarget()];

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTarget::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'ConfiguredTestAttributes',
    as InstanceOf['Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTestAttributes'];

coerce 'ConfiguredTestAttributes',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTestAttributes'->new($_) };

declare 'RepeatedConfiguredTestAttributes',
    as ArrayRef[ConfiguredTestAttributes()];

coerce 'RepeatedConfiguredTestAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ConfiguredTarget::ConfiguredTestAttributes'->new($_) } @$_ ] };

declare 'MapStringConfiguredTestAttributes',
    as HashRef[ConfiguredTestAttributes()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::ConfiguredTarget::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
