package Google::Actions::Sdk::V2::ReleaseChannel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReleaseChannel',
    as InstanceOf['Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel'];

coerce 'ReleaseChannel',
    from HashRef, via { 'Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel'->new($_) };

declare 'RepeatedReleaseChannel',
    as ArrayRef[ReleaseChannel()];

coerce 'RepeatedReleaseChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel'->new($_) } @$_ ] };

declare 'MapStringReleaseChannel',
    as HashRef[ReleaseChannel()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::ReleaseChannel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
