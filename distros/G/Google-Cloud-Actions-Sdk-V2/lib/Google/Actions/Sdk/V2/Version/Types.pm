package Google::Actions::Sdk::V2::Version::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Version',
    as InstanceOf['Google::Actions::Sdk::V2::Version::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Actions::Sdk::V2::Version::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Version::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'VersionState',
    as InstanceOf['Google::Actions::Sdk::V2::Version::Version::VersionState'];

coerce 'VersionState',
    from HashRef, via { 'Google::Actions::Sdk::V2::Version::Version::VersionState'->new($_) };

declare 'RepeatedVersionState',
    as ArrayRef[VersionState()];

coerce 'RepeatedVersionState',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Version::Version::VersionState'->new($_) } @$_ ] };

declare 'MapStringVersionState',
    as HashRef[VersionState()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Version::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
