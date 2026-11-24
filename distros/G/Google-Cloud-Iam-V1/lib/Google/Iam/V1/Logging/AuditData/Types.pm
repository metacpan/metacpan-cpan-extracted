package Google::Iam::V1::Logging::AuditData::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuditData',
    as InstanceOf['Google::Iam::V1::Logging::AuditData::AuditData'];

coerce 'AuditData',
    from HashRef, via { 'Google::Iam::V1::Logging::AuditData::AuditData'->new($_) };

declare 'RepeatedAuditData',
    as ArrayRef[AuditData()];

coerce 'RepeatedAuditData',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Logging::AuditData::AuditData'->new($_) } @$_ ] };

declare 'MapStringAuditData',
    as HashRef[AuditData()];

1;

__END__

=head1 NAME

Google::Iam::V1::Logging::AuditData::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
