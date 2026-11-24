package Google::Cloud::Auditmanager::V1::Parameters::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Parameter',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Parameters::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Parameters::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Parameters::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'StringList',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Parameters::StringList'];

coerce 'StringList',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Parameters::StringList'->new($_) };

declare 'RepeatedStringList',
    as ArrayRef[StringList()];

coerce 'RepeatedStringList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Parameters::StringList'->new($_) } @$_ ] };

declare 'MapStringStringList',
    as HashRef[StringList()];

declare 'ParamValue',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Parameters::ParamValue'];

coerce 'ParamValue',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Parameters::ParamValue'->new($_) };

declare 'RepeatedParamValue',
    as ArrayRef[ParamValue()];

coerce 'RepeatedParamValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Parameters::ParamValue'->new($_) } @$_ ] };

declare 'MapStringParamValue',
    as HashRef[ParamValue()];

declare 'ParameterOverrides',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Parameters::ParameterOverrides'];

coerce 'ParameterOverrides',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Parameters::ParameterOverrides'->new($_) };

declare 'RepeatedParameterOverrides',
    as ArrayRef[ParameterOverrides()];

coerce 'RepeatedParameterOverrides',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Parameters::ParameterOverrides'->new($_) } @$_ ] };

declare 'MapStringParameterOverrides',
    as HashRef[ParameterOverrides()];

declare 'ParameterState',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Parameters::ParameterState'];

coerce 'ParameterState',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Parameters::ParameterState'->new($_) };

declare 'RepeatedParameterState',
    as ArrayRef[ParameterState()];

coerce 'RepeatedParameterState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Parameters::ParameterState'->new($_) } @$_ ] };

declare 'MapStringParameterState',
    as HashRef[ParameterState()];

declare 'CloudControlParameterStates',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Parameters::CloudControlParameterStates'];

coerce 'CloudControlParameterStates',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Parameters::CloudControlParameterStates'->new($_) };

declare 'RepeatedCloudControlParameterStates',
    as ArrayRef[CloudControlParameterStates()];

coerce 'RepeatedCloudControlParameterStates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Parameters::CloudControlParameterStates'->new($_) } @$_ ] };

declare 'MapStringCloudControlParameterStates',
    as HashRef[CloudControlParameterStates()];

1;

__END__

=head1 NAME

Google::Cloud::Auditmanager::V1::Parameters::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
