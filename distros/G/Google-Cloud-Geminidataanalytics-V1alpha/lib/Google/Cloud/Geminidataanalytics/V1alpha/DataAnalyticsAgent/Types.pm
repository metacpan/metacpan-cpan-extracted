package Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataAnalyticsAgent',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent'];

coerce 'DataAnalyticsAgent',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent'->new($_) };

declare 'RepeatedDataAnalyticsAgent',
    as ArrayRef[DataAnalyticsAgent()];

coerce 'RepeatedDataAnalyticsAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::DataAnalyticsAgent'->new($_) } @$_ ] };

declare 'MapStringDataAnalyticsAgent',
    as HashRef[DataAnalyticsAgent()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::DataAnalyticsAgent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
