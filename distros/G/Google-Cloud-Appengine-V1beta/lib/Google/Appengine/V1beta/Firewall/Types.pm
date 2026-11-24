package Google::Appengine::V1beta::Firewall::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FirewallRule',
    as InstanceOf['Google::Appengine::V1beta::Firewall::FirewallRule'];

coerce 'FirewallRule',
    from HashRef, via { 'Google::Appengine::V1beta::Firewall::FirewallRule'->new($_) };

declare 'RepeatedFirewallRule',
    as ArrayRef[FirewallRule()];

coerce 'RepeatedFirewallRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Firewall::FirewallRule'->new($_) } @$_ ] };

declare 'MapStringFirewallRule',
    as HashRef[FirewallRule()];

declare 'Action',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Appengine::V1beta::Firewall::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
