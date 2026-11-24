package Google::Cloud::Automl::V1beta1::TableSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableSpec',
    as InstanceOf['Google::Cloud::Automl::V1beta1::TableSpec::TableSpec'];

coerce 'TableSpec',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::TableSpec::TableSpec'->new($_) };

declare 'RepeatedTableSpec',
    as ArrayRef[TableSpec()];

coerce 'RepeatedTableSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::TableSpec::TableSpec'->new($_) } @$_ ] };

declare 'MapStringTableSpec',
    as HashRef[TableSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::TableSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
