package Google::Cloud::Datacatalog::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IntegratedSystem',
    as (Int | Str);

declare 'ManagingSystem',
    as (Int | Str);

declare 'PersonalDetails',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Common::PersonalDetails'];

coerce 'PersonalDetails',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Common::PersonalDetails'->new($_) };

declare 'RepeatedPersonalDetails',
    as ArrayRef[PersonalDetails()];

coerce 'RepeatedPersonalDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Common::PersonalDetails'->new($_) } @$_ ] };

declare 'MapStringPersonalDetails',
    as HashRef[PersonalDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
