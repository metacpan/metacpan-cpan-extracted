package Google::Cloud::Securityposture::V1::ShaConstraints::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EnablementState',
    as (Int | Str);

declare 'SecurityHealthAnalyticsModule',
    as InstanceOf['Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule'];

coerce 'SecurityHealthAnalyticsModule',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule'->new($_) };

declare 'RepeatedSecurityHealthAnalyticsModule',
    as ArrayRef[SecurityHealthAnalyticsModule()];

coerce 'RepeatedSecurityHealthAnalyticsModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsModule'->new($_) } @$_ ] };

declare 'MapStringSecurityHealthAnalyticsModule',
    as HashRef[SecurityHealthAnalyticsModule()];

declare 'SecurityHealthAnalyticsCustomModule',
    as InstanceOf['Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsCustomModule'];

coerce 'SecurityHealthAnalyticsCustomModule',
    from HashRef, via { 'Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsCustomModule'->new($_) };

declare 'RepeatedSecurityHealthAnalyticsCustomModule',
    as ArrayRef[SecurityHealthAnalyticsCustomModule()];

coerce 'RepeatedSecurityHealthAnalyticsCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securityposture::V1::ShaConstraints::SecurityHealthAnalyticsCustomModule'->new($_) } @$_ ] };

declare 'MapStringSecurityHealthAnalyticsCustomModule',
    as HashRef[SecurityHealthAnalyticsCustomModule()];

1;

__END__

=head1 NAME

Google::Cloud::Securityposture::V1::ShaConstraints::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
