package Google::Api::Control::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Control',
    as InstanceOf['Google::Api::Control::Control'];

coerce 'Control',
    from HashRef, via { 'Google::Api::Control::Control'->new($_) };

declare 'RepeatedControl',
    as ArrayRef[Control()];

coerce 'RepeatedControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Control::Control'->new($_) } @$_ ] };

declare 'MapStringControl',
    as HashRef[Control()];

1;

__END__

=head1 NAME

Google::Api::Control::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
