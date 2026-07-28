package Google::Ai::Generativelanguage::V1::ModelService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetModelRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1::ModelService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
