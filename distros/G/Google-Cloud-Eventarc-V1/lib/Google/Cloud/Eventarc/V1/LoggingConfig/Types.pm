package Google::Cloud::Eventarc::V1::LoggingConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggingConfig',
    as InstanceOf['Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LogSeverity',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::LoggingConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
