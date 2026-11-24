package Google::Cloud::Batch::V1alpha::Volume::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Volume',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Volume::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Volume::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Volume::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'NFS',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Volume::NFS'];

coerce 'NFS',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Volume::NFS'->new($_) };

declare 'RepeatedNFS',
    as ArrayRef[NFS()];

coerce 'RepeatedNFS',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Volume::NFS'->new($_) } @$_ ] };

declare 'MapStringNFS',
    as HashRef[NFS()];

declare 'PD',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Volume::PD'];

coerce 'PD',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Volume::PD'->new($_) };

declare 'RepeatedPD',
    as ArrayRef[PD()];

coerce 'RepeatedPD',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Volume::PD'->new($_) } @$_ ] };

declare 'MapStringPD',
    as HashRef[PD()];

declare 'GCS',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Volume::GCS'];

coerce 'GCS',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Volume::GCS'->new($_) };

declare 'RepeatedGCS',
    as ArrayRef[GCS()];

coerce 'RepeatedGCS',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Volume::GCS'->new($_) } @$_ ] };

declare 'MapStringGCS',
    as HashRef[GCS()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1alpha::Volume::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
