package Google::Cloud::Gkehub::V1::Feature::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Feature',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::Feature'];

coerce 'Feature',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::Feature'->new($_) };

declare 'RepeatedFeature',
    as ArrayRef[Feature()];

coerce 'RepeatedFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::Feature'->new($_) } @$_ ] };

declare 'MapStringFeature',
    as HashRef[Feature()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::Feature::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::Feature::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::Feature::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MembershipSpecsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::Feature::MembershipSpecsEntry'];

coerce 'MembershipSpecsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::Feature::MembershipSpecsEntry'->new($_) };

declare 'RepeatedMembershipSpecsEntry',
    as ArrayRef[MembershipSpecsEntry()];

coerce 'RepeatedMembershipSpecsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::Feature::MembershipSpecsEntry'->new($_) } @$_ ] };

declare 'MapStringMembershipSpecsEntry',
    as HashRef[MembershipSpecsEntry()];

declare 'MembershipStatesEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::Feature::MembershipStatesEntry'];

coerce 'MembershipStatesEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::Feature::MembershipStatesEntry'->new($_) };

declare 'RepeatedMembershipStatesEntry',
    as ArrayRef[MembershipStatesEntry()];

coerce 'RepeatedMembershipStatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::Feature::MembershipStatesEntry'->new($_) } @$_ ] };

declare 'MapStringMembershipStatesEntry',
    as HashRef[MembershipStatesEntry()];

declare 'ScopeSpecsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::Feature::ScopeSpecsEntry'];

coerce 'ScopeSpecsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::Feature::ScopeSpecsEntry'->new($_) };

declare 'RepeatedScopeSpecsEntry',
    as ArrayRef[ScopeSpecsEntry()];

coerce 'RepeatedScopeSpecsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::Feature::ScopeSpecsEntry'->new($_) } @$_ ] };

declare 'MapStringScopeSpecsEntry',
    as HashRef[ScopeSpecsEntry()];

declare 'ScopeStatesEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::Feature::ScopeStatesEntry'];

coerce 'ScopeStatesEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::Feature::ScopeStatesEntry'->new($_) };

declare 'RepeatedScopeStatesEntry',
    as ArrayRef[ScopeStatesEntry()];

coerce 'RepeatedScopeStatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::Feature::ScopeStatesEntry'->new($_) } @$_ ] };

declare 'MapStringScopeStatesEntry',
    as HashRef[ScopeStatesEntry()];

declare 'FeatureResourceState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::FeatureResourceState'];

coerce 'FeatureResourceState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::FeatureResourceState'->new($_) };

declare 'RepeatedFeatureResourceState',
    as ArrayRef[FeatureResourceState()];

coerce 'RepeatedFeatureResourceState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::FeatureResourceState'->new($_) } @$_ ] };

declare 'MapStringFeatureResourceState',
    as HashRef[FeatureResourceState()];

declare 'State',
    as (Int | Str);

declare 'FeatureState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::FeatureState'];

coerce 'FeatureState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::FeatureState'->new($_) };

declare 'RepeatedFeatureState',
    as ArrayRef[FeatureState()];

coerce 'RepeatedFeatureState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::FeatureState'->new($_) } @$_ ] };

declare 'MapStringFeatureState',
    as HashRef[FeatureState()];

declare 'Code',
    as (Int | Str);

declare 'CommonFeatureSpec',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::CommonFeatureSpec'];

coerce 'CommonFeatureSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::CommonFeatureSpec'->new($_) };

declare 'RepeatedCommonFeatureSpec',
    as ArrayRef[CommonFeatureSpec()];

coerce 'RepeatedCommonFeatureSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::CommonFeatureSpec'->new($_) } @$_ ] };

declare 'MapStringCommonFeatureSpec',
    as HashRef[CommonFeatureSpec()];

declare 'CommonFeatureState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::CommonFeatureState'];

coerce 'CommonFeatureState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::CommonFeatureState'->new($_) };

declare 'RepeatedCommonFeatureState',
    as ArrayRef[CommonFeatureState()];

coerce 'RepeatedCommonFeatureState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::CommonFeatureState'->new($_) } @$_ ] };

declare 'MapStringCommonFeatureState',
    as HashRef[CommonFeatureState()];

declare 'ScopeFeatureSpec',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::ScopeFeatureSpec'];

coerce 'ScopeFeatureSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::ScopeFeatureSpec'->new($_) };

declare 'RepeatedScopeFeatureSpec',
    as ArrayRef[ScopeFeatureSpec()];

coerce 'RepeatedScopeFeatureSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::ScopeFeatureSpec'->new($_) } @$_ ] };

declare 'MapStringScopeFeatureSpec',
    as HashRef[ScopeFeatureSpec()];

declare 'ScopeFeatureState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::ScopeFeatureState'];

coerce 'ScopeFeatureState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::ScopeFeatureState'->new($_) };

declare 'RepeatedScopeFeatureState',
    as ArrayRef[ScopeFeatureState()];

coerce 'RepeatedScopeFeatureState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::ScopeFeatureState'->new($_) } @$_ ] };

declare 'MapStringScopeFeatureState',
    as HashRef[ScopeFeatureState()];

declare 'MembershipFeatureSpec',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::MembershipFeatureSpec'];

coerce 'MembershipFeatureSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::MembershipFeatureSpec'->new($_) };

declare 'RepeatedMembershipFeatureSpec',
    as ArrayRef[MembershipFeatureSpec()];

coerce 'RepeatedMembershipFeatureSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::MembershipFeatureSpec'->new($_) } @$_ ] };

declare 'MapStringMembershipFeatureSpec',
    as HashRef[MembershipFeatureSpec()];

declare 'MembershipFeatureState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Feature::MembershipFeatureState'];

coerce 'MembershipFeatureState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Feature::MembershipFeatureState'->new($_) };

declare 'RepeatedMembershipFeatureState',
    as ArrayRef[MembershipFeatureState()];

coerce 'RepeatedMembershipFeatureState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Feature::MembershipFeatureState'->new($_) } @$_ ] };

declare 'MapStringMembershipFeatureState',
    as HashRef[MembershipFeatureState()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::V1::Feature::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
