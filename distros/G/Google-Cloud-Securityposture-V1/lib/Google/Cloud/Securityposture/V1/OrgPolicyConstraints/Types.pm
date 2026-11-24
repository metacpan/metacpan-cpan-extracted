package Google::Cloud::Securityposture::V1::OrgPolicyConstraints::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OrgPolicyConstraint',
    as InstanceOf['Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint'];

coerce 'OrgPolicyConstraint',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint'->new($_) };

declare 'RepeatedOrgPolicyConstraint',
    as ArrayRef[OrgPolicyConstraint()];

coerce 'RepeatedOrgPolicyConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint'->new($_) } @$_ ] };

declare 'MapStringOrgPolicyConstraint',
    as HashRef[OrgPolicyConstraint()];

declare 'OrgPolicyConstraintCustom',
    as InstanceOf['Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraintCustom'];

coerce 'OrgPolicyConstraintCustom',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraintCustom'->new($_) };

declare 'RepeatedOrgPolicyConstraintCustom',
    as ArrayRef[OrgPolicyConstraintCustom()];

coerce 'RepeatedOrgPolicyConstraintCustom',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraintCustom'->new($_) } @$_ ] };

declare 'MapStringOrgPolicyConstraintCustom',
    as HashRef[OrgPolicyConstraintCustom()];

1;

__END__

=head1 NAME

Google::Cloud::Securityposture::V1::OrgPolicyConstraints::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
