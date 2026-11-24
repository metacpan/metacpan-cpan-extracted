package Google::Cloud::Securitycenter::V2::SecurityPosture::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecurityPosture',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecurityPosture::SecurityPosture'];

coerce 'SecurityPosture',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecurityPosture::SecurityPosture'->new($_) };

declare 'RepeatedSecurityPosture',
    as ArrayRef[SecurityPosture()];

coerce 'RepeatedSecurityPosture',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecurityPosture::SecurityPosture'->new($_) } @$_ ] };

declare 'MapStringSecurityPosture',
    as HashRef[SecurityPosture()];

declare 'PolicyDriftDetails',
    as InstanceOf['Google::Cloud::Securitycenter::V2::SecurityPosture::SecurityPosture::PolicyDriftDetails'];

coerce 'PolicyDriftDetails',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::SecurityPosture::SecurityPosture::PolicyDriftDetails'->new($_) };

declare 'RepeatedPolicyDriftDetails',
    as ArrayRef[PolicyDriftDetails()];

coerce 'RepeatedPolicyDriftDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::SecurityPosture::SecurityPosture::PolicyDriftDetails'->new($_) } @$_ ] };

declare 'MapStringPolicyDriftDetails',
    as HashRef[PolicyDriftDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::SecurityPosture::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
