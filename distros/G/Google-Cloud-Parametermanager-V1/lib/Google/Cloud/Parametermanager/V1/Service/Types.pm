package Google::Cloud::Parametermanager::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ParameterFormat',
    as (Int | Str);

declare 'TemplateFormat',
    as (Int | Str);

declare 'View',
    as (Int | Str);

declare 'Parameter',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::Parameter::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::Parameter::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::Parameter::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::Parameter::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::Parameter::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::Parameter::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'ListParametersRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListParametersRequest'];

coerce 'ListParametersRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListParametersRequest'->new($_) };

declare 'RepeatedListParametersRequest',
    as ArrayRef[ListParametersRequest()];

coerce 'RepeatedListParametersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListParametersRequest'->new($_) } @$_ ] };

declare 'MapStringListParametersRequest',
    as HashRef[ListParametersRequest()];

declare 'ListParametersResponse',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListParametersResponse'];

coerce 'ListParametersResponse',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListParametersResponse'->new($_) };

declare 'RepeatedListParametersResponse',
    as ArrayRef[ListParametersResponse()];

coerce 'RepeatedListParametersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListParametersResponse'->new($_) } @$_ ] };

declare 'MapStringListParametersResponse',
    as HashRef[ListParametersResponse()];

declare 'GetParameterRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::GetParameterRequest'];

coerce 'GetParameterRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::GetParameterRequest'->new($_) };

declare 'RepeatedGetParameterRequest',
    as ArrayRef[GetParameterRequest()];

coerce 'RepeatedGetParameterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::GetParameterRequest'->new($_) } @$_ ] };

declare 'MapStringGetParameterRequest',
    as HashRef[GetParameterRequest()];

declare 'CreateParameterRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::CreateParameterRequest'];

coerce 'CreateParameterRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::CreateParameterRequest'->new($_) };

declare 'RepeatedCreateParameterRequest',
    as ArrayRef[CreateParameterRequest()];

coerce 'RepeatedCreateParameterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::CreateParameterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateParameterRequest',
    as HashRef[CreateParameterRequest()];

declare 'UpdateParameterRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::UpdateParameterRequest'];

coerce 'UpdateParameterRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::UpdateParameterRequest'->new($_) };

declare 'RepeatedUpdateParameterRequest',
    as ArrayRef[UpdateParameterRequest()];

coerce 'RepeatedUpdateParameterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::UpdateParameterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateParameterRequest',
    as HashRef[UpdateParameterRequest()];

declare 'DeleteParameterRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::DeleteParameterRequest'];

coerce 'DeleteParameterRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::DeleteParameterRequest'->new($_) };

declare 'RepeatedDeleteParameterRequest',
    as ArrayRef[DeleteParameterRequest()];

coerce 'RepeatedDeleteParameterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::DeleteParameterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteParameterRequest',
    as HashRef[DeleteParameterRequest()];

declare 'ParameterVersion',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ParameterVersion'];

coerce 'ParameterVersion',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ParameterVersion'->new($_) };

declare 'RepeatedParameterVersion',
    as ArrayRef[ParameterVersion()];

coerce 'RepeatedParameterVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ParameterVersion'->new($_) } @$_ ] };

declare 'MapStringParameterVersion',
    as HashRef[ParameterVersion()];

declare 'ChecksumSource',
    as (Int | Str);

declare 'ParameterVersionPayload',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ParameterVersionPayload'];

coerce 'ParameterVersionPayload',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ParameterVersionPayload'->new($_) };

declare 'RepeatedParameterVersionPayload',
    as ArrayRef[ParameterVersionPayload()];

coerce 'RepeatedParameterVersionPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ParameterVersionPayload'->new($_) } @$_ ] };

declare 'MapStringParameterVersionPayload',
    as HashRef[ParameterVersionPayload()];

declare 'ListParameterVersionsRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListParameterVersionsRequest'];

coerce 'ListParameterVersionsRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListParameterVersionsRequest'->new($_) };

declare 'RepeatedListParameterVersionsRequest',
    as ArrayRef[ListParameterVersionsRequest()];

coerce 'RepeatedListParameterVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListParameterVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListParameterVersionsRequest',
    as HashRef[ListParameterVersionsRequest()];

declare 'ListParameterVersionsResponse',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListParameterVersionsResponse'];

coerce 'ListParameterVersionsResponse',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListParameterVersionsResponse'->new($_) };

declare 'RepeatedListParameterVersionsResponse',
    as ArrayRef[ListParameterVersionsResponse()];

coerce 'RepeatedListParameterVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListParameterVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListParameterVersionsResponse',
    as HashRef[ListParameterVersionsResponse()];

declare 'GetParameterVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::GetParameterVersionRequest'];

coerce 'GetParameterVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::GetParameterVersionRequest'->new($_) };

declare 'RepeatedGetParameterVersionRequest',
    as ArrayRef[GetParameterVersionRequest()];

