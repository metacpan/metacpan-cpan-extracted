package Google::Api::Resource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourceDescriptor',
    as InstanceOf['Google::Api::Resource::ResourceDescriptor'];

coerce 'ResourceDescriptor',
    from HashRef, via { 'Google::Api::Resource::ResourceDescriptor'->new($_) };

declare 'RepeatedResourceDescriptor',
    as ArrayRef[ResourceDescriptor()];

coerce 'RepeatedResourceDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Resource::ResourceDescriptor'->new($_) } @$_ ] };

declare 'MapStringResourceDescriptor',
    as HashRef[ResourceDescriptor()];

declare 'History',
    as (Int | Str);

declare 'Style',
    as (Int | Str);

declare 'ResourceReference',
    as InstanceOf['Google::Api::Resource::ResourceReference'];

coerce 'ResourceReference',
    from HashRef, via { 'Google::Api::Resource::ResourceReference'->new($_) };

declare 'RepeatedResourceReference',
    as ArrayRef[ResourceReference()];

coerce 'RepeatedResourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Resource::ResourceReference'->new($_) } @$_ ] };

declare 'MapStringResourceReference',
    as HashRef[ResourceReference()];

1;

__END__

=head1 NAME

Google::Api::Resource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
