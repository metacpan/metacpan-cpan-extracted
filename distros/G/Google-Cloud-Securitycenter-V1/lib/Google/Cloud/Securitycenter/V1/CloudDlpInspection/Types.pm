package Google::Cloud::Securitycenter::V1::CloudDlpInspection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudDlpInspection',
    as InstanceOf['Google::Cloud::Securitycenter::V1::CloudDlpInspection::CloudDlpInspection'];

coerce 'CloudDlpInspection',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::CloudDlpInspection::CloudDlpInspection'->new($_) };

declare 'RepeatedCloudDlpInspection',
    as ArrayRef[CloudDlpInspection()];

coerce 'RepeatedCloudDlpInspection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::CloudDlpInspection::CloudDlpInspection'->new($_) } @$_ ] };

declare 'MapStringCloudDlpInspection',
    as HashRef[CloudDlpInspection()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::CloudDlpInspection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
