package Google::Monitoring::Dashboard::V1::Alertchart::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AlertChart',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Alertchart::AlertChart'];

coerce 'AlertChart',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Alertchart::AlertChart'->new($_) };

declare 'RepeatedAlertChart',
    as ArrayRef[AlertChart()];

coerce 'RepeatedAlertChart',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Alertchart::AlertChart'->new($_) } @$_ ] };

declare 'MapStringAlertChart',
    as HashRef[AlertChart()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Alertchart::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
