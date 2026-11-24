package Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataRetentionDeletionEvent',
    as InstanceOf['Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent'];

coerce 'DataRetentionDeletionEvent',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent'->new($_) };

declare 'RepeatedDataRetentionDeletionEvent',
    as ArrayRef[DataRetentionDeletionEvent()];

coerce 'RepeatedDataRetentionDeletionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::DataRetentionDeletionEvent'->new($_) } @$_ ] };

declare 'MapStringDataRetentionDeletionEvent',
    as HashRef[DataRetentionDeletionEvent()];

declare 'EventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::DataRetentionDeletionEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
