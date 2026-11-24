package Google::Monitoring::Dashboard::V1::DashboardFilter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DashboardFilter',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter'];

coerce 'DashboardFilter',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter'->new($_) };

declare 'RepeatedDashboardFilter',
    as ArrayRef[DashboardFilter()];

coerce 'RepeatedDashboardFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter'->new($_) } @$_ ] };

declare 'MapStringDashboardFilter',
    as HashRef[DashboardFilter()];

declare 'FilterType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::DashboardFilter::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
