package Google::Monitoring::V3::AlertService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateAlertPolicyRequest',
    as InstanceOf['Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest'];

coerce 'CreateAlertPolicyRequest',
    from HashRef, via { 'Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest'->new($_) };

declare 'RepeatedCreateAlertPolicyRequest',
    as ArrayRef[CreateAlertPolicyRequest()];

coerce 'RepeatedCreateAlertPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::AlertService::CreateAlertPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAlertPolicyRequest',
    as HashRef[CreateAlertPolicyRequest()];

declare 'GetAlertPolicyRequest',
    as InstanceOf['Google::Monitoring::V3::AlertService::GetAlertPolicyRequest'];

coerce 'GetAlertPolicyRequest',
    from HashRef, via { 'Google::Monitoring::V3::AlertService::GetAlertPolicyRequest'->new($_) };

declare 'RepeatedGetAlertPolicyRequest',
    as ArrayRef[GetAlertPolicyRequest()];

coerce 'RepeatedGetAlertPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::AlertService::GetAlertPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAlertPolicyRequest',
    as HashRef[GetAlertPolicyRequest()];

declare 'ListAlertPoliciesRequest',
    as InstanceOf['Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest'];

coerce 'ListAlertPoliciesRequest',
    from HashRef, via { 'Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest'->new($_) };

declare 'RepeatedListAlertPoliciesRequest',
    as ArrayRef[ListAlertPoliciesRequest()];

coerce 'RepeatedListAlertPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAlertPoliciesRequest',
    as HashRef[ListAlertPoliciesRequest()];

declare 'ListAlertPoliciesResponse',
    as InstanceOf['Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse'];

coerce 'ListAlertPoliciesResponse',
    from HashRef, via { 'Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse'->new($_) };

declare 'RepeatedListAlertPoliciesResponse',
    as ArrayRef[ListAlertPoliciesResponse()];

coerce 'RepeatedListAlertPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAlertPoliciesResponse',
    as HashRef[ListAlertPoliciesResponse()];

declare 'UpdateAlertPolicyRequest',
    as InstanceOf['Google::Monitoring::V3::AlertService::UpdateAlertPolicyRequest'];

coerce 'UpdateAlertPolicyRequest',
    from HashRef, via { 'Google::Monitoring::V3::AlertService::UpdateAlertPolicyRequest'->new($_) };

declare 'RepeatedUpdateAlertPolicyRequest',
    as ArrayRef[UpdateAlertPolicyRequest()];

coerce 'RepeatedUpdateAlertPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::AlertService::UpdateAlertPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAlertPolicyRequest',
    as HashRef[UpdateAlertPolicyRequest()];

declare 'DeleteAlertPolicyRequest',
    as InstanceOf['Google::Monitoring::V3::AlertService::DeleteAlertPolicyRequest'];

coerce 'DeleteAlertPolicyRequest',
    from HashRef, via { 'Google::Monitoring::V3::AlertService::DeleteAlertPolicyRequest'->new($_) };

declare 'RepeatedDeleteAlertPolicyRequest',
    as ArrayRef[DeleteAlertPolicyRequest()];

coerce 'RepeatedDeleteAlertPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::AlertService::DeleteAlertPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAlertPolicyRequest',
    as HashRef[DeleteAlertPolicyRequest()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::AlertService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
