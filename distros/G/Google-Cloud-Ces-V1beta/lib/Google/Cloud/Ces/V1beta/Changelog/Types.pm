package Google::Cloud::Ces::V1beta::Changelog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Changelog',
    as InstanceOf['Google::Cloud::Ces::V1beta::Changelog::Changelog'];

coerce 'Changelog',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Changelog::Changelog'->new($_) };

declare 'RepeatedChangelog',
    as ArrayRef[Changelog()];

coerce 'RepeatedChangelog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Changelog::Changelog'->new($_) } @$_ ] };

declare 'MapStringChangelog',
    as HashRef[Changelog()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Changelog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
