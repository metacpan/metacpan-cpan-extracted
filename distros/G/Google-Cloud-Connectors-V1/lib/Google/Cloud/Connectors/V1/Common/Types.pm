package Google::Cloud::Connectors::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LaunchStage',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ConfigVariableTemplate',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate'];

coerce 'ConfigVariableTemplate',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate'->new($_) };

declare 'RepeatedConfigVariableTemplate',
    as ArrayRef[ConfigVariableTemplate()];

coerce 'RepeatedConfigVariableTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::ConfigVariableTemplate'->new($_) } @$_ ] };

declare 'MapStringConfigVariableTemplate',
    as HashRef[ConfigVariableTemplate()];

declare 'ValueType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Secret',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'EnumOption',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::EnumOption'];

coerce 'EnumOption',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::EnumOption'->new($_) };

declare 'RepeatedEnumOption',
    as ArrayRef[EnumOption()];

coerce 'RepeatedEnumOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::EnumOption'->new($_) } @$_ ] };

declare 'MapStringEnumOption',
    as HashRef[EnumOption()];

declare 'ConfigVariable',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::ConfigVariable'];

coerce 'ConfigVariable',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::ConfigVariable'->new($_) };

declare 'RepeatedConfigVariable',
    as ArrayRef[ConfigVariable()];

coerce 'RepeatedConfigVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::ConfigVariable'->new($_) } @$_ ] };

declare 'MapStringConfigVariable',
    as HashRef[ConfigVariable()];

declare 'RoleGrant',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::RoleGrant'];

coerce 'RoleGrant',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::RoleGrant'->new($_) };

declare 'RepeatedRoleGrant',
    as ArrayRef[RoleGrant()];

coerce 'RepeatedRoleGrant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::RoleGrant'->new($_) } @$_ ] };

declare 'MapStringRoleGrant',
    as HashRef[RoleGrant()];

declare 'Principal',
    as (Int | Str);

declare 'Resource',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::RoleGrant::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::RoleGrant::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::RoleGrant::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'Type',
    as (Int | Str);

declare 'AuthorizationCodeLink',
    as InstanceOf['Google::Cloud::Connectors::V1::Common::AuthorizationCodeLink'];

coerce 'AuthorizationCodeLink',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Common::AuthorizationCodeLink'->new($_) };

declare 'RepeatedAuthorizationCodeLink',
    as ArrayRef[AuthorizationCodeLink()];

coerce 'RepeatedAuthorizationCodeLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Common::AuthorizationCodeLink'->new($_) } @$_ ] };

declare 'MapStringAuthorizationCodeLink',
    as HashRef[AuthorizationCodeLink()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
