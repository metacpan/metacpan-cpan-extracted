package Google::Api::Httpbody::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpBody',
    as InstanceOf['Google::Api::Httpbody::HttpBody'];

coerce 'HttpBody',
    from HashRef, via { 'Google::Api::Httpbody::HttpBody'->new($_) };

declare 'RepeatedHttpBody',
    as ArrayRef[HttpBody()];

coerce 'RepeatedHttpBody',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Httpbody::HttpBody'->new($_) } @$_ ] };

declare 'MapStringHttpBody',
    as HashRef[HttpBody()];

1;

__END__

=head1 NAME

Google::Api::Httpbody::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
