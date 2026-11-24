package Google::Cloud::Osconfig::V1beta::GuestPolicies::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DesiredState',
    as (Int | Str);

declare 'GuestPolicy',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::GuestPolicy'];

coerce 'GuestPolicy',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GuestPolicy'->new($_) };

declare 'RepeatedGuestPolicy',
    as ArrayRef[GuestPolicy()];

coerce 'RepeatedGuestPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GuestPolicy'->new($_) } @$_ ] };

declare 'MapStringGuestPolicy',
    as HashRef[GuestPolicy()];

declare 'Assignment',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment'];

coerce 'Assignment',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment'->new($_) };

declare 'RepeatedAssignment',
    as ArrayRef[Assignment()];

coerce 'RepeatedAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment'->new($_) } @$_ ] };

declare 'MapStringAssignment',
    as HashRef[Assignment()];

declare 'GroupLabel',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::GroupLabel'];

coerce 'GroupLabel',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::GroupLabel'->new($_) };

declare 'RepeatedGroupLabel',
    as ArrayRef[GroupLabel()];

coerce 'RepeatedGroupLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::GroupLabel'->new($_) } @$_ ] };

declare 'MapStringGroupLabel',
    as HashRef[GroupLabel()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::GroupLabel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::GroupLabel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::GroupLabel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OsType',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::OsType'];

coerce 'OsType',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::OsType'->new($_) };

declare 'RepeatedOsType',
    as ArrayRef[OsType()];

coerce 'RepeatedOsType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Assignment::OsType'->new($_) } @$_ ] };

declare 'MapStringOsType',
    as HashRef[OsType()];

declare 'Package',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::Package'];

coerce 'Package',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Package'->new($_) };

declare 'RepeatedPackage',
    as ArrayRef[Package()];

coerce 'RepeatedPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::Package'->new($_) } @$_ ] };

declare 'MapStringPackage',
    as HashRef[Package()];

declare 'Manager',
    as (Int | Str);

declare 'AptRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::AptRepository'];

coerce 'AptRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::AptRepository'->new($_) };

declare 'RepeatedAptRepository',
    as ArrayRef[AptRepository()];

coerce 'RepeatedAptRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::AptRepository'->new($_) } @$_ ] };

declare 'MapStringAptRepository',
    as HashRef[AptRepository()];

declare 'ArchiveType',
    as (Int | Str);

declare 'YumRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::YumRepository'];

coerce 'YumRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::YumRepository'->new($_) };

declare 'RepeatedYumRepository',
    as ArrayRef[YumRepository()];

coerce 'RepeatedYumRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::YumRepository'->new($_) } @$_ ] };

declare 'MapStringYumRepository',
    as HashRef[YumRepository()];

declare 'ZypperRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::ZypperRepository'];

coerce 'ZypperRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ZypperRepository'->new($_) };

declare 'RepeatedZypperRepository',
    as ArrayRef[ZypperRepository()];

coerce 'RepeatedZypperRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ZypperRepository'->new($_) } @$_ ] };

declare 'MapStringZypperRepository',
    as HashRef[ZypperRepository()];

declare 'GooRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::GooRepository'];

coerce 'GooRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GooRepository'->new($_) };

declare 'RepeatedGooRepository',
    as ArrayRef[GooRepository()];

coerce 'RepeatedGooRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GooRepository'->new($_) } @$_ ] };

declare 'MapStringGooRepository',
    as HashRef[GooRepository()];

declare 'PackageRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::PackageRepository'];

coerce 'PackageRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::PackageRepository'->new($_) };

declare 'RepeatedPackageRepository',
    as ArrayRef[PackageRepository()];

coerce 'RepeatedPackageRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::PackageRepository'->new($_) } @$_ ] };

declare 'MapStringPackageRepository',
    as HashRef[PackageRepository()];

declare 'SoftwareRecipe',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe'];

coerce 'SoftwareRecipe',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe'->new($_) };

declare 'RepeatedSoftwareRecipe',
    as ArrayRef[SoftwareRecipe()];

coerce 'RepeatedSoftwareRecipe',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe'->new($_) } @$_ ] };

declare 'MapStringSoftwareRecipe',
    as HashRef[SoftwareRecipe()];

declare 'Artifact',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact'];

coerce 'Artifact',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact'->new($_) };

