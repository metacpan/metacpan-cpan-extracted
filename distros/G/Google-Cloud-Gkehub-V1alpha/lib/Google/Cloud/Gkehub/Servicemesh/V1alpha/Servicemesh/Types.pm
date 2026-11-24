package Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FeatureState',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState'];

coerce 'FeatureState',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState'->new($_) };

declare 'RepeatedFeatureState',
    as ArrayRef[FeatureState()];

coerce 'RepeatedFeatureState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState'->new($_) } @$_ ] };

declare 'MapStringFeatureState',
    as HashRef[FeatureState()];

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

declare 'AnalysisMessageBase',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase'];

coerce 'AnalysisMessageBase',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase'->new($_) };

declare 'RepeatedAnalysisMessageBase',
    as ArrayRef[AnalysisMessageBase()];

coerce 'RepeatedAnalysisMessageBase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase'->new($_) } @$_ ] };

declare 'MapStringAnalysisMessageBase',
    as HashRef[AnalysisMessageBase()];

declare 'Level',
    as (Int | Str);

declare 'Type',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase::Type'];

coerce 'Type',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase::Type'->new($_) };

declare 'RepeatedType',
    as ArrayRef[Type()];

coerce 'RepeatedType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase::Type'->new($_) } @$_ ] };

declare 'MapStringType',
    as HashRef[Type()];

declare 'AnalysisMessage',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage'];

coerce 'AnalysisMessage',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage'->new($_) };

declare 'RepeatedAnalysisMessage',
    as ArrayRef[AnalysisMessage()];

coerce 'RepeatedAnalysisMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage'->new($_) } @$_ ] };

declare 'MapStringAnalysisMessage',
    as HashRef[AnalysisMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
