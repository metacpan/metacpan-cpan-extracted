package Google::Monitoring::Dashboard::V1::CollapsibleGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CollapsibleGroup',
    as InstanceOf['Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup'];

coerce 'CollapsibleGroup',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup'->new($_) };

declare 'RepeatedCollapsibleGroup',
    as ArrayRef[CollapsibleGroup()];

coerce 'RepeatedCollapsibleGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup'->new($_) } @$_ ] };

declare 'MapStringCollapsibleGroup',
    as HashRef[CollapsibleGroup()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::CollapsibleGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
