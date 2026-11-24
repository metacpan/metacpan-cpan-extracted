package Google::Cloud::Apphub::V1::ServiceProjectAttachment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServiceProjectAttachment',
    as InstanceOf['Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment'];

coerce 'ServiceProjectAttachment',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment'->new($_) };

declare 'RepeatedServiceProjectAttachment',
    as ArrayRef[ServiceProjectAttachment()];

coerce 'RepeatedServiceProjectAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ServiceProjectAttachment::ServiceProjectAttachment'->new($_) } @$_ ] };

declare 'MapStringServiceProjectAttachment',
    as HashRef[ServiceProjectAttachment()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::ServiceProjectAttachment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
