package Google::Api::Logging::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Logging',
    as InstanceOf['Google::Api::Logging::Logging'];

coerce 'Logging',
    from HashRef, via { 'Google::Api::Logging::Logging'->new($_) };

declare 'RepeatedLogging',
    as ArrayRef[Logging()];

coerce 'RepeatedLogging',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Logging::Logging'->new($_) } @$_ ] };

declare 'MapStringLogging',
    as HashRef[Logging()];

declare 'LoggingDestination',
    as InstanceOf['Google::Api::Logging::Logging::LoggingDestination'];

coerce 'LoggingDestination',
    from HashRef, via { 'Google::Api::Logging::Logging::LoggingDestination'->new($_) };

declare 'RepeatedLoggingDestination',
    as ArrayRef[LoggingDestination()];

coerce 'RepeatedLoggingDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Logging::Logging::LoggingDestination'->new($_) } @$_ ] };

declare 'MapStringLoggingDestination',
    as HashRef[LoggingDestination()];

1;

__END__

=head1 NAME

Google::Api::Logging::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
