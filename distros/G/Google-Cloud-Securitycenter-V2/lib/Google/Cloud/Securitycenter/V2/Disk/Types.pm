package Google::Cloud::Securitycenter::V2::Disk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Disk',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Disk::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Disk::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Disk::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Disk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
