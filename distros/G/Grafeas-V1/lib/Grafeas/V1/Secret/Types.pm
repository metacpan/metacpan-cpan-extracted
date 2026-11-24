package Grafeas::V1::Secret::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecretKind',
    as (Int | Str);

declare 'SecretNote',
    as InstanceOf['Grafeas::V1::Secret::SecretNote'];

coerce 'SecretNote',
    from HashRef, via { 'Grafeas::V1::Secret::SecretNote'->new($_) };

declare 'RepeatedSecretNote',
    as ArrayRef[SecretNote()];

coerce 'RepeatedSecretNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Secret::SecretNote'->new($_) } @$_ ] };

declare 'MapStringSecretNote',
    as HashRef[SecretNote()];

declare 'SecretOccurrence',
    as InstanceOf['Grafeas::V1::Secret::SecretOccurrence'];

coerce 'SecretOccurrence',
    from HashRef, via { 'Grafeas::V1::Secret::SecretOccurrence'->new($_) };

declare 'RepeatedSecretOccurrence',
    as ArrayRef[SecretOccurrence()];

coerce 'RepeatedSecretOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Secret::SecretOccurrence'->new($_) } @$_ ] };

declare 'MapStringSecretOccurrence',
    as HashRef[SecretOccurrence()];

declare 'SecretLocation',
    as InstanceOf['Grafeas::V1::Secret::SecretLocation'];

coerce 'SecretLocation',
    from HashRef, via { 'Grafeas::V1::Secret::SecretLocation'->new($_) };

declare 'RepeatedSecretLocation',
    as ArrayRef[SecretLocation()];

coerce 'RepeatedSecretLocation',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Secret::SecretLocation'->new($_) } @$_ ] };

declare 'MapStringSecretLocation',
    as HashRef[SecretLocation()];

declare 'SecretStatus',
    as InstanceOf['Grafeas::V1::Secret::SecretStatus'];

coerce 'SecretStatus',
    from HashRef, via { 'Grafeas::V1::Secret::SecretStatus'->new($_) };

declare 'RepeatedSecretStatus',
    as ArrayRef[SecretStatus()];

coerce 'RepeatedSecretStatus',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Secret::SecretStatus'->new($_) } @$_ ] };

declare 'MapStringSecretStatus',
    as HashRef[SecretStatus()];

declare 'Status',
    as (Int | Str);

1;

__END__

=head1 NAME

Grafeas::V1::Secret::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
