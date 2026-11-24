package Google::Cloud::Discoveryengine::V1alpha::AclConfigService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetAclConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest'];

coerce 'GetAclConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest'->new($_) };

declare 'RepeatedGetAclConfigRequest',
    as ArrayRef[GetAclConfigRequest()];

coerce 'RepeatedGetAclConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAclConfigRequest',
    as HashRef[GetAclConfigRequest()];

declare 'UpdateAclConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest'];

coerce 'UpdateAclConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest'->new($_) };

declare 'RepeatedUpdateAclConfigRequest',
    as ArrayRef[UpdateAclConfigRequest()];

coerce 'RepeatedUpdateAclConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAclConfigRequest',
    as HashRef[UpdateAclConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::AclConfigService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
