package Google::Cloud::Securityposture::V1::OrgPolicyConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PolicyRule',
    as InstanceOf['Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule'];

coerce 'PolicyRule',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule'->new($_) };

declare 'RepeatedPolicyRule',
    as ArrayRef[PolicyRule()];

coerce 'RepeatedPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule'->new($_) } @$_ ] };

declare 'MapStringPolicyRule',
    as HashRef[PolicyRule()];

declare 'StringValues',
    as InstanceOf['Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule::StringValues'];

coerce 'StringValues',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule::StringValues'->new($_) };

declare 'RepeatedStringValues',
    as ArrayRef[StringValues()];

coerce 'RepeatedStringValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule::StringValues'->new($_) } @$_ ] };

declare 'MapStringStringValues',
    as HashRef[StringValues()];

declare 'CustomConstraint',
    as InstanceOf['Google::Cloud::Securityposture::V1::OrgPolicyConfig::CustomConstraint'];

coerce 'CustomConstraint',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::OrgPolicyConfig::CustomConstraint'->new($_) };

declare 'RepeatedCustomConstraint',
    as ArrayRef[CustomConstraint()];

coerce 'RepeatedCustomConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::OrgPolicyConfig::CustomConstraint'->new($_) } @$_ ] };

declare 'MapStringCustomConstraint',
    as HashRef[CustomConstraint()];

declare 'MethodType',
    as (Int | Str);

declare 'ActionType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securityposture::V1::OrgPolicyConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
