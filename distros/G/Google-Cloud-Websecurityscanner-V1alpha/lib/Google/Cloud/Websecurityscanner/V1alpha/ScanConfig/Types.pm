package Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ScanConfig',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig'];

coerce 'ScanConfig',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig'->new($_) };

declare 'RepeatedScanConfig',
    as ArrayRef[ScanConfig()];

coerce 'RepeatedScanConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig'->new($_) } @$_ ] };

declare 'MapStringScanConfig',
    as HashRef[ScanConfig()];

declare 'UserAgent',
    as (Int | Str);

declare 'TargetPlatform',
    as (Int | Str);

declare 'Authentication',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication'];

coerce 'Authentication',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication'->new($_) };

declare 'RepeatedAuthentication',
    as ArrayRef[Authentication()];

coerce 'RepeatedAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication'->new($_) } @$_ ] };

declare 'MapStringAuthentication',
    as HashRef[Authentication()];

declare 'GoogleAccount',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication::GoogleAccount'];

coerce 'GoogleAccount',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication::GoogleAccount'->new($_) };

declare 'RepeatedGoogleAccount',
    as ArrayRef[GoogleAccount()];

coerce 'RepeatedGoogleAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication::GoogleAccount'->new($_) } @$_ ] };

declare 'MapStringGoogleAccount',
    as HashRef[GoogleAccount()];

declare 'CustomAccount',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication::CustomAccount'];

coerce 'CustomAccount',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication::CustomAccount'->new($_) };

declare 'RepeatedCustomAccount',
    as ArrayRef[CustomAccount()];

coerce 'RepeatedCustomAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Authentication::CustomAccount'->new($_) } @$_ ] };

declare 'MapStringCustomAccount',
    as HashRef[CustomAccount()];

declare 'Schedule',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
