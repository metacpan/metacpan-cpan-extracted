package Google::Cloud::Securitycenter::V2::IamBinding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IamBinding',
    as InstanceOf['Google::Cloud::Securitycenter::V2::IamBinding::IamBinding'];

coerce 'IamBinding',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::IamBinding::IamBinding'->new($_) };

declare 'RepeatedIamBinding',
    as ArrayRef[IamBinding()];

coerce 'RepeatedIamBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::IamBinding::IamBinding'->new($_) } @$_ ] };

declare 'MapStringIamBinding',
    as HashRef[IamBinding()];

declare 'Action',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::IamBinding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
