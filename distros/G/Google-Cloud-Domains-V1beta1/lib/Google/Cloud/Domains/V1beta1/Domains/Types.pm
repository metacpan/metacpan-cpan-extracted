package Google::Cloud::Domains::V1beta1::Domains::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ContactPrivacy',
    as (Int | Str);

declare 'DomainNotice',
    as (Int | Str);

declare 'ContactNotice',
    as (Int | Str);

declare 'TransferLockState',
    as (Int | Str);

declare 'Registration',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::Registration'];

coerce 'Registration',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::Registration'->new($_) };

declare 'RepeatedRegistration',
    as ArrayRef[Registration()];

coerce 'RepeatedRegistration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::Registration'->new($_) } @$_ ] };

declare 'MapStringRegistration',
    as HashRef[Registration()];

declare 'State',
    as (Int | Str);

declare 'Issue',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::Registration::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::Registration::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::Registration::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ManagementSettings',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ManagementSettings'];

coerce 'ManagementSettings',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ManagementSettings'->new($_) };

declare 'RepeatedManagementSettings',
    as ArrayRef[ManagementSettings()];

coerce 'RepeatedManagementSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ManagementSettings'->new($_) } @$_ ] };

declare 'MapStringManagementSettings',
    as HashRef[ManagementSettings()];

declare 'RenewalMethod',
    as (Int | Str);

declare 'DnsSettings',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::DnsSettings'];

coerce 'DnsSettings',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings'->new($_) };

declare 'RepeatedDnsSettings',
    as ArrayRef[DnsSettings()];

coerce 'RepeatedDnsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings'->new($_) } @$_ ] };

declare 'MapStringDnsSettings',
    as HashRef[DnsSettings()];

declare 'DsState',
    as (Int | Str);

declare 'CustomDns',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::DnsSettings::CustomDns'];

coerce 'CustomDns',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::CustomDns'->new($_) };

declare 'RepeatedCustomDns',
    as ArrayRef[CustomDns()];

coerce 'RepeatedCustomDns',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::CustomDns'->new($_) } @$_ ] };

declare 'MapStringCustomDns',
    as HashRef[CustomDns()];

declare 'GoogleDomainsDns',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::DnsSettings::GoogleDomainsDns'];

coerce 'GoogleDomainsDns',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::GoogleDomainsDns'->new($_) };

declare 'RepeatedGoogleDomainsDns',
    as ArrayRef[GoogleDomainsDns()];

coerce 'RepeatedGoogleDomainsDns',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::GoogleDomainsDns'->new($_) } @$_ ] };

declare 'MapStringGoogleDomainsDns',
    as HashRef[GoogleDomainsDns()];

declare 'DsRecord',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::DnsSettings::DsRecord'];

coerce 'DsRecord',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::DsRecord'->new($_) };

declare 'RepeatedDsRecord',
    as ArrayRef[DsRecord()];

coerce 'RepeatedDsRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::DsRecord'->new($_) } @$_ ] };

declare 'MapStringDsRecord',
    as HashRef[DsRecord()];

declare 'Algorithm',
    as (Int | Str);

declare 'DigestType',
    as (Int | Str);

declare 'GlueRecord',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::DnsSettings::GlueRecord'];

coerce 'GlueRecord',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::GlueRecord'->new($_) };

declare 'RepeatedGlueRecord',
    as ArrayRef[GlueRecord()];

coerce 'RepeatedGlueRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::DnsSettings::GlueRecord'->new($_) } @$_ ] };

declare 'MapStringGlueRecord',
    as HashRef[GlueRecord()];

declare 'ContactSettings',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ContactSettings'];

coerce 'ContactSettings',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ContactSettings'->new($_) };

declare 'RepeatedContactSettings',
    as ArrayRef[ContactSettings()];

coerce 'RepeatedContactSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ContactSettings'->new($_) } @$_ ] };

declare 'MapStringContactSettings',
    as HashRef[ContactSettings()];

declare 'Contact',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ContactSettings::Contact'];

coerce 'Contact',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ContactSettings::Contact'->new($_) };

declare 'RepeatedContact',
    as ArrayRef[Contact()];

coerce 'RepeatedContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ContactSettings::Contact'->new($_) } @$_ ] };

declare 'MapStringContact',
    as HashRef[Contact()];

declare 'SearchDomainsRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::SearchDomainsRequest'];

coerce 'SearchDomainsRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::SearchDomainsRequest'->new($_) };

declare 'RepeatedSearchDomainsRequest',
    as ArrayRef[SearchDomainsRequest()];

coerce 'RepeatedSearchDomainsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::SearchDomainsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchDomainsRequest',
    as HashRef[SearchDomainsRequest()];

declare 'SearchDomainsResponse',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::SearchDomainsResponse'];

coerce 'SearchDomainsResponse',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::SearchDomainsResponse'->new($_) };

declare 'RepeatedSearchDomainsResponse',
    as ArrayRef[SearchDomainsResponse()];

coerce 'RepeatedSearchDomainsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::SearchDomainsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchDomainsResponse',
    as HashRef[SearchDomainsResponse()];

declare 'RetrieveRegisterParametersRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RetrieveRegisterParametersRequest'];

coerce 'RetrieveRegisterParametersRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveRegisterParametersRequest'->new($_) };

declare 'RepeatedRetrieveRegisterParametersRequest',
    as ArrayRef[RetrieveRegisterParametersRequest()];

coerce 'RepeatedRetrieveRegisterParametersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveRegisterParametersRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveRegisterParametersRequest',
    as HashRef[RetrieveRegisterParametersRequest()];

declare 'RetrieveRegisterParametersResponse',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RetrieveRegisterParametersResponse'];

coerce 'RetrieveRegisterParametersResponse',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveRegisterParametersResponse'->new($_) };

declare 'RepeatedRetrieveRegisterParametersResponse',
    as ArrayRef[RetrieveRegisterParametersResponse()];

coerce 'RepeatedRetrieveRegisterParametersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveRegisterParametersResponse'->new($_) } @$_ ] };

declare 'MapStringRetrieveRegisterParametersResponse',
    as HashRef[RetrieveRegisterParametersResponse()];

declare 'RegisterDomainRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RegisterDomainRequest'];

coerce 'RegisterDomainRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RegisterDomainRequest'->new($_) };

declare 'RepeatedRegisterDomainRequest',
    as ArrayRef[RegisterDomainRequest()];

coerce 'RepeatedRegisterDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RegisterDomainRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterDomainRequest',
    as HashRef[RegisterDomainRequest()];

declare 'RetrieveTransferParametersRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RetrieveTransferParametersRequest'];

coerce 'RetrieveTransferParametersRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveTransferParametersRequest'->new($_) };

declare 'RepeatedRetrieveTransferParametersRequest',
    as ArrayRef[RetrieveTransferParametersRequest()];

coerce 'RepeatedRetrieveTransferParametersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveTransferParametersRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveTransferParametersRequest',
    as HashRef[RetrieveTransferParametersRequest()];

declare 'RetrieveTransferParametersResponse',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RetrieveTransferParametersResponse'];

coerce 'RetrieveTransferParametersResponse',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveTransferParametersResponse'->new($_) };

declare 'RepeatedRetrieveTransferParametersResponse',
    as ArrayRef[RetrieveTransferParametersResponse()];

coerce 'RepeatedRetrieveTransferParametersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveTransferParametersResponse'->new($_) } @$_ ] };

declare 'MapStringRetrieveTransferParametersResponse',
    as HashRef[RetrieveTransferParametersResponse()];

declare 'TransferDomainRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::TransferDomainRequest'];

coerce 'TransferDomainRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::TransferDomainRequest'->new($_) };

declare 'RepeatedTransferDomainRequest',
    as ArrayRef[TransferDomainRequest()];

coerce 'RepeatedTransferDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::TransferDomainRequest'->new($_) } @$_ ] };

declare 'MapStringTransferDomainRequest',
    as HashRef[TransferDomainRequest()];

declare 'ListRegistrationsRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ListRegistrationsRequest'];

coerce 'ListRegistrationsRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ListRegistrationsRequest'->new($_) };

declare 'RepeatedListRegistrationsRequest',
    as ArrayRef[ListRegistrationsRequest()];

coerce 'RepeatedListRegistrationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ListRegistrationsRequest'->new($_) } @$_ ] };

declare 'MapStringListRegistrationsRequest',
    as HashRef[ListRegistrationsRequest()];

declare 'ListRegistrationsResponse',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ListRegistrationsResponse'];

coerce 'ListRegistrationsResponse',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ListRegistrationsResponse'->new($_) };

declare 'RepeatedListRegistrationsResponse',
    as ArrayRef[ListRegistrationsResponse()];

coerce 'RepeatedListRegistrationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ListRegistrationsResponse'->new($_) } @$_ ] };

declare 'MapStringListRegistrationsResponse',
    as HashRef[ListRegistrationsResponse()];

declare 'GetRegistrationRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::GetRegistrationRequest'];

coerce 'GetRegistrationRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::GetRegistrationRequest'->new($_) };

declare 'RepeatedGetRegistrationRequest',
    as ArrayRef[GetRegistrationRequest()];

coerce 'RepeatedGetRegistrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::GetRegistrationRequest'->new($_) } @$_ ] };

declare 'MapStringGetRegistrationRequest',
    as HashRef[GetRegistrationRequest()];

declare 'UpdateRegistrationRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::UpdateRegistrationRequest'];

coerce 'UpdateRegistrationRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::UpdateRegistrationRequest'->new($_) };

declare 'RepeatedUpdateRegistrationRequest',
    as ArrayRef[UpdateRegistrationRequest()];

coerce 'RepeatedUpdateRegistrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::UpdateRegistrationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRegistrationRequest',
    as HashRef[UpdateRegistrationRequest()];

declare 'ConfigureManagementSettingsRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ConfigureManagementSettingsRequest'];

coerce 'ConfigureManagementSettingsRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ConfigureManagementSettingsRequest'->new($_) };

declare 'RepeatedConfigureManagementSettingsRequest',
    as ArrayRef[ConfigureManagementSettingsRequest()];

coerce 'RepeatedConfigureManagementSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ConfigureManagementSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringConfigureManagementSettingsRequest',
    as HashRef[ConfigureManagementSettingsRequest()];

declare 'ConfigureDnsSettingsRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ConfigureDnsSettingsRequest'];

coerce 'ConfigureDnsSettingsRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ConfigureDnsSettingsRequest'->new($_) };

declare 'RepeatedConfigureDnsSettingsRequest',
    as ArrayRef[ConfigureDnsSettingsRequest()];

coerce 'RepeatedConfigureDnsSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ConfigureDnsSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringConfigureDnsSettingsRequest',
    as HashRef[ConfigureDnsSettingsRequest()];

declare 'ConfigureContactSettingsRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ConfigureContactSettingsRequest'];

coerce 'ConfigureContactSettingsRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ConfigureContactSettingsRequest'->new($_) };

declare 'RepeatedConfigureContactSettingsRequest',
    as ArrayRef[ConfigureContactSettingsRequest()];

coerce 'RepeatedConfigureContactSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ConfigureContactSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringConfigureContactSettingsRequest',
    as HashRef[ConfigureContactSettingsRequest()];

declare 'ExportRegistrationRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ExportRegistrationRequest'];

coerce 'ExportRegistrationRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ExportRegistrationRequest'->new($_) };

declare 'RepeatedExportRegistrationRequest',
    as ArrayRef[ExportRegistrationRequest()];

coerce 'RepeatedExportRegistrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ExportRegistrationRequest'->new($_) } @$_ ] };

declare 'MapStringExportRegistrationRequest',
    as HashRef[ExportRegistrationRequest()];

declare 'DeleteRegistrationRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::DeleteRegistrationRequest'];

coerce 'DeleteRegistrationRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::DeleteRegistrationRequest'->new($_) };

declare 'RepeatedDeleteRegistrationRequest',
    as ArrayRef[DeleteRegistrationRequest()];

coerce 'RepeatedDeleteRegistrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::DeleteRegistrationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRegistrationRequest',
    as HashRef[DeleteRegistrationRequest()];

declare 'RetrieveAuthorizationCodeRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RetrieveAuthorizationCodeRequest'];

coerce 'RetrieveAuthorizationCodeRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveAuthorizationCodeRequest'->new($_) };

declare 'RepeatedRetrieveAuthorizationCodeRequest',
    as ArrayRef[RetrieveAuthorizationCodeRequest()];

coerce 'RepeatedRetrieveAuthorizationCodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RetrieveAuthorizationCodeRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveAuthorizationCodeRequest',
    as HashRef[RetrieveAuthorizationCodeRequest()];

declare 'ResetAuthorizationCodeRequest',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::ResetAuthorizationCodeRequest'];

coerce 'ResetAuthorizationCodeRequest',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::ResetAuthorizationCodeRequest'->new($_) };

declare 'RepeatedResetAuthorizationCodeRequest',
    as ArrayRef[ResetAuthorizationCodeRequest()];

coerce 'RepeatedResetAuthorizationCodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::ResetAuthorizationCodeRequest'->new($_) } @$_ ] };

declare 'MapStringResetAuthorizationCodeRequest',
    as HashRef[ResetAuthorizationCodeRequest()];

declare 'RegisterParameters',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::RegisterParameters'];

coerce 'RegisterParameters',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::RegisterParameters'->new($_) };

declare 'RepeatedRegisterParameters',
    as ArrayRef[RegisterParameters()];

coerce 'RepeatedRegisterParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::RegisterParameters'->new($_) } @$_ ] };

declare 'MapStringRegisterParameters',
    as HashRef[RegisterParameters()];

declare 'Availability',
    as (Int | Str);

declare 'TransferParameters',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::TransferParameters'];

coerce 'TransferParameters',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::TransferParameters'->new($_) };

declare 'RepeatedTransferParameters',
    as ArrayRef[TransferParameters()];

coerce 'RepeatedTransferParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::TransferParameters'->new($_) } @$_ ] };

declare 'MapStringTransferParameters',
    as HashRef[TransferParameters()];

declare 'AuthorizationCode',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::AuthorizationCode'];

coerce 'AuthorizationCode',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::AuthorizationCode'->new($_) };

declare 'RepeatedAuthorizationCode',
    as ArrayRef[AuthorizationCode()];

coerce 'RepeatedAuthorizationCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::AuthorizationCode'->new($_) } @$_ ] };

declare 'MapStringAuthorizationCode',
    as HashRef[AuthorizationCode()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Domains::V1beta1::Domains::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Domains::V1beta1::Domains::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Domains::V1beta1::Domains::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Domains::V1beta1::Domains::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
