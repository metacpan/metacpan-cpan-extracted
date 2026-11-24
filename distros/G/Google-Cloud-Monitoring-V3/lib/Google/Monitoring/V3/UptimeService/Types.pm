package Google::Monitoring::V3::UptimeService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListUptimeCheckConfigsRequest',
    as InstanceOf['Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest'];

coerce 'ListUptimeCheckConfigsRequest',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest'->new($_) };

declare 'RepeatedListUptimeCheckConfigsRequest',
    as ArrayRef[ListUptimeCheckConfigsRequest()];

coerce 'RepeatedListUptimeCheckConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListUptimeCheckConfigsRequest',
    as HashRef[ListUptimeCheckConfigsRequest()];

declare 'ListUptimeCheckConfigsResponse',
    as InstanceOf['Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse'];

coerce 'ListUptimeCheckConfigsResponse',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse'->new($_) };

declare 'RepeatedListUptimeCheckConfigsResponse',
    as ArrayRef[ListUptimeCheckConfigsResponse()];

coerce 'RepeatedListUptimeCheckConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListUptimeCheckConfigsResponse',
    as HashRef[ListUptimeCheckConfigsResponse()];

declare 'GetUptimeCheckConfigRequest',
    as InstanceOf['Google::Monitoring::V3::UptimeService::GetUptimeCheckConfigRequest'];

coerce 'GetUptimeCheckConfigRequest',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::GetUptimeCheckConfigRequest'->new($_) };

declare 'RepeatedGetUptimeCheckConfigRequest',
    as ArrayRef[GetUptimeCheckConfigRequest()];

coerce 'RepeatedGetUptimeCheckConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::GetUptimeCheckConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetUptimeCheckConfigRequest',
    as HashRef[GetUptimeCheckConfigRequest()];

declare 'CreateUptimeCheckConfigRequest',
    as InstanceOf['Google::Monitoring::V3::UptimeService::CreateUptimeCheckConfigRequest'];

coerce 'CreateUptimeCheckConfigRequest',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::CreateUptimeCheckConfigRequest'->new($_) };

declare 'RepeatedCreateUptimeCheckConfigRequest',
    as ArrayRef[CreateUptimeCheckConfigRequest()];

coerce 'RepeatedCreateUptimeCheckConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::CreateUptimeCheckConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUptimeCheckConfigRequest',
    as HashRef[CreateUptimeCheckConfigRequest()];

declare 'UpdateUptimeCheckConfigRequest',
    as InstanceOf['Google::Monitoring::V3::UptimeService::UpdateUptimeCheckConfigRequest'];

coerce 'UpdateUptimeCheckConfigRequest',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::UpdateUptimeCheckConfigRequest'->new($_) };

declare 'RepeatedUpdateUptimeCheckConfigRequest',
    as ArrayRef[UpdateUptimeCheckConfigRequest()];

coerce 'RepeatedUpdateUptimeCheckConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::UpdateUptimeCheckConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUptimeCheckConfigRequest',
    as HashRef[UpdateUptimeCheckConfigRequest()];

declare 'DeleteUptimeCheckConfigRequest',
    as InstanceOf['Google::Monitoring::V3::UptimeService::DeleteUptimeCheckConfigRequest'];

coerce 'DeleteUptimeCheckConfigRequest',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::DeleteUptimeCheckConfigRequest'->new($_) };

declare 'RepeatedDeleteUptimeCheckConfigRequest',
    as ArrayRef[DeleteUptimeCheckConfigRequest()];

coerce 'RepeatedDeleteUptimeCheckConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::DeleteUptimeCheckConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUptimeCheckConfigRequest',
    as HashRef[DeleteUptimeCheckConfigRequest()];

declare 'ListUptimeCheckIpsRequest',
    as InstanceOf['Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest'];

coerce 'ListUptimeCheckIpsRequest',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest'->new($_) };

declare 'RepeatedListUptimeCheckIpsRequest',
    as ArrayRef[ListUptimeCheckIpsRequest()];

coerce 'RepeatedListUptimeCheckIpsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest'->new($_) } @$_ ] };

declare 'MapStringListUptimeCheckIpsRequest',
    as HashRef[ListUptimeCheckIpsRequest()];

declare 'ListUptimeCheckIpsResponse',
    as InstanceOf['Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse'];

coerce 'ListUptimeCheckIpsResponse',
    from HashRef, via { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse'->new($_) };

declare 'RepeatedListUptimeCheckIpsResponse',
    as ArrayRef[ListUptimeCheckIpsResponse()];

coerce 'RepeatedListUptimeCheckIpsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse'->new($_) } @$_ ] };

declare 'MapStringListUptimeCheckIpsResponse',
    as HashRef[ListUptimeCheckIpsResponse()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::UptimeService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
