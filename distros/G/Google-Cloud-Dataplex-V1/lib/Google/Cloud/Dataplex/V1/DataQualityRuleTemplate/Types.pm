package Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataQualityRuleTemplate',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate'];

coerce 'DataQualityRuleTemplate',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate'->new($_) };

declare 'RepeatedDataQualityRuleTemplate',
    as ArrayRef[DataQualityRuleTemplate()];

coerce 'RepeatedDataQualityRuleTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate'->new($_) } @$_ ] };

declare 'MapStringDataQualityRuleTemplate',
    as HashRef[DataQualityRuleTemplate()];

declare 'Sql',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::Sql'];

coerce 'Sql',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::Sql'->new($_) };

declare 'RepeatedSql',
    as ArrayRef[Sql()];

coerce 'RepeatedSql',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::Sql'->new($_) } @$_ ] };

declare 'MapStringSql',
    as HashRef[Sql()];

declare 'ParameterDescription',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::ParameterDescription'];

coerce 'ParameterDescription',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::ParameterDescription'->new($_) };

declare 'RepeatedParameterDescription',
    as ArrayRef[ParameterDescription()];

coerce 'RepeatedParameterDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::ParameterDescription'->new($_) } @$_ ] };

declare 'MapStringParameterDescription',
    as HashRef[ParameterDescription()];

declare 'InputParametersEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::InputParametersEntry'];

coerce 'InputParametersEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::InputParametersEntry'->new($_) };

declare 'RepeatedInputParametersEntry',
    as ArrayRef[InputParametersEntry()];

coerce 'RepeatedInputParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::DataQualityRuleTemplate::InputParametersEntry'->new($_) } @$_ ] };

declare 'MapStringInputParametersEntry',
    as HashRef[InputParametersEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataQualityRuleTemplate::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
