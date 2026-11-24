package Google::Devtools::Artifactregistry::V1beta2::Settings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProjectSettings',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings'];

coerce 'ProjectSettings',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings'->new($_) };

declare 'RepeatedProjectSettings',
    as ArrayRef[ProjectSettings()];

coerce 'RepeatedProjectSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings'->new($_) } @$_ ] };

declare 'MapStringProjectSettings',
    as HashRef[ProjectSettings()];

declare 'RedirectionState',
    as (Int | Str);

declare 'GetProjectSettingsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Settings::GetProjectSettingsRequest'];

coerce 'GetProjectSettingsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Settings::GetProjectSettingsRequest'->new($_) };

declare 'RepeatedGetProjectSettingsRequest',
    as ArrayRef[GetProjectSettingsRequest()];

coerce 'RepeatedGetProjectSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Settings::GetProjectSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectSettingsRequest',
    as HashRef[GetProjectSettingsRequest()];

declare 'UpdateProjectSettingsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Settings::UpdateProjectSettingsRequest'];

coerce 'UpdateProjectSettingsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Settings::UpdateProjectSettingsRequest'->new($_) };

declare 'RepeatedUpdateProjectSettingsRequest',
    as ArrayRef[UpdateProjectSettingsRequest()];

coerce 'RepeatedUpdateProjectSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Settings::UpdateProjectSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProjectSettingsRequest',
    as HashRef[UpdateProjectSettingsRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Settings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
