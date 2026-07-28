package Google::Api::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Api::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Api::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

1;

__END__

=head1 NAME

Google::Api::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
