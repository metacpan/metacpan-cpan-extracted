package Google::Cloud::Lustre::V1::DirectoryPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DirectoryPolicy',
    as InstanceOf['Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy'];

coerce 'DirectoryPolicy',
    from HashRef, via { 'Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy'->new($_) };

declare 'RepeatedDirectoryPolicy',
    as ArrayRef[DirectoryPolicy()];

coerce 'RepeatedDirectoryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy'->new($_) } @$_ ] };

declare 'MapStringDirectoryPolicy',
    as HashRef[DirectoryPolicy()];

declare 'State',
    as (Int | Str);

declare 'CreateDirectoryPolicyRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::DirectoryPolicy::CreateDirectoryPolicyRequest'];

coerce 'CreateDirectoryPolicyRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::DirectoryPolicy::CreateDirectoryPolicyRequest'->new($_) };

declare 'RepeatedCreateDirectoryPolicyRequest',
    as ArrayRef[CreateDirectoryPolicyRequest()];

coerce 'RepeatedCreateDirectoryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::DirectoryPolicy::CreateDirectoryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDirectoryPolicyRequest',
    as HashRef[CreateDirectoryPolicyRequest()];

declare 'DeleteDirectoryPolicyRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::DirectoryPolicy::DeleteDirectoryPolicyRequest'];

coerce 'DeleteDirectoryPolicyRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::DirectoryPolicy::DeleteDirectoryPolicyRequest'->new($_) };

declare 'RepeatedDeleteDirectoryPolicyRequest',
    as ArrayRef[DeleteDirectoryPolicyRequest()];

coerce 'RepeatedDeleteDirectoryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::DirectoryPolicy::DeleteDirectoryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDirectoryPolicyRequest',
    as HashRef[DeleteDirectoryPolicyRequest()];

declare 'GetDirectoryPolicyRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::DirectoryPolicy::GetDirectoryPolicyRequest'];

coerce 'GetDirectoryPolicyRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::DirectoryPolicy::GetDirectoryPolicyRequest'->new($_) };

declare 'RepeatedGetDirectoryPolicyRequest',
    as ArrayRef[GetDirectoryPolicyRequest()];

coerce 'RepeatedGetDirectoryPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::DirectoryPolicy::GetDirectoryPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetDirectoryPolicyRequest',
    as HashRef[GetDirectoryPolicyRequest()];

declare 'ListDirectoryPoliciesRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesRequest'];

coerce 'ListDirectoryPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesRequest'->new($_) };

declare 'RepeatedListDirectoryPoliciesRequest',
    as ArrayRef[ListDirectoryPoliciesRequest()];

coerce 'RepeatedListDirectoryPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListDirectoryPoliciesRequest',
    as HashRef[ListDirectoryPoliciesRequest()];

declare 'ListDirectoryPoliciesResponse',
    as InstanceOf['Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesResponse'];

coerce 'ListDirectoryPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesResponse'->new($_) };

declare 'RepeatedListDirectoryPoliciesResponse',
    as ArrayRef[ListDirectoryPoliciesResponse()];

coerce 'RepeatedListDirectoryPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListDirectoryPoliciesResponse',
    as HashRef[ListDirectoryPoliciesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Lustre::V1::DirectoryPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
