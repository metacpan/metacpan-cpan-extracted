package Google::Cloud::Talent::V4beta1::EventService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateClientEventRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest'];

coerce 'CreateClientEventRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest'->new($_) };

declare 'RepeatedCreateClientEventRequest',
    as ArrayRef[CreateClientEventRequest()];

coerce 'RepeatedCreateClientEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClientEventRequest',
    as HashRef[CreateClientEventRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::EventService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
