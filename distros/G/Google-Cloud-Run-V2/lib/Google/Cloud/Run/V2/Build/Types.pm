package Google::Cloud::Run::V2::Build::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SubmitBuildRequest',
    as InstanceOf['Google::Cloud::Run::V2::Build::SubmitBuildRequest'];

coerce 'SubmitBuildRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest'->new($_) };

declare 'RepeatedSubmitBuildRequest',
    as ArrayRef[SubmitBuildRequest()];

coerce 'RepeatedSubmitBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitBuildRequest',
    as HashRef[SubmitBuildRequest()];

declare 'DockerBuild',
    as InstanceOf['Google::Cloud::Run::V2::Build::SubmitBuildRequest::DockerBuild'];

coerce 'DockerBuild',
    from HashRef, via { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest::DockerBuild'->new($_) };

declare 'RepeatedDockerBuild',
    as ArrayRef[DockerBuild()];

coerce 'RepeatedDockerBuild',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest::DockerBuild'->new($_) } @$_ ] };

declare 'MapStringDockerBuild',
    as HashRef[DockerBuild()];

declare 'BuildpacksBuild',
    as InstanceOf['Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild'];

coerce 'BuildpacksBuild',
    from HashRef, via { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild'->new($_) };

declare 'RepeatedBuildpacksBuild',
    as ArrayRef[BuildpacksBuild()];

coerce 'RepeatedBuildpacksBuild',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild'->new($_) } @$_ ] };

declare 'MapStringBuildpacksBuild',
    as HashRef[BuildpacksBuild()];

declare 'EnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild::EnvironmentVariablesEntry'];

coerce 'EnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild::EnvironmentVariablesEntry'->new($_) };

declare 'RepeatedEnvironmentVariablesEntry',
    as ArrayRef[EnvironmentVariablesEntry()];

coerce 'RepeatedEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Build::SubmitBuildRequest::BuildpacksBuild::EnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariablesEntry',
    as HashRef[EnvironmentVariablesEntry()];

declare 'SubmitBuildResponse',
    as InstanceOf['Google::Cloud::Run::V2::Build::SubmitBuildResponse'];

coerce 'SubmitBuildResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::Build::SubmitBuildResponse'->new($_) };

declare 'RepeatedSubmitBuildResponse',
    as ArrayRef[SubmitBuildResponse()];

coerce 'RepeatedSubmitBuildResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Build::SubmitBuildResponse'->new($_) } @$_ ] };

declare 'MapStringSubmitBuildResponse',
    as HashRef[SubmitBuildResponse()];

declare 'StorageSource',
    as InstanceOf['Google::Cloud::Run::V2::Build::StorageSource'];

coerce 'StorageSource',
    from HashRef, via { 'Google::Cloud::Run::V2::Build::StorageSource'->new($_) };

declare 'RepeatedStorageSource',
    as ArrayRef[StorageSource()];

coerce 'RepeatedStorageSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Build::StorageSource'->new($_) } @$_ ] };

declare 'MapStringStorageSource',
    as HashRef[StorageSource()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Build::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
