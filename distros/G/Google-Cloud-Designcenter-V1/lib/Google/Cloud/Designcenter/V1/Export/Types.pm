package Google::Cloud::Designcenter::V1::Export::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ArtifactLocation',
    as InstanceOf['Google::Cloud::Designcenter::V1::Export::ArtifactLocation'];

coerce 'ArtifactLocation',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Export::ArtifactLocation'->new($_) };

declare 'RepeatedArtifactLocation',
    as ArrayRef[ArtifactLocation()];

coerce 'RepeatedArtifactLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Export::ArtifactLocation'->new($_) } @$_ ] };

declare 'MapStringArtifactLocation',
    as HashRef[ArtifactLocation()];

declare 'DeveloperConnectExportConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Export::DeveloperConnectExportConfig'];

coerce 'DeveloperConnectExportConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Export::DeveloperConnectExportConfig'->new($_) };

declare 'RepeatedDeveloperConnectExportConfig',
    as ArrayRef[DeveloperConnectExportConfig()];

coerce 'RepeatedDeveloperConnectExportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Export::DeveloperConnectExportConfig'->new($_) } @$_ ] };

declare 'MapStringDeveloperConnectExportConfig',
    as HashRef[DeveloperConnectExportConfig()];

declare 'ExportIaCConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Export::ExportIaCConfig'];

coerce 'ExportIaCConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Export::ExportIaCConfig'->new($_) };

declare 'RepeatedExportIaCConfig',
    as ArrayRef[ExportIaCConfig()];

coerce 'RepeatedExportIaCConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Export::ExportIaCConfig'->new($_) } @$_ ] };

declare 'MapStringExportIaCConfig',
    as HashRef[ExportIaCConfig()];

declare 'TerraformConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Export::TerraformConfig'];

coerce 'TerraformConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Export::TerraformConfig'->new($_) };

declare 'RepeatedTerraformConfig',
    as ArrayRef[TerraformConfig()];

coerce 'RepeatedTerraformConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Export::TerraformConfig'->new($_) } @$_ ] };

declare 'MapStringTerraformConfig',
    as HashRef[TerraformConfig()];

declare 'TerraformModuleConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Export::TerraformModuleConfig'];

coerce 'TerraformModuleConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Export::TerraformModuleConfig'->new($_) };

declare 'RepeatedTerraformModuleConfig',
    as ArrayRef[TerraformModuleConfig()];

coerce 'RepeatedTerraformModuleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Export::TerraformModuleConfig'->new($_) } @$_ ] };

declare 'MapStringTerraformModuleConfig',
    as HashRef[TerraformModuleConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Export::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
