package Google::Api::Routing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RoutingRule',
    as InstanceOf['Google::Api::Routing::RoutingRule'];

coerce 'RoutingRule',
    from HashRef, via { 'Google::Api::Routing::RoutingRule'->new($_) };

declare 'RepeatedRoutingRule',
    as ArrayRef[RoutingRule()];

coerce 'RepeatedRoutingRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Routing::RoutingRule'->new($_) } @$_ ] };

declare 'MapStringRoutingRule',
    as HashRef[RoutingRule()];

declare 'RoutingParameter',
    as InstanceOf['Google::Api::Routing::RoutingParameter'];

coerce 'RoutingParameter',
    from HashRef, via { 'Google::Api::Routing::RoutingParameter'->new($_) };

declare 'RepeatedRoutingParameter',
    as ArrayRef[RoutingParameter()];

coerce 'RepeatedRoutingParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Routing::RoutingParameter'->new($_) } @$_ ] };

declare 'MapStringRoutingParameter',
    as HashRef[RoutingParameter()];

1;

__END__

=head1 NAME

Google::Api::Routing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
