package Google::Cloud::Apphub::V1::Properties::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FunctionalType',
    as InstanceOf['Google::Cloud::Apphub::V1::Properties::FunctionalType'];

coerce 'FunctionalType',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Properties::FunctionalType'->new($_) };

declare 'RepeatedFunctionalType',
    as ArrayRef[FunctionalType()];

coerce 'RepeatedFunctionalType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Properties::FunctionalType'->new($_) } @$_ ] };

declare 'MapStringFunctionalType',
    as HashRef[FunctionalType()];

declare 'Type',
    as (Int | Str);

declare 'RegistrationType',
    as InstanceOf['Google::Cloud::Apphub::V1::Properties::RegistrationType'];

coerce 'RegistrationType',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Properties::RegistrationType'->new($_) };

declare 'RepeatedRegistrationType',
    as ArrayRef[RegistrationType()];

coerce 'RepeatedRegistrationType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Properties::RegistrationType'->new($_) } @$_ ] };

declare 'MapStringRegistrationType',
    as HashRef[RegistrationType()];

declare 'Type',
    as (Int | Str);

declare 'ExtendedMetadata',
    as InstanceOf['Google::Cloud::Apphub::V1::Properties::ExtendedMetadata'];

coerce 'ExtendedMetadata',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Properties::ExtendedMetadata'->new($_) };

declare 'RepeatedExtendedMetadata',
    as ArrayRef[ExtendedMetadata()];

coerce 'RepeatedExtendedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Properties::ExtendedMetadata'->new($_) } @$_ ] };

declare 'MapStringExtendedMetadata',
    as HashRef[ExtendedMetadata()];

declare 'Identity',
    as InstanceOf['Google::Cloud::Apphub::V1::Properties::Identity'];

coerce 'Identity',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Properties::Identity'->new($_) };

declare 'RepeatedIdentity',
    as ArrayRef[Identity()];

coerce 'RepeatedIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Properties::Identity'->new($_) } @$_ ] };

declare 'MapStringIdentity',
    as HashRef[Identity()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::Properties::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
