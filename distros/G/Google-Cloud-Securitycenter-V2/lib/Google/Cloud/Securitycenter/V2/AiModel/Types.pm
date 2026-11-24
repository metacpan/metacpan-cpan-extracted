package Google::Cloud::Securitycenter::V2::AiModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AiModel',
    as InstanceOf['Google::Cloud::Securitycenter::V2::AiModel::AiModel'];

coerce 'AiModel',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::AiModel::AiModel'->new($_) };

declare 'RepeatedAiModel',
    as ArrayRef[AiModel()];

coerce 'RepeatedAiModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::AiModel::AiModel'->new($_) } @$_ ] };

declare 'MapStringAiModel',
    as HashRef[AiModel()];

declare 'DeploymentPlatform',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::AiModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
