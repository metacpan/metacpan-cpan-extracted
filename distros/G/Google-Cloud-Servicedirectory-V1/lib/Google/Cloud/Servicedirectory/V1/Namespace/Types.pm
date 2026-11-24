package Google::Cloud::Servicedirectory::V1::Namespace::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Namespace',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::Namespace::Namespace'];

coerce 'Namespace',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::Namespace::Namespace'->new($_) };

declare 'RepeatedNamespace',
    as ArrayRef[Namespace()];

coerce 'RepeatedNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::Namespace::Namespace'->new($_) } @$_ ] };

declare 'MapStringNamespace',
    as HashRef[Namespace()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::Namespace::Namespace::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::Namespace::Namespace::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::Namespace::Namespace::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Servicedirectory::V1::Namespace::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
