package Google::Monitoring::Dashboard::V1::TableDisplayOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableDisplayOptions',
    as InstanceOf['Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions'];

coerce 'TableDisplayOptions',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions'->new($_) };

declare 'RepeatedTableDisplayOptions',
    as ArrayRef[TableDisplayOptions()];

coerce 'RepeatedTableDisplayOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::TableDisplayOptions::TableDisplayOptions'->new($_) } @$_ ] };

declare 'MapStringTableDisplayOptions',
    as HashRef[TableDisplayOptions()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::TableDisplayOptions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
