package Google::Cloud::Agentregistry::V1::Binding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Binding',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Binding::Binding'];

coerce 'Binding',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Binding::Binding'->new($_) };

declare 'RepeatedBinding',
    as ArrayRef[Binding()];

coerce 'RepeatedBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Binding::Binding'->new($_) } @$_ ] };

declare 'MapStringBinding',
    as HashRef[Binding()];

declare 'Source',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Binding::Binding::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Binding::Binding::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Binding::Binding::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'Target',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Binding::Binding::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Binding::Binding::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Binding::Binding::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'AuthProviderBinding',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Binding::Binding::AuthProviderBinding'];

coerce 'AuthProviderBinding',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Binding::Binding::AuthProviderBinding'->new($_) };

declare 'RepeatedAuthProviderBinding',
    as ArrayRef[AuthProviderBinding()];

coerce 'RepeatedAuthProviderBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Binding::Binding::AuthProviderBinding'->new($_) } @$_ ] };

declare 'MapStringAuthProviderBinding',
    as HashRef[AuthProviderBinding()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Binding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
