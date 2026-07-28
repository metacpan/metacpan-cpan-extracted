package Google::Iam::V1::Policy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Policy',
    as InstanceOf['Google::Iam::V1::Policy::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Iam::V1::Policy::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'Binding',
    as InstanceOf['Google::Iam::V1::Policy::Binding'];

coerce 'Binding',
    from HashRef, via { 'Google::Iam::V1::Policy::Binding'->new($_) };

declare 'RepeatedBinding',
    as ArrayRef[Binding()];

coerce 'RepeatedBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::Binding'->new($_) } @$_ ] };

declare 'MapStringBinding',
    as HashRef[Binding()];

declare 'AuditConfig',
    as InstanceOf['Google::Iam::V1::Policy::AuditConfig'];

coerce 'AuditConfig',
    from HashRef, via { 'Google::Iam::V1::Policy::AuditConfig'->new($_) };

declare 'RepeatedAuditConfig',
    as ArrayRef[AuditConfig()];

coerce 'RepeatedAuditConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::AuditConfig'->new($_) } @$_ ] };

declare 'MapStringAuditConfig',
    as HashRef[AuditConfig()];

declare 'AuditLogConfig',
    as InstanceOf['Google::Iam::V1::Policy::AuditLogConfig'];

coerce 'AuditLogConfig',
    from HashRef, via { 'Google::Iam::V1::Policy::AuditLogConfig'->new($_) };

declare 'RepeatedAuditLogConfig',
    as ArrayRef[AuditLogConfig()];

coerce 'RepeatedAuditLogConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::AuditLogConfig'->new($_) } @$_ ] };

declare 'MapStringAuditLogConfig',
    as HashRef[AuditLogConfig()];

declare 'LogType',
    as (Int | Str);

declare 'PolicyDelta',
    as InstanceOf['Google::Iam::V1::Policy::PolicyDelta'];

coerce 'PolicyDelta',
    from HashRef, via { 'Google::Iam::V1::Policy::PolicyDelta'->new($_) };

declare 'RepeatedPolicyDelta',
    as ArrayRef[PolicyDelta()];

coerce 'RepeatedPolicyDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::PolicyDelta'->new($_) } @$_ ] };

declare 'MapStringPolicyDelta',
    as HashRef[PolicyDelta()];

declare 'BindingDelta',
    as InstanceOf['Google::Iam::V1::Policy::BindingDelta'];

coerce 'BindingDelta',
    from HashRef, via { 'Google::Iam::V1::Policy::BindingDelta'->new($_) };

declare 'RepeatedBindingDelta',
    as ArrayRef[BindingDelta()];

coerce 'RepeatedBindingDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::BindingDelta'->new($_) } @$_ ] };

declare 'MapStringBindingDelta',
    as HashRef[BindingDelta()];

declare 'Action',
    as (Int | Str);

declare 'AuditConfigDelta',
    as InstanceOf['Google::Iam::V1::Policy::AuditConfigDelta'];

coerce 'AuditConfigDelta',
    from HashRef, via { 'Google::Iam::V1::Policy::AuditConfigDelta'->new($_) };

declare 'RepeatedAuditConfigDelta',
    as ArrayRef[AuditConfigDelta()];

coerce 'RepeatedAuditConfigDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V1::Policy::AuditConfigDelta'->new($_) } @$_ ] };

declare 'MapStringAuditConfigDelta',
    as HashRef[AuditConfigDelta()];

declare 'Action',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Iam::V1::Policy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
