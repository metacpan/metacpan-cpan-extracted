package Google::Cloud::Vision::V1::WebDetection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WebDetection',
    as InstanceOf['Google::Cloud::Vision::V1::WebDetection::WebDetection'];

coerce 'WebDetection',
    from HashRef, via { 'Google::Cloud::Vision::V1::WebDetection::WebDetection'->new($_) };

declare 'RepeatedWebDetection',
    as ArrayRef[WebDetection()];

coerce 'RepeatedWebDetection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::WebDetection::WebDetection'->new($_) } @$_ ] };

declare 'MapStringWebDetection',
    as HashRef[WebDetection()];

declare 'WebEntity',
    as InstanceOf['Google::Cloud::Vision::V1::WebDetection::WebDetection::WebEntity'];

coerce 'WebEntity',
    from HashRef, via { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebEntity'->new($_) };

declare 'RepeatedWebEntity',
    as ArrayRef[WebEntity()];

coerce 'RepeatedWebEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebEntity'->new($_) } @$_ ] };

declare 'MapStringWebEntity',
    as HashRef[WebEntity()];

declare 'WebImage',
    as InstanceOf['Google::Cloud::Vision::V1::WebDetection::WebDetection::WebImage'];

coerce 'WebImage',
    from HashRef, via { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebImage'->new($_) };

declare 'RepeatedWebImage',
    as ArrayRef[WebImage()];

coerce 'RepeatedWebImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebImage'->new($_) } @$_ ] };

declare 'MapStringWebImage',
    as HashRef[WebImage()];

declare 'WebPage',
    as InstanceOf['Google::Cloud::Vision::V1::WebDetection::WebDetection::WebPage'];

coerce 'WebPage',
    from HashRef, via { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebPage'->new($_) };

declare 'RepeatedWebPage',
    as ArrayRef[WebPage()];

coerce 'RepeatedWebPage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebPage'->new($_) } @$_ ] };

declare 'MapStringWebPage',
    as HashRef[WebPage()];

declare 'WebLabel',
    as InstanceOf['Google::Cloud::Vision::V1::WebDetection::WebDetection::WebLabel'];

coerce 'WebLabel',
    from HashRef, via { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebLabel'->new($_) };

declare 'RepeatedWebLabel',
    as ArrayRef[WebLabel()];

coerce 'RepeatedWebLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::WebDetection::WebDetection::WebLabel'->new($_) } @$_ ] };

declare 'MapStringWebLabel',
    as HashRef[WebLabel()];

1;

__END__

=head1 NAME

Google::Cloud::Vision::V1::WebDetection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
