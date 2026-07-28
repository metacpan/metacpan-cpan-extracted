package Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListImageVersionsRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest'];

coerce 'ListImageVersionsRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest'->new($_) };

declare 'RepeatedListImageVersionsRequest',
    as ArrayRef[ListImageVersionsRequest()];

coerce 'RepeatedListImageVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListImageVersionsRequest',
    as HashRef[ListImageVersionsRequest()];

declare 'ListImageVersionsResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse'];

coerce 'ListImageVersionsResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse'->new($_) };

declare 'RepeatedListImageVersionsResponse',
    as ArrayRef[ListImageVersionsResponse()];

coerce 'RepeatedListImageVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListImageVersionsResponse',
    as HashRef[ListImageVersionsResponse()];

declare 'ImageVersion',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersion'];

coerce 'ImageVersion',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersion'->new($_) };

declare 'RepeatedImageVersion',
    as ArrayRef[ImageVersion()];

coerce 'RepeatedImageVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersion'->new($_) } @$_ ] };

declare 'MapStringImageVersion',
    as HashRef[ImageVersion()];

1;

__END__

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
