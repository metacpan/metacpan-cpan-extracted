package Google::Api::Log::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogDescriptor',
    as InstanceOf['Google::Api::Log::LogDescriptor'];

coerce 'LogDescriptor',
    from HashRef, via { 'Google::Api::Log::LogDescriptor'->new($_) };

declare 'RepeatedLogDescriptor',
    as ArrayRef[LogDescriptor()];

coerce 'RepeatedLogDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Log::LogDescriptor'->new($_) } @$_ ] };

declare 'MapStringLogDescriptor',
    as HashRef[LogDescriptor()];

1;

__END__

=head1 NAME

Google::Api::Log::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
