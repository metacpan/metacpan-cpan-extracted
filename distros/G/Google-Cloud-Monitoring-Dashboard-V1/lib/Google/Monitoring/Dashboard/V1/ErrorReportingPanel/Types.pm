package Google::Monitoring::Dashboard::V1::ErrorReportingPanel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ErrorReportingPanel',
    as InstanceOf['Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel'];

coerce 'ErrorReportingPanel',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel'->new($_) };

declare 'RepeatedErrorReportingPanel',
    as ArrayRef[ErrorReportingPanel()];

coerce 'RepeatedErrorReportingPanel',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel'->new($_) } @$_ ] };

declare 'MapStringErrorReportingPanel',
    as HashRef[ErrorReportingPanel()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::ErrorReportingPanel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