declare 'RepeatedArtifact',
    as ArrayRef[Artifact()];

coerce 'RepeatedArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact'->new($_) } @$_ ] };

declare 'MapStringArtifact',
    as HashRef[Artifact()];

declare 'Remote',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact::Remote'];

coerce 'Remote',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact::Remote'->new($_) };

declare 'RepeatedRemote',
    as ArrayRef[Remote()];

coerce 'RepeatedRemote',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact::Remote'->new($_) } @$_ ] };

declare 'MapStringRemote',
    as HashRef[Remote()];

declare 'Gcs',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact::Gcs'];

coerce 'Gcs',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact::Gcs'->new($_) };

declare 'RepeatedGcs',
    as ArrayRef[Gcs()];

coerce 'RepeatedGcs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Artifact::Gcs'->new($_) } @$_ ] };

declare 'MapStringGcs',
    as HashRef[Gcs()];

declare 'Step',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'CopyFile',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::CopyFile'];

coerce 'CopyFile',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::CopyFile'->new($_) };

declare 'RepeatedCopyFile',
    as ArrayRef[CopyFile()];

coerce 'RepeatedCopyFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::CopyFile'->new($_) } @$_ ] };

declare 'MapStringCopyFile',
    as HashRef[CopyFile()];

declare 'ExtractArchive',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::ExtractArchive'];

coerce 'ExtractArchive',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::ExtractArchive'->new($_) };

declare 'RepeatedExtractArchive',
    as ArrayRef[ExtractArchive()];

coerce 'RepeatedExtractArchive',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::ExtractArchive'->new($_) } @$_ ] };

declare 'MapStringExtractArchive',
    as HashRef[ExtractArchive()];

declare 'ArchiveType',
    as (Int | Str);

declare 'InstallMsi',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallMsi'];

coerce 'InstallMsi',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallMsi'->new($_) };

declare 'RepeatedInstallMsi',
    as ArrayRef[InstallMsi()];

coerce 'RepeatedInstallMsi',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallMsi'->new($_) } @$_ ] };

declare 'MapStringInstallMsi',
    as HashRef[InstallMsi()];

declare 'InstallDpkg',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallDpkg'];

coerce 'InstallDpkg',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallDpkg'->new($_) };

declare 'RepeatedInstallDpkg',
    as ArrayRef[InstallDpkg()];

coerce 'RepeatedInstallDpkg',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallDpkg'->new($_) } @$_ ] };

declare 'MapStringInstallDpkg',
    as HashRef[InstallDpkg()];

declare 'InstallRpm',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallRpm'];

coerce 'InstallRpm',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallRpm'->new($_) };

declare 'RepeatedInstallRpm',
    as ArrayRef[InstallRpm()];

coerce 'RepeatedInstallRpm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::InstallRpm'->new($_) } @$_ ] };

declare 'MapStringInstallRpm',
    as HashRef[InstallRpm()];

declare 'ExecFile',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::ExecFile'];

coerce 'ExecFile',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::ExecFile'->new($_) };

declare 'RepeatedExecFile',
    as ArrayRef[ExecFile()];

coerce 'RepeatedExecFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::ExecFile'->new($_) } @$_ ] };

declare 'MapStringExecFile',
    as HashRef[ExecFile()];

declare 'RunScript',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::RunScript'];

coerce 'RunScript',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::RunScript'->new($_) };

declare 'RepeatedRunScript',
    as ArrayRef[RunScript()];

coerce 'RepeatedRunScript',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::SoftwareRecipe::Step::RunScript'->new($_) } @$_ ] };

declare 'MapStringRunScript',
    as HashRef[RunScript()];

declare 'Interpreter',
    as (Int | Str);

declare 'CreateGuestPolicyRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::CreateGuestPolicyRequest'];

coerce 'CreateGuestPolicyRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::CreateGuestPolicyRequest'->new($_) };

declare 'RepeatedCreateGuestPolicyRequest',
    as ArrayRef[CreateGuestPolicyRequest()];

coerce 'RepeatedCreateGuestPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::CreateGuestPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGuestPolicyRequest',
    as HashRef[CreateGuestPolicyRequest()];

declare 'GetGuestPolicyRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::GetGuestPolicyRequest'];

coerce 'GetGuestPolicyRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GetGuestPolicyRequest'->new($_) };

