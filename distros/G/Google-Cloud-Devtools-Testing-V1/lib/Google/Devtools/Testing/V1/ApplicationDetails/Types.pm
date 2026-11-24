package Google::Devtools::Testing::V1::ApplicationDetails::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ApkDetail',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail'];

coerce 'ApkDetail',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail'->new($_) };

declare 'RepeatedApkDetail',
    as ArrayRef[ApkDetail()];

coerce 'RepeatedApkDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::ApkDetail'->new($_) } @$_ ] };

declare 'MapStringApkDetail',
    as HashRef[ApkDetail()];

declare 'ApkManifest',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::ApkManifest'];

coerce 'ApkManifest',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::ApkManifest'->new($_) };

declare 'RepeatedApkManifest',
    as ArrayRef[ApkManifest()];

coerce 'RepeatedApkManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::ApkManifest'->new($_) } @$_ ] };

declare 'MapStringApkManifest',
    as HashRef[ApkManifest()];

declare 'UsesPermissionTag',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::UsesPermissionTag'];

coerce 'UsesPermissionTag',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::UsesPermissionTag'->new($_) };

declare 'RepeatedUsesPermissionTag',
    as ArrayRef[UsesPermissionTag()];

coerce 'RepeatedUsesPermissionTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::UsesPermissionTag'->new($_) } @$_ ] };

declare 'MapStringUsesPermissionTag',
    as HashRef[UsesPermissionTag()];

declare 'Service',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'IntentFilter',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter'];

coerce 'IntentFilter',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter'->new($_) };

declare 'RepeatedIntentFilter',
    as ArrayRef[IntentFilter()];

coerce 'RepeatedIntentFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::IntentFilter'->new($_) } @$_ ] };

declare 'MapStringIntentFilter',
    as HashRef[IntentFilter()];

declare 'Metadata',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'UsesFeature',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::UsesFeature'];

coerce 'UsesFeature',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::UsesFeature'->new($_) };

declare 'RepeatedUsesFeature',
    as ArrayRef[UsesFeature()];

coerce 'RepeatedUsesFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::UsesFeature'->new($_) } @$_ ] };

declare 'MapStringUsesFeature',
    as HashRef[UsesFeature()];

declare 'GetApkDetailsRequest',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest'];

coerce 'GetApkDetailsRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest'->new($_) };

declare 'RepeatedGetApkDetailsRequest',
    as ArrayRef[GetApkDetailsRequest()];

coerce 'RepeatedGetApkDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringGetApkDetailsRequest',
    as HashRef[GetApkDetailsRequest()];

declare 'GetApkDetailsResponse',
    as InstanceOf['Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse'];

coerce 'GetApkDetailsResponse',
    from HashRef, via { 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse'->new($_) };

declare 'RepeatedGetApkDetailsResponse',
    as ArrayRef[GetApkDetailsResponse()];

coerce 'RepeatedGetApkDetailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::ApplicationDetails::GetApkDetailsResponse'->new($_) } @$_ ] };

declare 'MapStringGetApkDetailsResponse',
    as HashRef[GetApkDetailsResponse()];

1;

__END__

=head1 NAME

Google::Devtools::Testing::V1::ApplicationDetails::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
