package Google::Cloud::Securitycenter::V1::ResourceValueConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourceValue',
    as (Int | Str);

declare 'ResourceValueConfig',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig'];

coerce 'ResourceValueConfig',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig'->new($_) };

declare 'RepeatedResourceValueConfig',
    as ArrayRef[ResourceValueConfig()];

coerce 'RepeatedResourceValueConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig'->new($_) } @$_ ] };

declare 'MapStringResourceValueConfig',
    as HashRef[ResourceValueConfig()];

declare 'SensitiveDataProtectionMapping',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::SensitiveDataProtectionMapping'];

coerce 'SensitiveDataProtectionMapping',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::SensitiveDataProtectionMapping'->new($_) };

declare 'RepeatedSensitiveDataProtectionMapping',
    as ArrayRef[SensitiveDataProtectionMapping()];

coerce 'RepeatedSensitiveDataProtectionMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::SensitiveDataProtectionMapping'->new($_) } @$_ ] };

declare 'MapStringSensitiveDataProtectionMapping',
    as HashRef[SensitiveDataProtectionMapping()];

declare 'ResourceLabelsSelectorEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::ResourceLabelsSelectorEntry'];

coerce 'ResourceLabelsSelectorEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::ResourceLabelsSelectorEntry'->new($_) };

declare 'RepeatedResourceLabelsSelectorEntry',
    as ArrayRef[ResourceLabelsSelectorEntry()];

coerce 'RepeatedResourceLabelsSelectorEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::ResourceValueConfig::ResourceValueConfig::ResourceLabelsSelectorEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsSelectorEntry',
    as HashRef[ResourceLabelsSelectorEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::ResourceValueConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
