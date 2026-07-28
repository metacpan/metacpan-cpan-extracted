package Google::Api::Consumer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProjectProperties',
    as InstanceOf['Google::Api::Consumer::ProjectProperties'];

coerce 'ProjectProperties',
    from HashRef, via { 'Google::Api::Consumer::ProjectProperties'->new($_) };

declare 'RepeatedProjectProperties',
    as ArrayRef[ProjectProperties()];

coerce 'RepeatedProjectProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Consumer::ProjectProperties'->new($_) } @$_ ] };

declare 'MapStringProjectProperties',
    as HashRef[ProjectProperties()];

declare 'Property',
    as InstanceOf['Google::Api::Consumer::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Api::Consumer::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Consumer::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'PropertyType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Api::Consumer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
