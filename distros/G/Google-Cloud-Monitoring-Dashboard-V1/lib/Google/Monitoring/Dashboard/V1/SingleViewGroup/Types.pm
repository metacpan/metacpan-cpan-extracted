package Google::Monitoring::Dashboard::V1::SingleViewGroup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SingleViewGroup',
    as InstanceOf['Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup'];

coerce 'SingleViewGroup',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup'->new($_) };

declare 'RepeatedSingleViewGroup',
    as ArrayRef[SingleViewGroup()];

coerce 'RepeatedSingleViewGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup'->new($_) } @$_ ] };

declare 'MapStringSingleViewGroup',
    as HashRef[SingleViewGroup()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::SingleViewGroup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
