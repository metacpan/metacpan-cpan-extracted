package Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggedRestorePlanMetadata',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata'];

coerce 'LoggedRestorePlanMetadata',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata'->new($_) };

declare 'RepeatedLoggedRestorePlanMetadata',
    as ArrayRef[LoggedRestorePlanMetadata()];

coerce 'RepeatedLoggedRestorePlanMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata'->new($_) } @$_ ] };

declare 'MapStringLoggedRestorePlanMetadata',
    as HashRef[LoggedRestorePlanMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
