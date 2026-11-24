package Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsFilesetSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec'];

coerce 'GcsFilesetSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec'->new($_) };

declare 'RepeatedGcsFilesetSpec',
    as ArrayRef[GcsFilesetSpec()];

coerce 'RepeatedGcsFilesetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFilesetSpec'->new($_) } @$_ ] };

declare 'MapStringGcsFilesetSpec',
    as HashRef[GcsFilesetSpec()];

declare 'GcsFileSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFileSpec'];

coerce 'GcsFileSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFileSpec'->new($_) };

declare 'RepeatedGcsFileSpec',
    as ArrayRef[GcsFileSpec()];

coerce 'RepeatedGcsFileSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::GcsFileSpec'->new($_) } @$_ ] };

declare 'MapStringGcsFileSpec',
    as HashRef[GcsFileSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::GcsFilesetSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
