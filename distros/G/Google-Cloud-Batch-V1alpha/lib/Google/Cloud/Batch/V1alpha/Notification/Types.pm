package Google::Cloud::Batch::V1alpha::Notification::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Notification',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Notification::Notification'];

coerce 'Notification',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Notification::Notification'->new($_) };

declare 'RepeatedNotification',
    as ArrayRef[Notification()];

coerce 'RepeatedNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Notification::Notification'->new($_) } @$_ ] };

declare 'MapStringNotification',
    as HashRef[Notification()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1alpha::Notification::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
