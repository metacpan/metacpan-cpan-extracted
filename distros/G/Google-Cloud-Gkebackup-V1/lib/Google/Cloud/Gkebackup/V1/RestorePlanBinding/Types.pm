package Google::Cloud::Gkebackup::V1::RestorePlanBinding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestorePlanBinding',
    as InstanceOf['Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding'];

coerce 'RestorePlanBinding',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding'->new($_) };

declare 'RepeatedRestorePlanBinding',
    as ArrayRef[RestorePlanBinding()];

coerce 'RepeatedRestorePlanBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::RestorePlanBinding::RestorePlanBinding'->new($_) } @$_ ] };

declare 'MapStringRestorePlanBinding',
    as HashRef[RestorePlanBinding()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::RestorePlanBinding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
