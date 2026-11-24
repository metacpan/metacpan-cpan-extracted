package Google::Cloud::Securitycenter::V1::Kubernetes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Kubernetes',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes'];

coerce 'Kubernetes',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes'->new($_) };

declare 'RepeatedKubernetes',
    as ArrayRef[Kubernetes()];

coerce 'RepeatedKubernetes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes'->new($_) } @$_ ] };

declare 'MapStringKubernetes',
    as HashRef[Kubernetes()];

declare 'Pod',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Pod'];

coerce 'Pod',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Pod'->new($_) };

declare 'RepeatedPod',
    as ArrayRef[Pod()];

coerce 'RepeatedPod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Pod'->new($_) } @$_ ] };

declare 'MapStringPod',
    as HashRef[Pod()];

declare 'Node',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'NodePool',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::NodePool'];

coerce 'NodePool',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::NodePool'->new($_) };

declare 'RepeatedNodePool',
    as ArrayRef[NodePool()];

coerce 'RepeatedNodePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::NodePool'->new($_) } @$_ ] };

declare 'MapStringNodePool',
    as HashRef[NodePool()];

declare 'Role',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Role'];

coerce 'Role',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Role'->new($_) };

declare 'RepeatedRole',
    as ArrayRef[Role()];

coerce 'RepeatedRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Role'->new($_) } @$_ ] };

declare 'MapStringRole',
    as HashRef[Role()];

declare 'Kind',
    as (Int | Str);

declare 'Binding',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Binding'];

coerce 'Binding',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Binding'->new($_) };

declare 'RepeatedBinding',
    as ArrayRef[Binding()];

coerce 'RepeatedBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Binding'->new($_) } @$_ ] };

declare 'MapStringBinding',
    as HashRef[Binding()];

declare 'Subject',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Subject'];

coerce 'Subject',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Subject'->new($_) };

declare 'RepeatedSubject',
    as ArrayRef[Subject()];

coerce 'RepeatedSubject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Subject'->new($_) } @$_ ] };

declare 'MapStringSubject',
    as HashRef[Subject()];

declare 'AuthType',
    as (Int | Str);

declare 'AccessReview',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::AccessReview'];

coerce 'AccessReview',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::AccessReview'->new($_) };

declare 'RepeatedAccessReview',
    as ArrayRef[AccessReview()];

coerce 'RepeatedAccessReview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::AccessReview'->new($_) } @$_ ] };

declare 'MapStringAccessReview',
    as HashRef[AccessReview()];

declare 'Object',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Object'];

coerce 'Object',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Object'->new($_) };

declare 'RepeatedObject',
    as ArrayRef[Object()];

coerce 'RepeatedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Kubernetes::Kubernetes::Object'->new($_) } @$_ ] };

declare 'MapStringObject',
    as HashRef[Object()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Kubernetes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
