package Google::Cloud::Connectors::V1::Runtime::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetRuntimeConfigRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest'];

coerce 'GetRuntimeConfigRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest'->new($_) };

declare 'RepeatedGetRuntimeConfigRequest',
    as ArrayRef[GetRuntimeConfigRequest()];

coerce 'RepeatedGetRuntimeConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuntimeConfigRequest',
    as HashRef[GetRuntimeConfigRequest()];

declare 'RuntimeConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::Runtime::RuntimeConfig'];

coerce 'RuntimeConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Runtime::RuntimeConfig'->new($_) };

declare 'RepeatedRuntimeConfig',
    as ArrayRef[RuntimeConfig()];

coerce 'RepeatedRuntimeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Runtime::RuntimeConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeConfig',
    as HashRef[RuntimeConfig()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Runtime::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
