package Google::Cloud::Securitycenter::V1::LoadBalancer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoadBalancer',
    as InstanceOf['Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer'];

coerce 'LoadBalancer',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer'->new($_) };

declare 'RepeatedLoadBalancer',
    as ArrayRef[LoadBalancer()];

coerce 'RepeatedLoadBalancer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::LoadBalancer::LoadBalancer'->new($_) } @$_ ] };

declare 'MapStringLoadBalancer',
    as HashRef[LoadBalancer()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::LoadBalancer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
