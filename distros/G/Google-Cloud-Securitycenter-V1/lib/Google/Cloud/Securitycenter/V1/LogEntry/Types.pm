package Google::Cloud::Securitycenter::V1::LogEntry::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1::LogEntry::LogEntry'];

coerce 'LogEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::LogEntry::LogEntry'->new($_) };

declare 'RepeatedLogEntry',
    as ArrayRef[LogEntry()];

coerce 'RepeatedLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::LogEntry::LogEntry'->new($_) } @$_ ] };

declare 'MapStringLogEntry',
    as HashRef[LogEntry()];

declare 'CloudLoggingEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1::LogEntry::CloudLoggingEntry'];

coerce 'CloudLoggingEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::LogEntry::CloudLoggingEntry'->new($_) };

declare 'RepeatedCloudLoggingEntry',
    as ArrayRef[CloudLoggingEntry()];

coerce 'RepeatedCloudLoggingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::LogEntry::CloudLoggingEntry'->new($_) } @$_ ] };

declare 'MapStringCloudLoggingEntry',
    as HashRef[CloudLoggingEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::LogEntry::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
