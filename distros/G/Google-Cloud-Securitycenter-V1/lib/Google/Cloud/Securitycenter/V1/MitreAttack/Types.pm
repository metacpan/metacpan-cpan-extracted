package Google::Cloud::Securitycenter::V1::MitreAttack::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MitreAttack',
    as InstanceOf['Google::Cloud::Securitycenter::V1::MitreAttack::MitreAttack'];

coerce 'MitreAttack',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::MitreAttack::MitreAttack'->new($_) };

declare 'RepeatedMitreAttack',
    as ArrayRef[MitreAttack()];

coerce 'RepeatedMitreAttack',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::MitreAttack::MitreAttack'->new($_) } @$_ ] };

declare 'MapStringMitreAttack',
    as HashRef[MitreAttack()];

declare 'Tactic',
    as (Int | Str);

declare 'Technique',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::MitreAttack::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
