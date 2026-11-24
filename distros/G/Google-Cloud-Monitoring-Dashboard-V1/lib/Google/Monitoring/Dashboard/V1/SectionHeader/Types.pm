package Google::Monitoring::Dashboard::V1::SectionHeader::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SectionHeader',
    as InstanceOf['Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader'];

coerce 'SectionHeader',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader'->new($_) };

declare 'RepeatedSectionHeader',
    as ArrayRef[SectionHeader()];

coerce 'RepeatedSectionHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader'->new($_) } @$_ ] };

declare 'MapStringSectionHeader',
    as HashRef[SectionHeader()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::SectionHeader::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
