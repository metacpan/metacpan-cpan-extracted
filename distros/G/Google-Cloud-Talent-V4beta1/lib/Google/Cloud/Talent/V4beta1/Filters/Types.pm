package Google::Cloud::Talent::V4beta1::Filters::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobQuery',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Filters::JobQuery'];

coerce 'JobQuery',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Filters::JobQuery'->new($_) };

declare 'RepeatedJobQuery',
    as ArrayRef[JobQuery()];

coerce 'RepeatedJobQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Filters::JobQuery'->new($_) } @$_ ] };

declare 'MapStringJobQuery',
    as HashRef[JobQuery()];

declare 'LocationFilter',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Filters::LocationFilter'];

coerce 'LocationFilter',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Filters::LocationFilter'->new($_) };

declare 'RepeatedLocationFilter',
    as ArrayRef[LocationFilter()];

coerce 'RepeatedLocationFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Filters::LocationFilter'->new($_) } @$_ ] };

declare 'MapStringLocationFilter',
    as HashRef[LocationFilter()];

declare 'TelecommutePreference',
    as (Int | Str);

declare 'CompensationFilter',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Filters::CompensationFilter'];

coerce 'CompensationFilter',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Filters::CompensationFilter'->new($_) };

declare 'RepeatedCompensationFilter',
    as ArrayRef[CompensationFilter()];

coerce 'RepeatedCompensationFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Filters::CompensationFilter'->new($_) } @$_ ] };

declare 'MapStringCompensationFilter',
    as HashRef[CompensationFilter()];

declare 'FilterType',
    as (Int | Str);

declare 'CommuteFilter',
    as InstanceOf['Google::Cloud::Talent::V4beta1::Filters::CommuteFilter'];

coerce 'CommuteFilter',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::Filters::CommuteFilter'->new($_) };

declare 'RepeatedCommuteFilter',
    as ArrayRef[CommuteFilter()];

coerce 'RepeatedCommuteFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::Filters::CommuteFilter'->new($_) } @$_ ] };

declare 'MapStringCommuteFilter',
    as HashRef[CommuteFilter()];

declare 'RoadTraffic',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::Filters::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
