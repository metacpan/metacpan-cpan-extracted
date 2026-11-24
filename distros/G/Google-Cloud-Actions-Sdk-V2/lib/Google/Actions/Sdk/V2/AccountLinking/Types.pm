package Google::Actions::Sdk::V2::AccountLinking::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AccountLinking',
    as InstanceOf['Google::Actions::Sdk::V2::AccountLinking::AccountLinking'];

coerce 'AccountLinking',
    from HashRef, via { 'Google::Actions::Sdk::V2::AccountLinking::AccountLinking'->new($_) };

declare 'RepeatedAccountLinking',
    as ArrayRef[AccountLinking()];

coerce 'RepeatedAccountLinking',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::AccountLinking::AccountLinking'->new($_) } @$_ ] };

declare 'MapStringAccountLinking',
    as HashRef[AccountLinking()];

declare 'LinkingType',
    as (Int | Str);

declare 'AuthGrantType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::AccountLinking::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
