package Google::Cloud::Discoveryengine::V1beta::ProjectService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProvisionProjectRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest'];

coerce 'ProvisionProjectRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest'->new($_) };

declare 'RepeatedProvisionProjectRequest',
    as ArrayRef[ProvisionProjectRequest()];

coerce 'RepeatedProvisionProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest'->new($_) } @$_ ] };

declare 'MapStringProvisionProjectRequest',
    as HashRef[ProvisionProjectRequest()];

declare 'ProvisionIntent',
    as (Int | Str);

declare 'SaasParams',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest::SaasParams'];

coerce 'SaasParams',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest::SaasParams'->new($_) };

declare 'RepeatedSaasParams',
    as ArrayRef[SaasParams()];

coerce 'RepeatedSaasParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest::SaasParams'->new($_) } @$_ ] };

declare 'MapStringSaasParams',
    as HashRef[SaasParams()];

declare 'ProvisionProjectMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectMetadata'];

coerce 'ProvisionProjectMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectMetadata'->new($_) };

declare 'RepeatedProvisionProjectMetadata',
    as ArrayRef[ProvisionProjectMetadata()];

coerce 'RepeatedProvisionProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringProvisionProjectMetadata',
    as HashRef[ProvisionProjectMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::ProjectService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
