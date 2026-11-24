package Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EstimateDataSizeRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest'];

coerce 'EstimateDataSizeRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest'->new($_) };

declare 'RepeatedEstimateDataSizeRequest',
    as ArrayRef[EstimateDataSizeRequest()];

coerce 'RepeatedEstimateDataSizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest'->new($_) } @$_ ] };

declare 'MapStringEstimateDataSizeRequest',
    as HashRef[EstimateDataSizeRequest()];

declare 'WebsiteDataSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource'];

coerce 'WebsiteDataSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource'->new($_) };

declare 'RepeatedWebsiteDataSource',
    as ArrayRef[WebsiteDataSource()];

coerce 'RepeatedWebsiteDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource'->new($_) } @$_ ] };

declare 'MapStringWebsiteDataSource',
    as HashRef[WebsiteDataSource()];

declare 'EstimatorUriPattern',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource::EstimatorUriPattern'];

coerce 'EstimatorUriPattern',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource::EstimatorUriPattern'->new($_) };

declare 'RepeatedEstimatorUriPattern',
    as ArrayRef[EstimatorUriPattern()];

coerce 'RepeatedEstimatorUriPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::WebsiteDataSource::EstimatorUriPattern'->new($_) } @$_ ] };

declare 'MapStringEstimatorUriPattern',
    as HashRef[EstimatorUriPattern()];

declare 'FileDataSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::FileDataSource'];

coerce 'FileDataSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::FileDataSource'->new($_) };

declare 'RepeatedFileDataSource',
    as ArrayRef[FileDataSource()];

coerce 'RepeatedFileDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest::FileDataSource'->new($_) } @$_ ] };

declare 'MapStringFileDataSource',
    as HashRef[FileDataSource()];

declare 'EstimateDataSizeResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeResponse'];

coerce 'EstimateDataSizeResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeResponse'->new($_) };

declare 'RepeatedEstimateDataSizeResponse',
    as ArrayRef[EstimateDataSizeResponse()];

coerce 'RepeatedEstimateDataSizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeResponse'->new($_) } @$_ ] };

declare 'MapStringEstimateDataSizeResponse',
    as HashRef[EstimateDataSizeResponse()];

declare 'EstimateDataSizeMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeMetadata'];

coerce 'EstimateDataSizeMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeMetadata'->new($_) };

declare 'RepeatedEstimateDataSizeMetadata',
    as ArrayRef[EstimateDataSizeMetadata()];

coerce 'RepeatedEstimateDataSizeMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeMetadata'->new($_) } @$_ ] };

declare 'MapStringEstimateDataSizeMetadata',
    as HashRef[EstimateDataSizeMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
