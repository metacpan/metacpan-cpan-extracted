package Google::Cloud::Securitycenter::V2::Database::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Database',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Database::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Database::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Database::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Database::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
