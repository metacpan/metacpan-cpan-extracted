package Google::Iam::V3::AccessPolicyResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AccessPolicy',
    as InstanceOf['Google::Iam::V3::AccessPolicyResources::AccessPolicy'];

coerce 'AccessPolicy',
    from HashRef, via { 'Google::Iam::V3::AccessPolicyResources::AccessPolicy'->new($_) };

declare 'RepeatedAccessPolicy',
    as ArrayRef[AccessPolicy()];

coerce 'RepeatedAccessPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPolicyResources::AccessPolicy'->new($_) } @$_ ] };

declare 'MapStringAccessPolicy',
    as HashRef[AccessPolicy()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Iam::V3::AccessPolicyResources::AccessPolicy::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Iam::V3::AccessPolicyResources::AccessPolicy::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPolicyResources::AccessPolicy::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'AccessPolicyDetails',
    as InstanceOf['Google::Iam::V3::AccessPolicyResources::AccessPolicyDetails'];

coerce 'AccessPolicyDetails',
    from HashRef, via { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyDetails'->new($_) };

declare 'RepeatedAccessPolicyDetails',
    as ArrayRef[AccessPolicyDetails()];

coerce 'RepeatedAccessPolicyDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyDetails'->new($_) } @$_ ] };

declare 'MapStringAccessPolicyDetails',
    as HashRef[AccessPolicyDetails()];

declare 'AccessPolicyRule',
    as InstanceOf['Google::Iam::V3::AccessPolicyResources::AccessPolicyRule'];

coerce 'AccessPolicyRule',
    from HashRef, via { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyRule'->new($_) };

declare 'RepeatedAccessPolicyRule',
    as ArrayRef[AccessPolicyRule()];

coerce 'RepeatedAccessPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyRule'->new($_) } @$_ ] };

declare 'MapStringAccessPolicyRule',
    as HashRef[AccessPolicyRule()];

declare 'Effect',
    as (Int | Str);

declare 'Operation',
    as InstanceOf['Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'ConditionsEntry',
    as InstanceOf['Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::ConditionsEntry'];

coerce 'ConditionsEntry',
    from HashRef, via { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::ConditionsEntry'->new($_) };

declare 'RepeatedConditionsEntry',
    as ArrayRef[ConditionsEntry()];

coerce 'RepeatedConditionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::AccessPolicyResources::AccessPolicyRule::ConditionsEntry'->new($_) } @$_ ] };

declare 'MapStringConditionsEntry',
    as HashRef[ConditionsEntry()];

1;

__END__

=head1 NAME

Google::Iam::V3::AccessPolicyResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
