package Google::Cloud::Securitycenter::V2::DataAccessEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataAccessEvent',
    as InstanceOf['Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent'];

coerce 'DataAccessEvent',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent'->new($_) };

declare 'RepeatedDataAccessEvent',
    as ArrayRef[DataAccessEvent()];

coerce 'RepeatedDataAccessEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent'->new($_) } @$_ ] };

declare 'MapStringDataAccessEvent',
    as HashRef[DataAccessEvent()];

declare 'Operation',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::DataAccessEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
