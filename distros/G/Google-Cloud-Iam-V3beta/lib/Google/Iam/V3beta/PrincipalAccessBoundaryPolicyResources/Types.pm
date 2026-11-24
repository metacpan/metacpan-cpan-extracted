package Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PrincipalAccessBoundaryPolicy',
    as InstanceOf['Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy'];

coerce 'PrincipalAccessBoundaryPolicy',
    from HashRef, via { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy'->new($_) };

declare 'RepeatedPrincipalAccessBoundaryPolicy',
    as ArrayRef[PrincipalAccessBoundaryPolicy()];

coerce 'RepeatedPrincipalAccessBoundaryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy'->new($_) } @$_ ] };

declare 'MapStringPrincipalAccessBoundaryPolicy',
    as HashRef[PrincipalAccessBoundaryPolicy()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicy::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PrincipalAccessBoundaryPolicyDetails',
    as InstanceOf['Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails'];

coerce 'PrincipalAccessBoundaryPolicyDetails',
    from HashRef, via { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails'->new($_) };

declare 'RepeatedPrincipalAccessBoundaryPolicyDetails',
    as ArrayRef[PrincipalAccessBoundaryPolicyDetails()];

coerce 'RepeatedPrincipalAccessBoundaryPolicyDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyDetails'->new($_) } @$_ ] };

declare 'MapStringPrincipalAccessBoundaryPolicyDetails',
    as HashRef[PrincipalAccessBoundaryPolicyDetails()];

declare 'PrincipalAccessBoundaryPolicyRule',
    as InstanceOf['Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule'];

coerce 'PrincipalAccessBoundaryPolicyRule',
    from HashRef, via { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule'->new($_) };

declare 'RepeatedPrincipalAccessBoundaryPolicyRule',
    as ArrayRef[PrincipalAccessBoundaryPolicyRule()];

coerce 'RepeatedPrincipalAccessBoundaryPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::PrincipalAccessBoundaryPolicyRule'->new($_) } @$_ ] };

declare 'MapStringPrincipalAccessBoundaryPolicyRule',
    as HashRef[PrincipalAccessBoundaryPolicyRule()];

declare 'Effect',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Iam::V3beta::PrincipalAccessBoundaryPolicyResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
