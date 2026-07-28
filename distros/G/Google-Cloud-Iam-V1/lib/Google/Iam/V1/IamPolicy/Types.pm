package Google::Iam::V1::IamPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SetIamPolicyRequest',
    as InstanceOf['Google::Iam::V1::IamPolicy::SetIamPolicyRequest'];

coerce 'SetIamPolicyRequest',
    from HashRef, via { 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest'->new($_) };

declare 'RepeatedSetIamPolicyRequest',
    as ArrayRef[SetIamPolicyRequest()];

coerce 'RepeatedSetIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringSetIamPolicyRequest',
    as HashRef[SetIamPolicyRequest()];

declare 'GetIamPolicyRequest',
    as InstanceOf['Google::Iam::V1::IamPolicy::GetIamPolicyRequest'];

coerce 'GetIamPolicyRequest',
    from HashRef, via { 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest'->new($_) };

declare 'RepeatedGetIamPolicyRequest',
    as ArrayRef[GetIamPolicyRequest()];

coerce 'RepeatedGetIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetIamPolicyRequest',
    as HashRef[GetIamPolicyRequest()];

declare 'TestIamPermissionsRequest',
    as InstanceOf['Google::Iam::V1::IamPolicy::TestIamPermissionsRequest'];

coerce 'TestIamPermissionsRequest',
    from HashRef, via { 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest'->new($_) };

declare 'RepeatedTestIamPermissionsRequest',
    as ArrayRef[TestIamPermissionsRequest()];

coerce 'RepeatedTestIamPermissionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest'->new($_) } @$_ ] };

declare 'MapStringTestIamPermissionsRequest',
    as HashRef[TestIamPermissionsRequest()];

declare 'TestIamPermissionsResponse',
    as InstanceOf['Google::Iam::V1::IamPolicy::TestIamPermissionsResponse'];

coerce 'TestIamPermissionsResponse',
    from HashRef, via { 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse'->new($_) };

declare 'RepeatedTestIamPermissionsResponse',
    as ArrayRef[TestIamPermissionsResponse()];

coerce 'RepeatedTestIamPermissionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse'->new($_) } @$_ ] };

declare 'MapStringTestIamPermissionsResponse',
    as HashRef[TestIamPermissionsResponse()];

1;

__END__

=head1 NAME

Google::Iam::V1::IamPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
