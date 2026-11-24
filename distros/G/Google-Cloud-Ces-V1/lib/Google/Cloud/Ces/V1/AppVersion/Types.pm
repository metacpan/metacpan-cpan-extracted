package Google::Cloud::Ces::V1::AppVersion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AppSnapshot',
    as InstanceOf['Google::Cloud::Ces::V1::AppVersion::AppSnapshot'];

coerce 'AppSnapshot',
    from HashRef, via { 'Google::Cloud::Ces::V1::AppVersion::AppSnapshot'->new($_) };

declare 'RepeatedAppSnapshot',
    as ArrayRef[AppSnapshot()];

coerce 'RepeatedAppSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AppVersion::AppSnapshot'->new($_) } @$_ ] };

declare 'MapStringAppSnapshot',
    as HashRef[AppSnapshot()];

declare 'AppVersion',
    as InstanceOf['Google::Cloud::Ces::V1::AppVersion::AppVersion'];

coerce 'AppVersion',
    from HashRef, via { 'Google::Cloud::Ces::V1::AppVersion::AppVersion'->new($_) };

declare 'RepeatedAppVersion',
    as ArrayRef[AppVersion()];

coerce 'RepeatedAppVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AppVersion::AppVersion'->new($_) } @$_ ] };

declare 'MapStringAppVersion',
    as HashRef[AppVersion()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::AppVersion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
