package Google::Appengine::V1::AuditData::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuditData',
    as InstanceOf['Google::Appengine::V1::AuditData::AuditData'];

coerce 'AuditData',
    from HashRef, via { 'Google::Appengine::V1::AuditData::AuditData'->new($_) };

declare 'RepeatedAuditData',
    as ArrayRef[AuditData()];

coerce 'RepeatedAuditData',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AuditData::AuditData'->new($_) } @$_ ] };

declare 'MapStringAuditData',
    as HashRef[AuditData()];

declare 'UpdateServiceMethod',
    as InstanceOf['Google::Appengine::V1::AuditData::UpdateServiceMethod'];

coerce 'UpdateServiceMethod',
    from HashRef, via { 'Google::Appengine::V1::AuditData::UpdateServiceMethod'->new($_) };

declare 'RepeatedUpdateServiceMethod',
    as ArrayRef[UpdateServiceMethod()];

coerce 'RepeatedUpdateServiceMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AuditData::UpdateServiceMethod'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceMethod',
    as HashRef[UpdateServiceMethod()];

declare 'CreateVersionMethod',
    as InstanceOf['Google::Appengine::V1::AuditData::CreateVersionMethod'];

coerce 'CreateVersionMethod',
    from HashRef, via { 'Google::Appengine::V1::AuditData::CreateVersionMethod'->new($_) };

declare 'RepeatedCreateVersionMethod',
    as ArrayRef[CreateVersionMethod()];

coerce 'RepeatedCreateVersionMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::AuditData::CreateVersionMethod'->new($_) } @$_ ] };

declare 'MapStringCreateVersionMethod',
    as HashRef[CreateVersionMethod()];

1;

__END__

=head1 NAME

Google::Appengine::V1::AuditData::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
