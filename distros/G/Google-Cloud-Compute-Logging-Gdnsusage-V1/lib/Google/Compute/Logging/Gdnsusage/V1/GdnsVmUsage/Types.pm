package Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GdnsVmUsagePlatformLog',
    as InstanceOf['Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog'];

coerce 'GdnsVmUsagePlatformLog',
    from HashRef, via { 'Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog'->new($_) };

declare 'RepeatedGdnsVmUsagePlatformLog',
    as ArrayRef[GdnsVmUsagePlatformLog()];

coerce 'RepeatedGdnsVmUsagePlatformLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::GdnsVmUsagePlatformLog'->new($_) } @$_ ] };

declare 'MapStringGdnsVmUsagePlatformLog',
    as HashRef[GdnsVmUsagePlatformLog()];

declare 'VmInfo',
    as InstanceOf['Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo'];

coerce 'VmInfo',
    from HashRef, via { 'Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo'->new($_) };

declare 'RepeatedVmInfo',
    as ArrayRef[VmInfo()];

coerce 'RepeatedVmInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::VmInfo'->new($_) } @$_ ] };

declare 'MapStringVmInfo',
    as HashRef[VmInfo()];

1;

__END__

=head1 NAME

Google::Compute::Logging::Gdnsusage::V1::GdnsVmUsage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
