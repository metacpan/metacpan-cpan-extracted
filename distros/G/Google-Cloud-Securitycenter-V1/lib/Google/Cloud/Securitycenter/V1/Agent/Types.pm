package Google::Cloud::Securitycenter::V1::Agent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Agent',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Agent::Agent'];

coerce 'Agent',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Agent::Agent'->new($_) };

declare 'RepeatedAgent',
    as ArrayRef[Agent()];

coerce 'RepeatedAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Agent::Agent'->new($_) } @$_ ] };

declare 'MapStringAgent',
    as HashRef[Agent()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Agent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