declare 'RepeatedGetGuestPolicyRequest',
    as ArrayRef[GetGuestPolicyRequest()];

coerce 'RepeatedGetGuestPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::GetGuestPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetGuestPolicyRequest',
    as HashRef[GetGuestPolicyRequest()];

declare 'ListGuestPoliciesRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesRequest'];

coerce 'ListGuestPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesRequest'->new($_) };

declare 'RepeatedListGuestPoliciesRequest',
    as ArrayRef[ListGuestPoliciesRequest()];

coerce 'RepeatedListGuestPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListGuestPoliciesRequest',
    as HashRef[ListGuestPoliciesRequest()];

declare 'ListGuestPoliciesResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesResponse'];

coerce 'ListGuestPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesResponse'->new($_) };

declare 'RepeatedListGuestPoliciesResponse',
    as ArrayRef[ListGuestPoliciesResponse()];

coerce 'RepeatedListGuestPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::ListGuestPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListGuestPoliciesResponse',
    as HashRef[ListGuestPoliciesResponse()];

declare 'UpdateGuestPolicyRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::UpdateGuestPolicyRequest'];

coerce 'UpdateGuestPolicyRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::UpdateGuestPolicyRequest'->new($_) };

declare 'RepeatedUpdateGuestPolicyRequest',
    as ArrayRef[UpdateGuestPolicyRequest()];

coerce 'RepeatedUpdateGuestPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::UpdateGuestPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGuestPolicyRequest',
    as HashRef[UpdateGuestPolicyRequest()];

declare 'DeleteGuestPolicyRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::DeleteGuestPolicyRequest'];

coerce 'DeleteGuestPolicyRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::DeleteGuestPolicyRequest'->new($_) };

declare 'RepeatedDeleteGuestPolicyRequest',
    as ArrayRef[DeleteGuestPolicyRequest()];

coerce 'RepeatedDeleteGuestPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::DeleteGuestPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGuestPolicyRequest',
    as HashRef[DeleteGuestPolicyRequest()];

declare 'LookupEffectiveGuestPolicyRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest'];

coerce 'LookupEffectiveGuestPolicyRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest'->new($_) };

declare 'RepeatedLookupEffectiveGuestPolicyRequest',
    as ArrayRef[LookupEffectiveGuestPolicyRequest()];

coerce 'RepeatedLookupEffectiveGuestPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEffectiveGuestPolicyRequest',
    as HashRef[LookupEffectiveGuestPolicyRequest()];

declare 'EffectiveGuestPolicy',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy'];

coerce 'EffectiveGuestPolicy',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy'->new($_) };

declare 'RepeatedEffectiveGuestPolicy',
    as ArrayRef[EffectiveGuestPolicy()];

coerce 'RepeatedEffectiveGuestPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy'->new($_) } @$_ ] };

declare 'MapStringEffectiveGuestPolicy',
    as HashRef[EffectiveGuestPolicy()];

declare 'SourcedPackage',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedPackage'];

coerce 'SourcedPackage',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedPackage'->new($_) };

declare 'RepeatedSourcedPackage',
    as ArrayRef[SourcedPackage()];

coerce 'RepeatedSourcedPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedPackage'->new($_) } @$_ ] };

declare 'MapStringSourcedPackage',
    as HashRef[SourcedPackage()];

declare 'SourcedPackageRepository',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedPackageRepository'];

coerce 'SourcedPackageRepository',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedPackageRepository'->new($_) };

declare 'RepeatedSourcedPackageRepository',
    as ArrayRef[SourcedPackageRepository()];

coerce 'RepeatedSourcedPackageRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedPackageRepository'->new($_) } @$_ ] };

declare 'MapStringSourcedPackageRepository',
    as HashRef[SourcedPackageRepository()];

declare 'SourcedSoftwareRecipe',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedSoftwareRecipe'];

coerce 'SourcedSoftwareRecipe',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedSoftwareRecipe'->new($_) };

declare 'RepeatedSourcedSoftwareRecipe',
    as ArrayRef[SourcedSoftwareRecipe()];

coerce 'RepeatedSourcedSoftwareRecipe',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::GuestPolicies::EffectiveGuestPolicy::SourcedSoftwareRecipe'->new($_) } @$_ ] };

declare 'MapStringSourcedSoftwareRecipe',
    as HashRef[SourcedSoftwareRecipe()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1beta::GuestPolicies::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
