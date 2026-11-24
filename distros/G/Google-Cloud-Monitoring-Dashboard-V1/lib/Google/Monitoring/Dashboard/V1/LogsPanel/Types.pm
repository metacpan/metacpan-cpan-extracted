package Google::Monitoring::Dashboard::V1::LogsPanel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogsPanel',
    as InstanceOf['Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel'];

coerce 'LogsPanel',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel'->new($_) };

declare 'RepeatedLogsPanel',
    as ArrayRef[LogsPanel()];

coerce 'RepeatedLogsPanel',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel'->new($_) } @$_ ] };

declare 'MapStringLogsPanel',
    as HashRef[LogsPanel()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::LogsPanel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
