package Google::Cloud::Licensemanager::V1::ApiEntities::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LicenseType',
    as (Int | Str);

declare 'ActivationState',
    as (Int | Str);

declare 'Configuration',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Configuration'];

coerce 'Configuration',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Configuration'->new($_) };

declare 'RepeatedConfiguration',
    as ArrayRef[Configuration()];

coerce 'RepeatedConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Configuration'->new($_) } @$_ ] };

declare 'MapStringConfiguration',
    as HashRef[Configuration()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Configuration::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Configuration::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Configuration::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BillingInfo',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo'];

coerce 'BillingInfo',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo'->new($_) };

declare 'RepeatedBillingInfo',
    as ArrayRef[BillingInfo()];

coerce 'RepeatedBillingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo'->new($_) } @$_ ] };

declare 'MapStringBillingInfo',
    as HashRef[BillingInfo()];

declare 'UserCountBillingInfo',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::UserCountBillingInfo'];

coerce 'UserCountBillingInfo',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::UserCountBillingInfo'->new($_) };

declare 'RepeatedUserCountBillingInfo',
    as ArrayRef[UserCountBillingInfo()];

coerce 'RepeatedUserCountBillingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::UserCountBillingInfo'->new($_) } @$_ ] };

declare 'MapStringUserCountBillingInfo',
    as HashRef[UserCountBillingInfo()];

declare 'UserCountUsage',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::UserCountUsage'];

coerce 'UserCountUsage',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::UserCountUsage'->new($_) };

declare 'RepeatedUserCountUsage',
    as ArrayRef[UserCountUsage()];

coerce 'RepeatedUserCountUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::UserCountUsage'->new($_) } @$_ ] };

declare 'MapStringUserCountUsage',
    as HashRef[UserCountUsage()];

declare 'Product',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Product'];

coerce 'Product',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

declare 'State',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ProductActivationEntry',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Instance::ProductActivationEntry'];

coerce 'ProductActivationEntry',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Instance::ProductActivationEntry'->new($_) };

declare 'RepeatedProductActivationEntry',
    as ArrayRef[ProductActivationEntry()];

coerce 'RepeatedProductActivationEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Instance::ProductActivationEntry'->new($_) } @$_ ] };

declare 'MapStringProductActivationEntry',
    as HashRef[ProductActivationEntry()];

declare 'Usage',
    as InstanceOf['Google::Cloud::Licensemanager::V1::ApiEntities::Usage'];

coerce 'Usage',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::ApiEntities::Usage'->new($_) };

declare 'RepeatedUsage',
    as ArrayRef[Usage()];

coerce 'RepeatedUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::ApiEntities::Usage'->new($_) } @$_ ] };

declare 'MapStringUsage',
    as HashRef[Usage()];

1;

__END__

=head1 NAME

Google::Cloud::Licensemanager::V1::ApiEntities::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
