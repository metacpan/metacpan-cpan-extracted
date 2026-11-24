package Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MembershipSpec',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipSpec'];

coerce 'MembershipSpec',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipSpec'->new($_) };

declare 'RepeatedMembershipSpec',
    as ArrayRef[MembershipSpec()];

coerce 'RepeatedMembershipSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipSpec'->new($_) } @$_ ] };

declare 'MapStringMembershipSpec',
    as HashRef[MembershipSpec()];

declare 'ControlPlaneManagement',
    as (Int | Str);

declare 'Management',
    as (Int | Str);

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

declare 'LifecycleState',
    as (Int | Str);

declare 'ControlPlaneManagement',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::ControlPlaneManagement'];

coerce 'ControlPlaneManagement',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::ControlPlaneManagement'->new($_) };

declare 'RepeatedControlPlaneManagement',
    as ArrayRef[ControlPlaneManagement()];

coerce 'RepeatedControlPlaneManagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::ControlPlaneManagement'->new($_) } @$_ ] };

declare 'MapStringControlPlaneManagement',
    as HashRef[ControlPlaneManagement()];

declare 'Implementation',
    as (Int | Str);

declare 'DataPlaneManagement',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::DataPlaneManagement'];

coerce 'DataPlaneManagement',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::DataPlaneManagement'->new($_) };

declare 'RepeatedDataPlaneManagement',
    as ArrayRef[DataPlaneManagement()];

coerce 'RepeatedDataPlaneManagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::DataPlaneManagement'->new($_) } @$_ ] };

declare 'MapStringDataPlaneManagement',
    as HashRef[DataPlaneManagement()];

declare 'Condition',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::MembershipState::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'Code',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'StatusDetails',
    as InstanceOf['Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::StatusDetails'];

coerce 'StatusDetails',
    from HashRef, via { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::StatusDetails'->new($_) };

declare 'RepeatedStatusDetails',
    as ArrayRef[StatusDetails()];

coerce 'RepeatedStatusDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::StatusDetails'->new($_) } @$_ ] };

declare 'MapStringStatusDetails',
    as HashRef[StatusDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::Servicemesh::V1beta::Servicemesh::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