coerce 'RepeatedGetParameterVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::GetParameterVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetParameterVersionRequest',
    as HashRef[GetParameterVersionRequest()];

declare 'RenderParameterVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::RenderParameterVersionRequest'];

coerce 'RenderParameterVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::RenderParameterVersionRequest'->new($_) };

declare 'RepeatedRenderParameterVersionRequest',
    as ArrayRef[RenderParameterVersionRequest()];

coerce 'RepeatedRenderParameterVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::RenderParameterVersionRequest'->new($_) } @$_ ] };

declare 'MapStringRenderParameterVersionRequest',
    as HashRef[RenderParameterVersionRequest()];

declare 'RenderParameterVersionResponse',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::RenderParameterVersionResponse'];

coerce 'RenderParameterVersionResponse',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::RenderParameterVersionResponse'->new($_) };

declare 'RepeatedRenderParameterVersionResponse',
    as ArrayRef[RenderParameterVersionResponse()];

coerce 'RepeatedRenderParameterVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::RenderParameterVersionResponse'->new($_) } @$_ ] };

declare 'MapStringRenderParameterVersionResponse',
    as HashRef[RenderParameterVersionResponse()];

declare 'CreateParameterVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::CreateParameterVersionRequest'];

coerce 'CreateParameterVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::CreateParameterVersionRequest'->new($_) };

declare 'RepeatedCreateParameterVersionRequest',
    as ArrayRef[CreateParameterVersionRequest()];

coerce 'RepeatedCreateParameterVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::CreateParameterVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateParameterVersionRequest',
    as HashRef[CreateParameterVersionRequest()];

declare 'UpdateParameterVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::UpdateParameterVersionRequest'];

coerce 'UpdateParameterVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::UpdateParameterVersionRequest'->new($_) };

declare 'RepeatedUpdateParameterVersionRequest',
    as ArrayRef[UpdateParameterVersionRequest()];

coerce 'RepeatedUpdateParameterVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::UpdateParameterVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateParameterVersionRequest',
    as HashRef[UpdateParameterVersionRequest()];

declare 'DeleteParameterVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::DeleteParameterVersionRequest'];

coerce 'DeleteParameterVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::DeleteParameterVersionRequest'->new($_) };

declare 'RepeatedDeleteParameterVersionRequest',
    as ArrayRef[DeleteParameterVersionRequest()];

coerce 'RepeatedDeleteParameterVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::DeleteParameterVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteParameterVersionRequest',
    as HashRef[DeleteParameterVersionRequest()];

declare 'Template',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::Template'];

coerce 'Template',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::Template'->new($_) };

declare 'RepeatedTemplate',
    as ArrayRef[Template()];

coerce 'RepeatedTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::Template'->new($_) } @$_ ] };

declare 'MapStringTemplate',
    as HashRef[Template()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::Template::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::Template::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::Template::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListTemplatesRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListTemplatesRequest'];

coerce 'ListTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListTemplatesRequest'->new($_) };

declare 'RepeatedListTemplatesRequest',
    as ArrayRef[ListTemplatesRequest()];

coerce 'RepeatedListTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListTemplatesRequest',
    as HashRef[ListTemplatesRequest()];

declare 'ListTemplatesResponse',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListTemplatesResponse'];

coerce 'ListTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListTemplatesResponse'->new($_) };

declare 'RepeatedListTemplatesResponse',
    as ArrayRef[ListTemplatesResponse()];

coerce 'RepeatedListTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListTemplatesResponse',
    as HashRef[ListTemplatesResponse()];

declare 'GetTemplateRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::GetTemplateRequest'];

coerce 'GetTemplateRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::GetTemplateRequest'->new($_) };

declare 'RepeatedGetTemplateRequest',
    as ArrayRef[GetTemplateRequest()];

coerce 'RepeatedGetTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::GetTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetTemplateRequest',
    as HashRef[GetTemplateRequest()];

declare 'CreateTemplateRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::CreateTemplateRequest'];

coerce 'CreateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::CreateTemplateRequest'->new($_) };

declare 'RepeatedCreateTemplateRequest',
    as ArrayRef[CreateTemplateRequest()];

coerce 'RepeatedCreateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::CreateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTemplateRequest',
    as HashRef[CreateTemplateRequest()];

declare 'UpdateTemplateRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::UpdateTemplateRequest'];

coerce 'UpdateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::UpdateTemplateRequest'->new($_) };

declare 'RepeatedUpdateTemplateRequest',
    as ArrayRef[UpdateTemplateRequest()];

coerce 'RepeatedUpdateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::UpdateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTemplateRequest',
    as HashRef[UpdateTemplateRequest()];

declare 'DeleteTemplateRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::DeleteTemplateRequest'];

coerce 'DeleteTemplateRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::DeleteTemplateRequest'->new($_) };

declare 'RepeatedDeleteTemplateRequest',
    as ArrayRef[DeleteTemplateRequest()];

