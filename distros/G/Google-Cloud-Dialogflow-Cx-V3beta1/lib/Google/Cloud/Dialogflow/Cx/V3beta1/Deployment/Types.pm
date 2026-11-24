package Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Deployment',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'State',
    as (Int | Str);

declare 'Result',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment::Result'];

coerce 'Result',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment::Result'->new($_) };

declare 'RepeatedResult',
    as ArrayRef[Result()];

coerce 'RepeatedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Deployment::Result'->new($_) } @$_ ] };

declare 'MapStringResult',
    as HashRef[Result()];

declare 'ListDeploymentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest'];

coerce 'ListDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest'->new($_) };

declare 'RepeatedListDeploymentsRequest',
    as ArrayRef[ListDeploymentsRequest()];

coerce 'RepeatedListDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsRequest',
    as HashRef[ListDeploymentsRequest()];

declare 'ListDeploymentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse'];

coerce 'ListDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse'->new($_) };

declare 'RepeatedListDeploymentsResponse',
    as ArrayRef[ListDeploymentsResponse()];

coerce 'RepeatedListDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::ListDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsResponse',
    as HashRef[ListDeploymentsResponse()];

declare 'GetDeploymentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::GetDeploymentRequest'];

coerce 'GetDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::GetDeploymentRequest'->new($_) };

declare 'RepeatedGetDeploymentRequest',
    as ArrayRef[GetDeploymentRequest()];

coerce 'RepeatedGetDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::GetDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentRequest',
    as HashRef[GetDeploymentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Deployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
