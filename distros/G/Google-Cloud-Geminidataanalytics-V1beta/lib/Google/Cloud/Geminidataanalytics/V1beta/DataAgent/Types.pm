package Google::Cloud::Geminidataanalytics::V1beta::DataAgent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataAgent',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent'];

coerce 'DataAgent',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent'->new($_) };

declare 'RepeatedDataAgent',
    as ArrayRef[DataAgent()];

coerce 'RepeatedDataAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent'->new($_) } @$_ ] };

declare 'MapStringDataAgent',
    as HashRef[DataAgent()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgent::DataAgent::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::DataAgent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
