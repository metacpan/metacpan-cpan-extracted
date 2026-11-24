package Google::Cloud::Oracledatabase::V1::GiVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GiVersion',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion'];

coerce 'GiVersion',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion'->new($_) };

declare 'RepeatedGiVersion',
    as ArrayRef[GiVersion()];

coerce 'RepeatedGiVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GiVersion::GiVersion'->new($_) } @$_ ] };

declare 'MapStringGiVersion',
    as HashRef[GiVersion()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GiVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
