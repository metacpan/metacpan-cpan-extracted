package Google::Devtools::Cloudprofiler::V2::Profiler::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProfileType',
    as (Int | Str);

declare 'CreateProfileRequest',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest'];

coerce 'CreateProfileRequest',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest'->new($_) };

declare 'RepeatedCreateProfileRequest',
    as ArrayRef[CreateProfileRequest()];

coerce 'RepeatedCreateProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::CreateProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProfileRequest',
    as HashRef[CreateProfileRequest()];

declare 'CreateOfflineProfileRequest',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::CreateOfflineProfileRequest'];

coerce 'CreateOfflineProfileRequest',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::CreateOfflineProfileRequest'->new($_) };

declare 'RepeatedCreateOfflineProfileRequest',
    as ArrayRef[CreateOfflineProfileRequest()];

coerce 'RepeatedCreateOfflineProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::CreateOfflineProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOfflineProfileRequest',
    as HashRef[CreateOfflineProfileRequest()];

declare 'UpdateProfileRequest',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::UpdateProfileRequest'];

coerce 'UpdateProfileRequest',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::UpdateProfileRequest'->new($_) };

declare 'RepeatedUpdateProfileRequest',
    as ArrayRef[UpdateProfileRequest()];

coerce 'RepeatedUpdateProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::UpdateProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProfileRequest',
    as HashRef[UpdateProfileRequest()];

declare 'Profile',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::Profile'];

coerce 'Profile',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile'->new($_) };

declare 'RepeatedProfile',
    as ArrayRef[Profile()];

coerce 'RepeatedProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile'->new($_) } @$_ ] };

declare 'MapStringProfile',
    as HashRef[Profile()];

declare 'LabelsEntry',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::Profile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::Profile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Deployment',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::Deployment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::Deployment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::Deployment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListProfilesRequest',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesRequest'];

coerce 'ListProfilesRequest',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesRequest'->new($_) };

declare 'RepeatedListProfilesRequest',
    as ArrayRef[ListProfilesRequest()];

coerce 'RepeatedListProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListProfilesRequest',
    as HashRef[ListProfilesRequest()];

declare 'ListProfilesResponse',
    as InstanceOf['Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesResponse'];

coerce 'ListProfilesResponse',
    from HashRef, via { 'Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesResponse'->new($_) };

declare 'RepeatedListProfilesResponse',
    as ArrayRef[ListProfilesResponse()];

coerce 'RepeatedListProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudprofiler::V2::Profiler::ListProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListProfilesResponse',
    as HashRef[ListProfilesResponse()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudprofiler::V2::Profiler::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
