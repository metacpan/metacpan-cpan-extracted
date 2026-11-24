package Google::Cloud::Securitycenter::V1beta1::Asset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Asset',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::Asset::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::Asset::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::Asset::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'SecurityCenterProperties',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::Asset::Asset::SecurityCenterProperties'];

coerce 'SecurityCenterProperties',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::Asset::Asset::SecurityCenterProperties'->new($_) };

declare 'RepeatedSecurityCenterProperties',
    as ArrayRef[SecurityCenterProperties()];

coerce 'RepeatedSecurityCenterProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::Asset::Asset::SecurityCenterProperties'->new($_) } @$_ ] };

declare 'MapStringSecurityCenterProperties',
    as HashRef[SecurityCenterProperties()];

declare 'ResourcePropertiesEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1beta1::Asset::Asset::ResourcePropertiesEntry'];

coerce 'ResourcePropertiesEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1beta1::Asset::Asset::ResourcePropertiesEntry'->new($_) };

declare 'RepeatedResourcePropertiesEntry',
    as ArrayRef[ResourcePropertiesEntry()];

coerce 'RepeatedResourcePropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1beta1::Asset::Asset::ResourcePropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringResourcePropertiesEntry',
    as HashRef[ResourcePropertiesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::Asset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
