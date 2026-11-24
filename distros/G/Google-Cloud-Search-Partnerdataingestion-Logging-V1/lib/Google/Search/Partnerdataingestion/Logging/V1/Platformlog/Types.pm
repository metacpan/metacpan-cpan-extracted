package Google::Search::Partnerdataingestion::Logging::V1::Platformlog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IngestDetailsLog',
    as InstanceOf['Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog'];

coerce 'IngestDetailsLog',
    from HashRef, via { 'Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog'->new($_) };

declare 'RepeatedIngestDetailsLog',
    as ArrayRef[IngestDetailsLog()];

coerce 'RepeatedIngestDetailsLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Search::Partnerdataingestion::Logging::V1::Platformlog::IngestDetailsLog'->new($_) } @$_ ] };

declare 'MapStringIngestDetailsLog',
    as HashRef[IngestDetailsLog()];

1;

__END__

=head1 NAME

Google::Search::Partnerdataingestion::Logging::V1::Platformlog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
