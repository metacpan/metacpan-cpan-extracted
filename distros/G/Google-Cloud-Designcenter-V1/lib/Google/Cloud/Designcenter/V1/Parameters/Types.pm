package Google::Cloud::Designcenter::V1::Parameters::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComponentVariable',
    as InstanceOf['Google::Cloud::Designcenter::V1::Parameters::ComponentVariable'];

coerce 'ComponentVariable',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Parameters::ComponentVariable'->new($_) };

declare 'RepeatedComponentVariable',
    as ArrayRef[ComponentVariable()];

coerce 'RepeatedComponentVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Parameters::ComponentVariable'->new($_) } @$_ ] };

declare 'MapStringComponentVariable',
    as HashRef[ComponentVariable()];

declare 'SaaSRuntimeContext',
    as InstanceOf['Google::Cloud::Designcenter::V1::Parameters::SaaSRuntimeContext'];

coerce 'SaaSRuntimeContext',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Parameters::SaaSRuntimeContext'->new($_) };

declare 'RepeatedSaaSRuntimeContext',
    as ArrayRef[SaaSRuntimeContext()];

coerce 'RepeatedSaaSRuntimeContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Parameters::SaaSRuntimeContext'->new($_) } @$_ ] };

declare 'MapStringSaaSRuntimeContext',
    as HashRef[SaaSRuntimeContext()];

declare 'ConnectionParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Parameters::ConnectionParameters'];

coerce 'ConnectionParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Parameters::ConnectionParameters'->new($_) };

declare 'RepeatedConnectionParameters',
    as ArrayRef[ConnectionParameters()];

coerce 'RepeatedConnectionParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Parameters::ConnectionParameters'->new($_) } @$_ ] };

declare 'MapStringConnectionParameters',
    as HashRef[ConnectionParameters()];

declare 'ComponentParameterSchema',
    as InstanceOf['Google::Cloud::Designcenter::V1::Parameters::ComponentParameterSchema'];

coerce 'ComponentParameterSchema',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Parameters::ComponentParameterSchema'->new($_) };

declare 'RepeatedComponentParameterSchema',
    as ArrayRef[ComponentParameterSchema()];

coerce 'RepeatedComponentParameterSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Parameters::ComponentParameterSchema'->new($_) } @$_ ] };

declare 'MapStringComponentParameterSchema',
    as HashRef[ComponentParameterSchema()];

declare 'Parameter',
    as InstanceOf['Google::Cloud::Designcenter::V1::Parameters::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Parameters::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Parameters::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'CloudControlConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Parameters::CloudControlConfig'];

coerce 'CloudControlConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Parameters::CloudControlConfig'->new($_) };

declare 'RepeatedCloudControlConfig',
    as ArrayRef[CloudControlConfig()];

coerce 'RepeatedCloudControlConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Parameters::CloudControlConfig'->new($_) } @$_ ] };

declare 'MapStringCloudControlConfig',
    as HashRef[CloudControlConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Parameters::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
