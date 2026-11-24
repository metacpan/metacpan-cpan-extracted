package Google::Monitoring::Dashboard::V1::Dashboard::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Dashboard',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Dashboard::Dashboard'];

coerce 'Dashboard',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard'->new($_) };

declare 'RepeatedDashboard',
    as ArrayRef[Dashboard()];

coerce 'RepeatedDashboard',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard'->new($_) } @$_ ] };

declare 'MapStringDashboard',
    as HashRef[Dashboard()];

declare 'LabelsEntry',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Dashboard::Dashboard::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Dashboard::Dashboard::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Dashboard::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
