package Google::Monitoring::Dashboard::V1::IncidentList::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IncidentList',
    as InstanceOf['Google::Monitoring::Dashboard::V1::IncidentList::IncidentList'];

coerce 'IncidentList',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::IncidentList::IncidentList'->new($_) };

declare 'RepeatedIncidentList',
    as ArrayRef[IncidentList()];

coerce 'RepeatedIncidentList',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::IncidentList::IncidentList'->new($_) } @$_ ] };

declare 'MapStringIncidentList',
    as HashRef[IncidentList()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::IncidentList::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
