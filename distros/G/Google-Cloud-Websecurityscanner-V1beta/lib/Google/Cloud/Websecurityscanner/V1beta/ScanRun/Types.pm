package Google::Cloud::Websecurityscanner::V1beta::ScanRun::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ScanRun',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun'];

coerce 'ScanRun',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun'->new($_) };

declare 'RepeatedScanRun',
    as ArrayRef[ScanRun()];

coerce 'RepeatedScanRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun'->new($_) } @$_ ] };

declare 'MapStringScanRun',
    as HashRef[ScanRun()];

declare 'ExecutionState',
    as (Int | Str);

declare 'ResultState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::ScanRun::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
