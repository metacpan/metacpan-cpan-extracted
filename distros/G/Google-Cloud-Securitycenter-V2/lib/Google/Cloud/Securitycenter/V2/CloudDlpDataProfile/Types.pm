package Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudDlpDataProfile',
    as InstanceOf['Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile'];

coerce 'CloudDlpDataProfile',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile'->new($_) };

declare 'RepeatedCloudDlpDataProfile',
    as ArrayRef[CloudDlpDataProfile()];

coerce 'RepeatedCloudDlpDataProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile'->new($_) } @$_ ] };

declare 'MapStringCloudDlpDataProfile',
    as HashRef[CloudDlpDataProfile()];

declare 'ParentType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
