package Google::Ai::Generativelanguage::V1beta::ModelService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetModelRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'GetTunedModelRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest'];

coerce 'GetTunedModelRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest'->new($_) };

declare 'RepeatedGetTunedModelRequest',
    as ArrayRef[GetTunedModelRequest()];

coerce 'RepeatedGetTunedModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetTunedModelRequest',
    as HashRef[GetTunedModelRequest()];

declare 'ListTunedModelsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest'];

coerce 'ListTunedModelsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest'->new($_) };

declare 'RepeatedListTunedModelsRequest',
    as ArrayRef[ListTunedModelsRequest()];

coerce 'RepeatedListTunedModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListTunedModelsRequest',
    as HashRef[ListTunedModelsRequest()];

declare 'ListTunedModelsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse'];

coerce 'ListTunedModelsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse'->new($_) };

declare 'RepeatedListTunedModelsResponse',
    as ArrayRef[ListTunedModelsResponse()];

coerce 'RepeatedListTunedModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListTunedModelsResponse',
    as HashRef[ListTunedModelsResponse()];

declare 'CreateTunedModelRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest'];

coerce 'CreateTunedModelRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest'->new($_) };

declare 'RepeatedCreateTunedModelRequest',
    as ArrayRef[CreateTunedModelRequest()];

coerce 'RepeatedCreateTunedModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTunedModelRequest',
    as HashRef[CreateTunedModelRequest()];

declare 'CreateTunedModelMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelMetadata'];

coerce 'CreateTunedModelMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelMetadata'->new($_) };

declare 'RepeatedCreateTunedModelMetadata',
    as ArrayRef[CreateTunedModelMetadata()];

coerce 'RepeatedCreateTunedModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTunedModelMetadata',
    as HashRef[CreateTunedModelMetadata()];

declare 'UpdateTunedModelRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest'];

coerce 'UpdateTunedModelRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest'->new($_) };

declare 'RepeatedUpdateTunedModelRequest',
    as ArrayRef[UpdateTunedModelRequest()];

coerce 'RepeatedUpdateTunedModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTunedModelRequest',
    as HashRef[UpdateTunedModelRequest()];

declare 'DeleteTunedModelRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest'];

coerce 'DeleteTunedModelRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest'->new($_) };

declare 'RepeatedDeleteTunedModelRequest',
    as ArrayRef[DeleteTunedModelRequest()];

coerce 'RepeatedDeleteTunedModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTunedModelRequest',
    as HashRef[DeleteTunedModelRequest()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::ModelService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
