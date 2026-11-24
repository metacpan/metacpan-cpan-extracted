package Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AppliedAutoProtectionPolicy',
    as InstanceOf['Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy'];

coerce 'AppliedAutoProtectionPolicy',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy'->new($_) };

declare 'RepeatedAppliedAutoProtectionPolicy',
    as ArrayRef[AppliedAutoProtectionPolicy()];

coerce 'RepeatedAppliedAutoProtectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy'->new($_) } @$_ ] };

declare 'MapStringAppliedAutoProtectionPolicy',
    as HashRef[AppliedAutoProtectionPolicy()];

declare 'State',
    as (Int | Str);

declare 'ListAppliedAutoProtectionPoliciesRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest'];

coerce 'ListAppliedAutoProtectionPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest'->new($_) };

declare 'RepeatedListAppliedAutoProtectionPoliciesRequest',
    as ArrayRef[ListAppliedAutoProtectionPoliciesRequest()];

coerce 'RepeatedListAppliedAutoProtectionPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAppliedAutoProtectionPoliciesRequest',
    as HashRef[ListAppliedAutoProtectionPoliciesRequest()];

declare 'ListAppliedAutoProtectionPoliciesResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse'];

coerce 'ListAppliedAutoProtectionPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse'->new($_) };

declare 'RepeatedListAppliedAutoProtectionPoliciesResponse',
    as ArrayRef[ListAppliedAutoProtectionPoliciesResponse()];

coerce 'RepeatedListAppliedAutoProtectionPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAppliedAutoProtectionPoliciesResponse',
    as HashRef[ListAppliedAutoProtectionPoliciesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::Appliedautoprotectionpolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
