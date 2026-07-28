package Google::Cloud::Bigquery::V2::RestrictionConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestrictionConfig',
    as InstanceOf['Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig'];

coerce 'RestrictionConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig'->new($_) };

declare 'RepeatedRestrictionConfig',
    as ArrayRef[RestrictionConfig()];

coerce 'RepeatedRestrictionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RestrictionConfig::RestrictionConfig'->new($_) } @$_ ] };

declare 'MapStringRestrictionConfig',
    as HashRef[RestrictionConfig()];

declare 'RestrictionType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::RestrictionConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
