package Google::Monitoring::V3::Group::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Group',
    as InstanceOf['Google::Monitoring::V3::Group::Group'];

coerce 'Group',
    from HashRef, via { 'Google::Monitoring::V3::Group::Group'->new($_) };

declare 'RepeatedGroup',
    as ArrayRef[Group()];

coerce 'RepeatedGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Group::Group'->new($_) } @$_ ] };

declare 'MapStringGroup',
    as HashRef[Group()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Group::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
