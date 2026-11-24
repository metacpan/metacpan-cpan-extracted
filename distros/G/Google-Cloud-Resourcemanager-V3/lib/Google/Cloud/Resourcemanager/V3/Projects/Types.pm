package Google::Cloud::Resourcemanager::V3::Projects::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Project',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::Project'];

coerce 'Project',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::Project'->new($_) };

declare 'RepeatedProject',
    as ArrayRef[Project()];

coerce 'RepeatedProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::Project'->new($_) } @$_ ] };

declare 'MapStringProject',
    as HashRef[Project()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::Project::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::Project::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::Project::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetProjectRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::GetProjectRequest'];

coerce 'GetProjectRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::GetProjectRequest'->new($_) };

declare 'RepeatedGetProjectRequest',
    as ArrayRef[GetProjectRequest()];

coerce 'RepeatedGetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::GetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectRequest',
    as HashRef[GetProjectRequest()];

declare 'ListProjectsRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::ListProjectsRequest'];

coerce 'ListProjectsRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsRequest'->new($_) };

declare 'RepeatedListProjectsRequest',
    as ArrayRef[ListProjectsRequest()];

coerce 'RepeatedListProjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListProjectsRequest',
    as HashRef[ListProjectsRequest()];

declare 'ListProjectsResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse'];

coerce 'ListProjectsResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse'->new($_) };

declare 'RepeatedListProjectsResponse',
    as ArrayRef[ListProjectsResponse()];

coerce 'RepeatedListProjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse'->new($_) } @$_ ] };

declare 'MapStringListProjectsResponse',
    as HashRef[ListProjectsResponse()];

declare 'SearchProjectsRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsRequest'];

coerce 'SearchProjectsRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsRequest'->new($_) };

declare 'RepeatedSearchProjectsRequest',
    as ArrayRef[SearchProjectsRequest()];

coerce 'RepeatedSearchProjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchProjectsRequest',
    as HashRef[SearchProjectsRequest()];

declare 'SearchProjectsResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse'];

coerce 'SearchProjectsResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse'->new($_) };

declare 'RepeatedSearchProjectsResponse',
    as ArrayRef[SearchProjectsResponse()];

coerce 'RepeatedSearchProjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchProjectsResponse',
    as HashRef[SearchProjectsResponse()];

declare 'CreateProjectRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::CreateProjectRequest'];

coerce 'CreateProjectRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::CreateProjectRequest'->new($_) };

declare 'RepeatedCreateProjectRequest',
    as ArrayRef[CreateProjectRequest()];

coerce 'RepeatedCreateProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::CreateProjectRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProjectRequest',
    as HashRef[CreateProjectRequest()];

declare 'CreateProjectMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::CreateProjectMetadata'];

coerce 'CreateProjectMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::CreateProjectMetadata'->new($_) };

declare 'RepeatedCreateProjectMetadata',
    as ArrayRef[CreateProjectMetadata()];

coerce 'RepeatedCreateProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::CreateProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateProjectMetadata',
    as HashRef[CreateProjectMetadata()];

declare 'UpdateProjectRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectRequest'];

coerce 'UpdateProjectRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectRequest'->new($_) };

declare 'RepeatedUpdateProjectRequest',
    as ArrayRef[UpdateProjectRequest()];

coerce 'RepeatedUpdateProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProjectRequest',
    as HashRef[UpdateProjectRequest()];

declare 'UpdateProjectMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectMetadata'];

coerce 'UpdateProjectMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectMetadata'->new($_) };

declare 'RepeatedUpdateProjectMetadata',
    as ArrayRef[UpdateProjectMetadata()];

coerce 'RepeatedUpdateProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateProjectMetadata',
    as HashRef[UpdateProjectMetadata()];

declare 'MoveProjectRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::MoveProjectRequest'];

coerce 'MoveProjectRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::MoveProjectRequest'->new($_) };

declare 'RepeatedMoveProjectRequest',
    as ArrayRef[MoveProjectRequest()];

coerce 'RepeatedMoveProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::MoveProjectRequest'->new($_) } @$_ ] };

declare 'MapStringMoveProjectRequest',
    as HashRef[MoveProjectRequest()];

declare 'MoveProjectMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::MoveProjectMetadata'];

coerce 'MoveProjectMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::MoveProjectMetadata'->new($_) };

declare 'RepeatedMoveProjectMetadata',
    as ArrayRef[MoveProjectMetadata()];

coerce 'RepeatedMoveProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::MoveProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringMoveProjectMetadata',
    as HashRef[MoveProjectMetadata()];

declare 'DeleteProjectRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectRequest'];

coerce 'DeleteProjectRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectRequest'->new($_) };

declare 'RepeatedDeleteProjectRequest',
    as ArrayRef[DeleteProjectRequest()];

coerce 'RepeatedDeleteProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProjectRequest',
    as HashRef[DeleteProjectRequest()];

declare 'DeleteProjectMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectMetadata'];

coerce 'DeleteProjectMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectMetadata'->new($_) };

declare 'RepeatedDeleteProjectMetadata',
    as ArrayRef[DeleteProjectMetadata()];

coerce 'RepeatedDeleteProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteProjectMetadata',
    as HashRef[DeleteProjectMetadata()];

declare 'UndeleteProjectRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectRequest'];

coerce 'UndeleteProjectRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectRequest'->new($_) };

declare 'RepeatedUndeleteProjectRequest',
    as ArrayRef[UndeleteProjectRequest()];

coerce 'RepeatedUndeleteProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteProjectRequest',
    as HashRef[UndeleteProjectRequest()];

declare 'UndeleteProjectMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectMetadata'];

coerce 'UndeleteProjectMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectMetadata'->new($_) };

declare 'RepeatedUndeleteProjectMetadata',
    as ArrayRef[UndeleteProjectMetadata()];

coerce 'RepeatedUndeleteProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeleteProjectMetadata',
    as HashRef[UndeleteProjectMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::Projects::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
