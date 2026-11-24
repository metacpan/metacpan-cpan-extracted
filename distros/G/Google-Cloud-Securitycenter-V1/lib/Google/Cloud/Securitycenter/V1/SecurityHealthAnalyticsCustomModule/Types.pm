package Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecurityHealthAnalyticsCustomModule',
    as InstanceOf['Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule'];

coerce 'SecurityHealthAnalyticsCustomModule',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule'->new($_) };

declare 'RepeatedSecurityHealthAnalyticsCustomModule',
    as ArrayRef[SecurityHealthAnalyticsCustomModule()];

coerce 'RepeatedSecurityHealthAnalyticsCustomModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule'->new($_) } @$_ ] };

declare 'MapStringSecurityHealthAnalyticsCustomModule',
    as HashRef[SecurityHealthAnalyticsCustomModule()];

declare 'EnablementState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
