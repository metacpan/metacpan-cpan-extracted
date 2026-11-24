package Google::Cloud::Cloudsecuritycompliance::V1::Config::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListFrameworksRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest'];

coerce 'ListFrameworksRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest'->new($_) };

declare 'RepeatedListFrameworksRequest',
    as ArrayRef[ListFrameworksRequest()];

coerce 'RepeatedListFrameworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksRequest'->new($_) } @$_ ] };

declare 'MapStringListFrameworksRequest',
    as HashRef[ListFrameworksRequest()];

declare 'ListFrameworksResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse'];

coerce 'ListFrameworksResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse'->new($_) };

declare 'RepeatedListFrameworksResponse',
    as ArrayRef[ListFrameworksResponse()];

coerce 'RepeatedListFrameworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListFrameworksResponse'->new($_) } @$_ ] };

declare 'MapStringListFrameworksResponse',
    as HashRef[ListFrameworksResponse()];

declare 'GetFrameworkRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::GetFrameworkRequest'];

coerce 'GetFrameworkRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::GetFrameworkRequest'->new($_) };

declare 'RepeatedGetFrameworkRequest',
    as ArrayRef[GetFrameworkRequest()];

coerce 'RepeatedGetFrameworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::GetFrameworkRequest'->new($_) } @$_ ] };

declare 'MapStringGetFrameworkRequest',
    as HashRef[GetFrameworkRequest()];

declare 'CreateFrameworkRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateFrameworkRequest'];

coerce 'CreateFrameworkRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateFrameworkRequest'->new($_) };

declare 'RepeatedCreateFrameworkRequest',
    as ArrayRef[CreateFrameworkRequest()];

coerce 'RepeatedCreateFrameworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateFrameworkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFrameworkRequest',
    as HashRef[CreateFrameworkRequest()];

declare 'UpdateFrameworkRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateFrameworkRequest'];

coerce 'UpdateFrameworkRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateFrameworkRequest'->new($_) };

declare 'RepeatedUpdateFrameworkRequest',
    as ArrayRef[UpdateFrameworkRequest()];

coerce 'RepeatedUpdateFrameworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateFrameworkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFrameworkRequest',
    as HashRef[UpdateFrameworkRequest()];

declare 'DeleteFrameworkRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteFrameworkRequest'];

coerce 'DeleteFrameworkRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteFrameworkRequest'->new($_) };

declare 'RepeatedDeleteFrameworkRequest',
    as ArrayRef[DeleteFrameworkRequest()];

coerce 'RepeatedDeleteFrameworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteFrameworkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFrameworkRequest',
    as HashRef[DeleteFrameworkRequest()];

declare 'ListCloudControlsRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsRequest'];

coerce 'ListCloudControlsRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsRequest'->new($_) };

declare 'RepeatedListCloudControlsRequest',
    as ArrayRef[ListCloudControlsRequest()];

coerce 'RepeatedListCloudControlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsRequest'->new($_) } @$_ ] };

declare 'MapStringListCloudControlsRequest',
    as HashRef[ListCloudControlsRequest()];

declare 'ListCloudControlsResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsResponse'];

coerce 'ListCloudControlsResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsResponse'->new($_) };

declare 'RepeatedListCloudControlsResponse',
    as ArrayRef[ListCloudControlsResponse()];

coerce 'RepeatedListCloudControlsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::ListCloudControlsResponse'->new($_) } @$_ ] };

declare 'MapStringListCloudControlsResponse',
    as HashRef[ListCloudControlsResponse()];

declare 'GetCloudControlRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::GetCloudControlRequest'];

coerce 'GetCloudControlRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::GetCloudControlRequest'->new($_) };

declare 'RepeatedGetCloudControlRequest',
    as ArrayRef[GetCloudControlRequest()];

coerce 'RepeatedGetCloudControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::GetCloudControlRequest'->new($_) } @$_ ] };

declare 'MapStringGetCloudControlRequest',
    as HashRef[GetCloudControlRequest()];

declare 'CreateCloudControlRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateCloudControlRequest'];

coerce 'CreateCloudControlRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateCloudControlRequest'->new($_) };

declare 'RepeatedCreateCloudControlRequest',
    as ArrayRef[CreateCloudControlRequest()];

coerce 'RepeatedCreateCloudControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::CreateCloudControlRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCloudControlRequest',
    as HashRef[CreateCloudControlRequest()];

declare 'UpdateCloudControlRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateCloudControlRequest'];

coerce 'UpdateCloudControlRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateCloudControlRequest'->new($_) };

declare 'RepeatedUpdateCloudControlRequest',
    as ArrayRef[UpdateCloudControlRequest()];

coerce 'RepeatedUpdateCloudControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::UpdateCloudControlRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudControlRequest',
    as HashRef[UpdateCloudControlRequest()];

declare 'DeleteCloudControlRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteCloudControlRequest'];

coerce 'DeleteCloudControlRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteCloudControlRequest'->new($_) };

declare 'RepeatedDeleteCloudControlRequest',
    as ArrayRef[DeleteCloudControlRequest()];

coerce 'RepeatedDeleteCloudControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Config::DeleteCloudControlRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCloudControlRequest',
    as HashRef[DeleteCloudControlRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::Config::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
