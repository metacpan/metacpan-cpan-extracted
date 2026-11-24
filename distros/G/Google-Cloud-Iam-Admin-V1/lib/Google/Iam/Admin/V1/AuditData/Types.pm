package Google::Iam::Admin::V1::AuditData::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuditData',
    as InstanceOf['Google::Iam::Admin::V1::AuditData::AuditData'];

coerce 'AuditData',
    from HashRef, via { 'Google::Iam::Admin::V1::AuditData::AuditData'->new($_) };

declare 'RepeatedAuditData',
    as ArrayRef[AuditData()];

coerce 'RepeatedAuditData',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::AuditData::AuditData'->new($_) } @$_ ] };

declare 'MapStringAuditData',
    as HashRef[AuditData()];

declare 'PermissionDelta',
    as InstanceOf['Google::Iam::Admin::V1::AuditData::AuditData::PermissionDelta'];

coerce 'PermissionDelta',
    from HashRef, via { 'Google::Iam::Admin::V1::AuditData::AuditData::PermissionDelta'->new($_) };

declare 'RepeatedPermissionDelta',
    as ArrayRef[PermissionDelta()];

coerce 'RepeatedPermissionDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Admin::V1::AuditData::AuditData::PermissionDelta'->new($_) } @$_ ] };

declare 'MapStringPermissionDelta',
    as HashRef[PermissionDelta()];

1;

__END__

=head1 NAME

Google::Iam::Admin::V1::AuditData::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
