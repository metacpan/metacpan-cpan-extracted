package Google::Cloud::Orgpolicy::V1::Orgpolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Policy',
    as InstanceOf['Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy'];

coerce 'Policy',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy'->new($_) };

declare 'RepeatedPolicy',
    as ArrayRef[Policy()];

coerce 'RepeatedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy'->new($_) } @$_ ] };

declare 'MapStringPolicy',
    as HashRef[Policy()];

declare 'ListPolicy',
    as InstanceOf['Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::ListPolicy'];

coerce 'ListPolicy',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::ListPolicy'->new($_) };

declare 'RepeatedListPolicy',
    as ArrayRef[ListPolicy()];

coerce 'RepeatedListPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::ListPolicy'->new($_) } @$_ ] };

declare 'MapStringListPolicy',
    as HashRef[ListPolicy()];

declare 'AllValues',
    as (Int | Str);

declare 'BooleanPolicy',
    as InstanceOf['Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::BooleanPolicy'];

coerce 'BooleanPolicy',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::BooleanPolicy'->new($_) };

declare 'RepeatedBooleanPolicy',
    as ArrayRef[BooleanPolicy()];

coerce 'RepeatedBooleanPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::BooleanPolicy'->new($_) } @$_ ] };

declare 'MapStringBooleanPolicy',
    as HashRef[BooleanPolicy()];

declare 'RestoreDefault',
    as InstanceOf['Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::RestoreDefault'];

coerce 'RestoreDefault',
    from HashRef, via { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::RestoreDefault'->new($_) };

declare 'RepeatedRestoreDefault',
    as ArrayRef[RestoreDefault()];

coerce 'RepeatedRestoreDefault',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orgpolicy::V1::Orgpolicy::Policy::RestoreDefault'->new($_) } @$_ ] };

declare 'MapStringRestoreDefault',
    as HashRef[RestoreDefault()];

1;

__END__

=head1 NAME

Google::Cloud::Orgpolicy::V1::Orgpolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
