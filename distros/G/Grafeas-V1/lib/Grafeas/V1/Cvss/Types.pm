package Grafeas::V1::Cvss::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CVSSVersion',
    as (Int | Str);

declare 'CVSSv3',
    as InstanceOf['Grafeas::V1::Cvss::CVSSv3'];

coerce 'CVSSv3',
    from HashRef, via { 'Grafeas::V1::Cvss::CVSSv3'->new($_) };

declare 'RepeatedCVSSv3',
    as ArrayRef[CVSSv3()];

coerce 'RepeatedCVSSv3',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Cvss::CVSSv3'->new($_) } @$_ ] };

declare 'MapStringCVSSv3',
    as HashRef[CVSSv3()];

declare 'AttackVector',
    as (Int | Str);

declare 'AttackComplexity',
    as (Int | Str);

declare 'PrivilegesRequired',
    as (Int | Str);

declare 'UserInteraction',
    as (Int | Str);

declare 'Scope',
    as (Int | Str);

declare 'Impact',
    as (Int | Str);

declare 'CVSS',
    as InstanceOf['Grafeas::V1::Cvss::CVSS'];

coerce 'CVSS',
    from HashRef, via { 'Grafeas::V1::Cvss::CVSS'->new($_) };

declare 'RepeatedCVSS',
    as ArrayRef[CVSS()];

coerce 'RepeatedCVSS',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Cvss::CVSS'->new($_) } @$_ ] };

declare 'MapStringCVSS',
    as HashRef[CVSS()];

declare 'AttackVector',
    as (Int | Str);

declare 'AttackComplexity',
    as (Int | Str);

declare 'Authentication',
    as (Int | Str);

declare 'PrivilegesRequired',
    as (Int | Str);

declare 'UserInteraction',
    as (Int | Str);

declare 'Scope',
    as (Int | Str);

declare 'Impact',
    as (Int | Str);

declare 'AttackRequirements',
    as (Int | Str);

declare 'ExploitMaturity',
    as (Int | Str);

1;

__END__

=head1 NAME

Grafeas::V1::Cvss::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
