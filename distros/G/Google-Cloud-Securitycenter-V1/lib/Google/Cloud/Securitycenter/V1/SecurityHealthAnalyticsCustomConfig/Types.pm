package Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomConfig',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig'];

coerce 'CustomConfig',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig'->new($_) };

declare 'RepeatedCustomConfig',
    as ArrayRef[CustomConfig()];

coerce 'RepeatedCustomConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig'->new($_) } @$_ ] };

declare 'MapStringCustomConfig',
    as HashRef[CustomConfig()];

declare 'Severity',
    as (Int | Str);

declare 'CustomOutputSpec',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec'];

coerce 'CustomOutputSpec',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec'->new($_) };

declare 'RepeatedCustomOutputSpec',
    as ArrayRef[CustomOutputSpec()];

coerce 'RepeatedCustomOutputSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec'->new($_) } @$_ ] };

declare 'MapStringCustomOutputSpec',
    as HashRef[CustomOutputSpec()];

declare 'Property',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::CustomOutputSpec::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'ResourceSelector',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::ResourceSelector'];

coerce 'ResourceSelector',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::ResourceSelector'->new($_) };

declare 'RepeatedResourceSelector',
    as ArrayRef[ResourceSelector()];

coerce 'RepeatedResourceSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig::ResourceSelector'->new($_) } @$_ ] };

declare 'MapStringResourceSelector',
    as HashRef[ResourceSelector()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
