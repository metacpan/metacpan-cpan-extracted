package Google::Cloud::Certificatemanager::V1::TrustConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListTrustConfigsRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest'];

coerce 'ListTrustConfigsRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest'->new($_) };

declare 'RepeatedListTrustConfigsRequest',
    as ArrayRef[ListTrustConfigsRequest()];

coerce 'RepeatedListTrustConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListTrustConfigsRequest',
    as HashRef[ListTrustConfigsRequest()];

declare 'ListTrustConfigsResponse',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsResponse'];

coerce 'ListTrustConfigsResponse',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsResponse'->new($_) };

declare 'RepeatedListTrustConfigsResponse',
    as ArrayRef[ListTrustConfigsResponse()];

coerce 'RepeatedListTrustConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListTrustConfigsResponse',
    as HashRef[ListTrustConfigsResponse()];

declare 'GetTrustConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::GetTrustConfigRequest'];

coerce 'GetTrustConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::GetTrustConfigRequest'->new($_) };

declare 'RepeatedGetTrustConfigRequest',
    as ArrayRef[GetTrustConfigRequest()];

coerce 'RepeatedGetTrustConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::GetTrustConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetTrustConfigRequest',
    as HashRef[GetTrustConfigRequest()];

declare 'CreateTrustConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::CreateTrustConfigRequest'];

coerce 'CreateTrustConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::CreateTrustConfigRequest'->new($_) };

declare 'RepeatedCreateTrustConfigRequest',
    as ArrayRef[CreateTrustConfigRequest()];

coerce 'RepeatedCreateTrustConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::CreateTrustConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTrustConfigRequest',
    as HashRef[CreateTrustConfigRequest()];

declare 'UpdateTrustConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::UpdateTrustConfigRequest'];

coerce 'UpdateTrustConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::UpdateTrustConfigRequest'->new($_) };

declare 'RepeatedUpdateTrustConfigRequest',
    as ArrayRef[UpdateTrustConfigRequest()];

coerce 'RepeatedUpdateTrustConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::UpdateTrustConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTrustConfigRequest',
    as HashRef[UpdateTrustConfigRequest()];

declare 'DeleteTrustConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::DeleteTrustConfigRequest'];

coerce 'DeleteTrustConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::DeleteTrustConfigRequest'->new($_) };

declare 'RepeatedDeleteTrustConfigRequest',
    as ArrayRef[DeleteTrustConfigRequest()];

coerce 'RepeatedDeleteTrustConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::DeleteTrustConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTrustConfigRequest',
    as HashRef[DeleteTrustConfigRequest()];

declare 'TrustConfig',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig'];

coerce 'TrustConfig',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig'->new($_) };

declare 'RepeatedTrustConfig',
    as ArrayRef[TrustConfig()];

coerce 'RepeatedTrustConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig'->new($_) } @$_ ] };

declare 'MapStringTrustConfig',
    as HashRef[TrustConfig()];

declare 'TrustAnchor',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustAnchor'];

coerce 'TrustAnchor',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustAnchor'->new($_) };

declare 'RepeatedTrustAnchor',
    as ArrayRef[TrustAnchor()];

coerce 'RepeatedTrustAnchor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustAnchor'->new($_) } @$_ ] };

declare 'MapStringTrustAnchor',
    as HashRef[TrustAnchor()];

declare 'IntermediateCA',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::IntermediateCA'];

coerce 'IntermediateCA',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::IntermediateCA'->new($_) };

declare 'RepeatedIntermediateCA',
    as ArrayRef[IntermediateCA()];

coerce 'RepeatedIntermediateCA',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::IntermediateCA'->new($_) } @$_ ] };

declare 'MapStringIntermediateCA',
    as HashRef[IntermediateCA()];

declare 'TrustStore',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustStore'];

coerce 'TrustStore',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustStore'->new($_) };

declare 'RepeatedTrustStore',
    as ArrayRef[TrustStore()];

coerce 'RepeatedTrustStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustStore'->new($_) } @$_ ] };

declare 'MapStringTrustStore',
    as HashRef[TrustStore()];

declare 'AllowlistedCertificate',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::AllowlistedCertificate'];

coerce 'AllowlistedCertificate',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::AllowlistedCertificate'->new($_) };

declare 'RepeatedAllowlistedCertificate',
    as ArrayRef[AllowlistedCertificate()];

coerce 'RepeatedAllowlistedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::AllowlistedCertificate'->new($_) } @$_ ] };

declare 'MapStringAllowlistedCertificate',
    as HashRef[AllowlistedCertificate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SpiffeTrustStoresEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::SpiffeTrustStoresEntry'];

coerce 'SpiffeTrustStoresEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::SpiffeTrustStoresEntry'->new($_) };

declare 'RepeatedSpiffeTrustStoresEntry',
    as ArrayRef[SpiffeTrustStoresEntry()];

coerce 'RepeatedSpiffeTrustStoresEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::SpiffeTrustStoresEntry'->new($_) } @$_ ] };

declare 'MapStringSpiffeTrustStoresEntry',
    as HashRef[SpiffeTrustStoresEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Certificatemanager::V1::TrustConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
