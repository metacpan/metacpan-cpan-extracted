package Google::Cloud::Kms::V1::AutokeyAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpdateAutokeyConfigRequest',
    as InstanceOf['Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest'];

coerce 'UpdateAutokeyConfigRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest'->new($_) };

declare 'RepeatedUpdateAutokeyConfigRequest',
    as ArrayRef[UpdateAutokeyConfigRequest()];

coerce 'RepeatedUpdateAutokeyConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAutokeyConfigRequest',
    as HashRef[UpdateAutokeyConfigRequest()];

declare 'GetAutokeyConfigRequest',
    as InstanceOf['Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest'];

coerce 'GetAutokeyConfigRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest'->new($_) };

declare 'RepeatedGetAutokeyConfigRequest',
    as ArrayRef[GetAutokeyConfigRequest()];

coerce 'RepeatedGetAutokeyConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutokeyConfigRequest',
    as HashRef[GetAutokeyConfigRequest()];

declare 'AutokeyConfig',
    as InstanceOf['Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig'];

coerce 'AutokeyConfig',
    from HashRef, via { 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig'->new($_) };

declare 'RepeatedAutokeyConfig',
    as ArrayRef[AutokeyConfig()];

coerce 'RepeatedAutokeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig'->new($_) } @$_ ] };

declare 'MapStringAutokeyConfig',
    as HashRef[AutokeyConfig()];

declare 'State',
    as (Int | Str);

declare 'KeyProjectResolutionMode',
    as (Int | Str);

declare 'ShowEffectiveAutokeyConfigRequest',
    as InstanceOf['Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest'];

coerce 'ShowEffectiveAutokeyConfigRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest'->new($_) };

declare 'RepeatedShowEffectiveAutokeyConfigRequest',
    as ArrayRef[ShowEffectiveAutokeyConfigRequest()];

coerce 'RepeatedShowEffectiveAutokeyConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest'->new($_) } @$_ ] };

declare 'MapStringShowEffectiveAutokeyConfigRequest',
    as HashRef[ShowEffectiveAutokeyConfigRequest()];

declare 'ShowEffectiveAutokeyConfigResponse',
    as InstanceOf['Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse'];

coerce 'ShowEffectiveAutokeyConfigResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse'->new($_) };

declare 'RepeatedShowEffectiveAutokeyConfigResponse',
    as ArrayRef[ShowEffectiveAutokeyConfigResponse()];

coerce 'RepeatedShowEffectiveAutokeyConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse'->new($_) } @$_ ] };

declare 'MapStringShowEffectiveAutokeyConfigResponse',
    as HashRef[ShowEffectiveAutokeyConfigResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::AutokeyAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
