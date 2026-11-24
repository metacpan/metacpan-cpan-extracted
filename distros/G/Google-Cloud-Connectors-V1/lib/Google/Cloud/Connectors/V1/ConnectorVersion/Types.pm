package Google::Cloud::Connectors::V1::ConnectorVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConnectorVersionView',
    as (Int | Str);

declare 'ConnectorVersion',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion'];

coerce 'ConnectorVersion',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion'->new($_) };

declare 'RepeatedConnectorVersion',
    as ArrayRef[ConnectorVersion()];

coerce 'RepeatedConnectorVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion'->new($_) } @$_ ] };

declare 'MapStringConnectorVersion',
    as HashRef[ConnectorVersion()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ConnectorVersion::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetConnectorVersionRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::GetConnectorVersionRequest'];

coerce 'GetConnectorVersionRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::GetConnectorVersionRequest'->new($_) };

declare 'RepeatedGetConnectorVersionRequest',
    as ArrayRef[GetConnectorVersionRequest()];

coerce 'RepeatedGetConnectorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::GetConnectorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectorVersionRequest',
    as HashRef[GetConnectorVersionRequest()];

declare 'ListConnectorVersionsRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsRequest'];

coerce 'ListConnectorVersionsRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsRequest'->new($_) };

declare 'RepeatedListConnectorVersionsRequest',
    as ArrayRef[ListConnectorVersionsRequest()];

coerce 'RepeatedListConnectorVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectorVersionsRequest',
    as HashRef[ListConnectorVersionsRequest()];

declare 'ListConnectorVersionsResponse',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsResponse'];

coerce 'ListConnectorVersionsResponse',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsResponse'->new($_) };

declare 'RepeatedListConnectorVersionsResponse',
    as ArrayRef[ListConnectorVersionsResponse()];

coerce 'RepeatedListConnectorVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ListConnectorVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectorVersionsResponse',
    as HashRef[ListConnectorVersionsResponse()];

declare 'SupportedRuntimeFeatures',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::SupportedRuntimeFeatures'];

coerce 'SupportedRuntimeFeatures',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::SupportedRuntimeFeatures'->new($_) };

declare 'RepeatedSupportedRuntimeFeatures',
    as ArrayRef[SupportedRuntimeFeatures()];

coerce 'RepeatedSupportedRuntimeFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::SupportedRuntimeFeatures'->new($_) } @$_ ] };

declare 'MapStringSupportedRuntimeFeatures',
    as HashRef[SupportedRuntimeFeatures()];

declare 'EgressControlConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::EgressControlConfig'];

coerce 'EgressControlConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::EgressControlConfig'->new($_) };

declare 'RepeatedEgressControlConfig',
    as ArrayRef[EgressControlConfig()];

coerce 'RepeatedEgressControlConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::EgressControlConfig'->new($_) } @$_ ] };

declare 'MapStringEgressControlConfig',
    as HashRef[EgressControlConfig()];

declare 'ExtractionRules',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRules'];

coerce 'ExtractionRules',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRules'->new($_) };

declare 'RepeatedExtractionRules',
    as ArrayRef[ExtractionRules()];

coerce 'RepeatedExtractionRules',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRules'->new($_) } @$_ ] };

declare 'MapStringExtractionRules',
    as HashRef[ExtractionRules()];

declare 'ExtractionRule',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule'];

coerce 'ExtractionRule',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule'->new($_) };

declare 'RepeatedExtractionRule',
    as ArrayRef[ExtractionRule()];

coerce 'RepeatedExtractionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule'->new($_) } @$_ ] };

declare 'MapStringExtractionRule',
    as HashRef[ExtractionRule()];

declare 'SourceType',
    as (Int | Str);

declare 'Source',
    as InstanceOf['Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::ConnectorVersion::ExtractionRule::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::ConnectorVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
