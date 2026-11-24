package Google::Iam::V3::PolicyBindingResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PolicyBinding',
    as InstanceOf['Google::Iam::V3::PolicyBindingResources::PolicyBinding'];

coerce 'PolicyBinding',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingResources::PolicyBinding'->new($_) };

declare 'RepeatedPolicyBinding',
    as ArrayRef[PolicyBinding()];

coerce 'RepeatedPolicyBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingResources::PolicyBinding'->new($_) } @$_ ] };

declare 'MapStringPolicyBinding',
    as HashRef[PolicyBinding()];

declare 'PolicyKind',
    as (Int | Str);

declare 'Target',
    as InstanceOf['Google::Iam::V3::PolicyBindingResources::PolicyBinding::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingResources::PolicyBinding::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingResources::PolicyBinding::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Iam::V3::PolicyBindingResources::PolicyBinding::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Iam::V3::PolicyBindingResources::PolicyBinding::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::V3::PolicyBindingResources::PolicyBinding::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Iam::V3::PolicyBindingResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
