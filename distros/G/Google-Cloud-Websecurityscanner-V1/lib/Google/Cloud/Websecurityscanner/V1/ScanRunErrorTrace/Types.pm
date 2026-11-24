package Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ScanRunErrorTrace',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace'];

coerce 'ScanRunErrorTrace',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace'->new($_) };

declare 'RepeatedScanRunErrorTrace',
    as ArrayRef[ScanRunErrorTrace()];

coerce 'RepeatedScanRunErrorTrace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::ScanRunErrorTrace'->new($_) } @$_ ] };

declare 'MapStringScanRunErrorTrace',
    as HashRef[ScanRunErrorTrace()];

declare 'Code',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
