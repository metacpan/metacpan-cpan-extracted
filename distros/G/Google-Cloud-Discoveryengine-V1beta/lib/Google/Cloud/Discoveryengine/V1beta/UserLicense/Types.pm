package Google::Cloud::Discoveryengine::V1beta::UserLicense::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserLicense',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense'];

coerce 'UserLicense',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense'->new($_) };

declare 'RepeatedUserLicense',
    as ArrayRef[UserLicense()];

coerce 'RepeatedUserLicense',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense'->new($_) } @$_ ] };

declare 'MapStringUserLicense',
    as HashRef[UserLicense()];

declare 'LicenseAssignmentState',
    as (Int | Str);

declare 'LicenseConfigUsageStats',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseConfigUsageStats'];

coerce 'LicenseConfigUsageStats',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseConfigUsageStats'->new($_) };

declare 'RepeatedLicenseConfigUsageStats',
    as ArrayRef[LicenseConfigUsageStats()];

coerce 'RepeatedLicenseConfigUsageStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseConfigUsageStats'->new($_) } @$_ ] };

declare 'MapStringLicenseConfigUsageStats',
    as HashRef[LicenseConfigUsageStats()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserLicense::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
