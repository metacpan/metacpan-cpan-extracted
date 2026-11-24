package Google::Cloud::Securitycenter::V2::Connection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Connection',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Connection::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Connection::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Connection::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'Protocol',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Connection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
