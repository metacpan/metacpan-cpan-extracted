package Google::Cloud::Connectors::V1::Provider::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Provider',
    as InstanceOf['Google::Cloud::Connectors::V1::Provider::Provider'];

coerce 'Provider',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Provider::Provider'->new($_) };

declare 'RepeatedProvider',
    as ArrayRef[Provider()];

coerce 'RepeatedProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Provider::Provider'->new($_) } @$_ ] };

declare 'MapStringProvider',
    as HashRef[Provider()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Connectors::V1::Provider::Provider::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Provider::Provider::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Provider::Provider::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetProviderRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Provider::GetProviderRequest'];

coerce 'GetProviderRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Provider::GetProviderRequest'->new($_) };

declare 'RepeatedGetProviderRequest',
    as ArrayRef[GetProviderRequest()];

coerce 'RepeatedGetProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Provider::GetProviderRequest'->new($_) } @$_ ] };

declare 'MapStringGetProviderRequest',
    as HashRef[GetProviderRequest()];

declare 'ListProvidersRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Provider::ListProvidersRequest'];

coerce 'ListProvidersRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Provider::ListProvidersRequest'->new($_) };

declare 'RepeatedListProvidersRequest',
    as ArrayRef[ListProvidersRequest()];

coerce 'RepeatedListProvidersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Provider::ListProvidersRequest'->new($_) } @$_ ] };

declare 'MapStringListProvidersRequest',
    as HashRef[ListProvidersRequest()];

declare 'ListProvidersResponse',
    as InstanceOf['Google::Cloud::Connectors::V1::Provider::ListProvidersResponse'];

coerce 'ListProvidersResponse',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Provider::ListProvidersResponse'->new($_) };

declare 'RepeatedListProvidersResponse',
    as ArrayRef[ListProvidersResponse()];

coerce 'RepeatedListProvidersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Provider::ListProvidersResponse'->new($_) } @$_ ] };

declare 'MapStringListProvidersResponse',
    as HashRef[ListProvidersResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Provider::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
