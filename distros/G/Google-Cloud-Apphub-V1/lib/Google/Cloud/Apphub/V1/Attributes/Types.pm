package Google::Cloud::Apphub::V1::Attributes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Attributes',
    as InstanceOf['Google::Cloud::Apphub::V1::Attributes::Attributes'];

coerce 'Attributes',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Attributes::Attributes'->new($_) };

declare 'RepeatedAttributes',
    as ArrayRef[Attributes()];

coerce 'RepeatedAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Attributes::Attributes'->new($_) } @$_ ] };

declare 'MapStringAttributes',
    as HashRef[Attributes()];

declare 'Criticality',
    as InstanceOf['Google::Cloud::Apphub::V1::Attributes::Criticality'];

coerce 'Criticality',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Attributes::Criticality'->new($_) };

declare 'RepeatedCriticality',
    as ArrayRef[Criticality()];

coerce 'RepeatedCriticality',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Attributes::Criticality'->new($_) } @$_ ] };

declare 'MapStringCriticality',
    as HashRef[Criticality()];

declare 'Type',
    as (Int | Str);

declare 'Environment',
    as InstanceOf['Google::Cloud::Apphub::V1::Attributes::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Attributes::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Attributes::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'Type',
    as (Int | Str);

declare 'ContactInfo',
    as InstanceOf['Google::Cloud::Apphub::V1::Attributes::ContactInfo'];

coerce 'ContactInfo',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Attributes::ContactInfo'->new($_) };

declare 'RepeatedContactInfo',
    as ArrayRef[ContactInfo()];

coerce 'RepeatedContactInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Attributes::ContactInfo'->new($_) } @$_ ] };

declare 'MapStringContactInfo',
    as HashRef[ContactInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::Attributes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
