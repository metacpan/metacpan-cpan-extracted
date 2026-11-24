package Google::Cloud::Talent::V4beta1::Tenant::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Tenant',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Tenant::Tenant'];

coerce 'Tenant',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Tenant::Tenant'->new($_) };

declare 'RepeatedTenant',
    as ArrayRef[Tenant()];

coerce 'RepeatedTenant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Tenant::Tenant'->new($_) } @$_ ] };

declare 'MapStringTenant',
    as HashRef[Tenant()];

declare 'DataUsageType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::Tenant::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
