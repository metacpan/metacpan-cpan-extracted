package Google::Cloud::Databasecenter::V1beta::Affiliation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Affiliation',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation'];

coerce 'Affiliation',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation'->new($_) };

declare 'RepeatedAffiliation',
    as ArrayRef[Affiliation()];

coerce 'RepeatedAffiliation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation'->new($_) } @$_ ] };

declare 'MapStringAffiliation',
    as HashRef[Affiliation()];

declare 'ProcessType',
    as (Int | Str);

declare 'Lineage',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation::Lineage'];

coerce 'Lineage',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation::Lineage'->new($_) };

declare 'RepeatedLineage',
    as ArrayRef[Lineage()];

coerce 'RepeatedLineage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Affiliation::Affiliation::Lineage'->new($_) } @$_ ] };

declare 'MapStringLineage',
    as HashRef[Lineage()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Affiliation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
