package Google::Cloud::Websecurityscanner::V1beta::ScanConfigError::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ScanConfigError',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1beta::ScanConfigError::ScanConfigError'];

coerce 'ScanConfigError',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1beta::ScanConfigError::ScanConfigError'->new($_) };

declare 'RepeatedScanConfigError',
    as ArrayRef[ScanConfigError()];

coerce 'RepeatedScanConfigError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1beta::ScanConfigError::ScanConfigError'->new($_) } @$_ ] };

declare 'MapStringScanConfigError',
    as HashRef[ScanConfigError()];

declare 'Code',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::ScanConfigError::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
