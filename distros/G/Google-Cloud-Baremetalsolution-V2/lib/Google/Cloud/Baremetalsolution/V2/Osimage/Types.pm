package Google::Cloud::Baremetalsolution::V2::Osimage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OSImage',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Osimage::OSImage'];

coerce 'OSImage',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Osimage::OSImage'->new($_) };

declare 'RepeatedOSImage',
    as ArrayRef[OSImage()];

coerce 'RepeatedOSImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Osimage::OSImage'->new($_) } @$_ ] };

declare 'MapStringOSImage',
    as HashRef[OSImage()];

declare 'ListOSImagesRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesRequest'];

coerce 'ListOSImagesRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesRequest'->new($_) };

declare 'RepeatedListOSImagesRequest',
    as ArrayRef[ListOSImagesRequest()];

coerce 'RepeatedListOSImagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesRequest'->new($_) } @$_ ] };

declare 'MapStringListOSImagesRequest',
    as HashRef[ListOSImagesRequest()];

declare 'ListOSImagesResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesResponse'];

coerce 'ListOSImagesResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesResponse'->new($_) };

declare 'RepeatedListOSImagesResponse',
    as ArrayRef[ListOSImagesResponse()];

coerce 'RepeatedListOSImagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Osimage::ListOSImagesResponse'->new($_) } @$_ ] };

declare 'MapStringListOSImagesResponse',
    as HashRef[ListOSImagesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Osimage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