coerce 'RepeatedDeleteTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::DeleteTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTemplateRequest',
    as HashRef[DeleteTemplateRequest()];

declare 'TemplateVersion',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::TemplateVersion'];

coerce 'TemplateVersion',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::TemplateVersion'->new($_) };

declare 'RepeatedTemplateVersion',
    as ArrayRef[TemplateVersion()];

coerce 'RepeatedTemplateVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::TemplateVersion'->new($_) } @$_ ] };

declare 'MapStringTemplateVersion',
    as HashRef[TemplateVersion()];

declare 'TemplateVersionPayload',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::TemplateVersionPayload'];

coerce 'TemplateVersionPayload',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::TemplateVersionPayload'->new($_) };

declare 'RepeatedTemplateVersionPayload',
    as ArrayRef[TemplateVersionPayload()];

coerce 'RepeatedTemplateVersionPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::TemplateVersionPayload'->new($_) } @$_ ] };

declare 'MapStringTemplateVersionPayload',
    as HashRef[TemplateVersionPayload()];

declare 'ListTemplateVersionsRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListTemplateVersionsRequest'];

coerce 'ListTemplateVersionsRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListTemplateVersionsRequest'->new($_) };

declare 'RepeatedListTemplateVersionsRequest',
    as ArrayRef[ListTemplateVersionsRequest()];

coerce 'RepeatedListTemplateVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListTemplateVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListTemplateVersionsRequest',
    as HashRef[ListTemplateVersionsRequest()];

declare 'ListTemplateVersionsResponse',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::ListTemplateVersionsResponse'];

coerce 'ListTemplateVersionsResponse',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::ListTemplateVersionsResponse'->new($_) };

declare 'RepeatedListTemplateVersionsResponse',
    as ArrayRef[ListTemplateVersionsResponse()];

coerce 'RepeatedListTemplateVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::ListTemplateVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListTemplateVersionsResponse',
    as HashRef[ListTemplateVersionsResponse()];

declare 'GetTemplateVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::GetTemplateVersionRequest'];

coerce 'GetTemplateVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::GetTemplateVersionRequest'->new($_) };

declare 'RepeatedGetTemplateVersionRequest',
    as ArrayRef[GetTemplateVersionRequest()];

coerce 'RepeatedGetTemplateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::GetTemplateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetTemplateVersionRequest',
    as HashRef[GetTemplateVersionRequest()];

declare 'CreateTemplateVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::CreateTemplateVersionRequest'];

coerce 'CreateTemplateVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::CreateTemplateVersionRequest'->new($_) };

declare 'RepeatedCreateTemplateVersionRequest',
    as ArrayRef[CreateTemplateVersionRequest()];

coerce 'RepeatedCreateTemplateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::CreateTemplateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTemplateVersionRequest',
    as HashRef[CreateTemplateVersionRequest()];

declare 'UpdateTemplateVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::UpdateTemplateVersionRequest'];

coerce 'UpdateTemplateVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::UpdateTemplateVersionRequest'->new($_) };

declare 'RepeatedUpdateTemplateVersionRequest',
    as ArrayRef[UpdateTemplateVersionRequest()];

coerce 'RepeatedUpdateTemplateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::UpdateTemplateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTemplateVersionRequest',
    as HashRef[UpdateTemplateVersionRequest()];

declare 'DeleteTemplateVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::DeleteTemplateVersionRequest'];

coerce 'DeleteTemplateVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::DeleteTemplateVersionRequest'->new($_) };

declare 'RepeatedDeleteTemplateVersionRequest',
    as ArrayRef[DeleteTemplateVersionRequest()];

coerce 'RepeatedDeleteTemplateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::DeleteTemplateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTemplateVersionRequest',
    as HashRef[DeleteTemplateVersionRequest()];

declare 'RenderTemplateVersionRequest',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::RenderTemplateVersionRequest'];

coerce 'RenderTemplateVersionRequest',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::RenderTemplateVersionRequest'->new($_) };

declare 'RepeatedRenderTemplateVersionRequest',
    as ArrayRef[RenderTemplateVersionRequest()];

coerce 'RepeatedRenderTemplateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::RenderTemplateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringRenderTemplateVersionRequest',
    as HashRef[RenderTemplateVersionRequest()];

declare 'RenderTemplateVersionResponse',
    as InstanceOf['Google::Cloud::Parametermanager::V1::Service::RenderTemplateVersionResponse'];

coerce 'RenderTemplateVersionResponse',
    from HashRef, via { 'Google::Cloud::Parametermanager::V1::Service::RenderTemplateVersionResponse'->new($_) };

declare 'RepeatedRenderTemplateVersionResponse',
    as ArrayRef[RenderTemplateVersionResponse()];

coerce 'RepeatedRenderTemplateVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parametermanager::V1::Service::RenderTemplateVersionResponse'->new($_) } @$_ ] };

declare 'MapStringRenderTemplateVersionResponse',
    as HashRef[RenderTemplateVersionResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Parametermanager::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
