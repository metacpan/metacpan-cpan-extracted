package Google::Api::Context::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Context',
    as InstanceOf['Google::Api::Context::Context'];

coerce 'Context',
    from HashRef, via { 'Google::Api::Context::Context'->new($_) };

declare 'RepeatedContext',
    as ArrayRef[Context()];

coerce 'RepeatedContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Context::Context'->new($_) } @$_ ] };

declare 'MapStringContext',
    as HashRef[Context()];

declare 'ContextRule',
    as InstanceOf['Google::Api::Context::ContextRule'];

coerce 'ContextRule',
    from HashRef, via { 'Google::Api::Context::ContextRule'->new($_) };

declare 'RepeatedContextRule',
    as ArrayRef[ContextRule()];

coerce 'RepeatedContextRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Context::ContextRule'->new($_) } @$_ ] };

declare 'MapStringContextRule',
    as HashRef[ContextRule()];

1;

__END__

=head1 NAME

Google::Api::Context::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
