package Google::Cloud::Dataplex::V1::Analyze::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Environment',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'InfrastructureSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec'];

coerce 'InfrastructureSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec'->new($_) };

declare 'RepeatedInfrastructureSpec',
    as ArrayRef[InfrastructureSpec()];

coerce 'RepeatedInfrastructureSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec'->new($_) } @$_ ] };

declare 'MapStringInfrastructureSpec',
    as HashRef[InfrastructureSpec()];

declare 'ComputeResources',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::ComputeResources'];

coerce 'ComputeResources',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::ComputeResources'->new($_) };

declare 'RepeatedComputeResources',
    as ArrayRef[ComputeResources()];

coerce 'RepeatedComputeResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::ComputeResources'->new($_) } @$_ ] };

declare 'MapStringComputeResources',
    as HashRef[ComputeResources()];

declare 'OsImageRuntime',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::OsImageRuntime'];

coerce 'OsImageRuntime',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::OsImageRuntime'->new($_) };

declare 'RepeatedOsImageRuntime',
    as ArrayRef[OsImageRuntime()];

coerce 'RepeatedOsImageRuntime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::OsImageRuntime'->new($_) } @$_ ] };

declare 'MapStringOsImageRuntime',
    as HashRef[OsImageRuntime()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::OsImageRuntime::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::OsImageRuntime::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::InfrastructureSpec::OsImageRuntime::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'SessionSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::SessionSpec'];

coerce 'SessionSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::SessionSpec'->new($_) };

declare 'RepeatedSessionSpec',
    as ArrayRef[SessionSpec()];

coerce 'RepeatedSessionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::SessionSpec'->new($_) } @$_ ] };

declare 'MapStringSessionSpec',
    as HashRef[SessionSpec()];

declare 'SessionStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::SessionStatus'];

coerce 'SessionStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::SessionStatus'->new($_) };

declare 'RepeatedSessionStatus',
    as ArrayRef[SessionStatus()];

coerce 'RepeatedSessionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::SessionStatus'->new($_) } @$_ ] };

declare 'MapStringSessionStatus',
    as HashRef[SessionStatus()];

declare 'Endpoints',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::Endpoints'];

coerce 'Endpoints',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::Endpoints'->new($_) };

declare 'RepeatedEndpoints',
    as ArrayRef[Endpoints()];

coerce 'RepeatedEndpoints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::Endpoints'->new($_) } @$_ ] };

declare 'MapStringEndpoints',
    as HashRef[Endpoints()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Environment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Environment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Environment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Content',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Content'];

coerce 'Content',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Content'->new($_) };

declare 'RepeatedContent',
    as ArrayRef[Content()];

coerce 'RepeatedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Content'->new($_) } @$_ ] };

declare 'MapStringContent',
    as HashRef[Content()];

declare 'SqlScript',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Content::SqlScript'];

coerce 'SqlScript',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Content::SqlScript'->new($_) };

declare 'RepeatedSqlScript',
    as ArrayRef[SqlScript()];

coerce 'RepeatedSqlScript',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Content::SqlScript'->new($_) } @$_ ] };

declare 'MapStringSqlScript',
    as HashRef[SqlScript()];

declare 'QueryEngine',
    as (Int | Str);

declare 'Notebook',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Content::Notebook'];

coerce 'Notebook',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Content::Notebook'->new($_) };

declare 'RepeatedNotebook',
    as ArrayRef[Notebook()];

coerce 'RepeatedNotebook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Content::Notebook'->new($_) } @$_ ] };

declare 'MapStringNotebook',
    as HashRef[Notebook()];

declare 'KernelType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Content::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Content::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Content::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Session',
    as InstanceOf['Google::Cloud::Dataplex::V1::Analyze::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Analyze::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Analyze::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Analyze::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
