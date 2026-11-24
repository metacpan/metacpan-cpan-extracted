package Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggedRestore',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore'];

coerce 'LoggedRestore',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore'->new($_) };

declare 'RepeatedLoggedRestore',
    as ArrayRef[LoggedRestore()];

coerce 'RepeatedLoggedRestore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore'->new($_) } @$_ ] };

declare 'MapStringLoggedRestore',
    as HashRef[LoggedRestore()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::LoggedRestore::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedRestore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
