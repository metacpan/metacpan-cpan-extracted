package Google::Cloud::Discoveryengine::V1::AclConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AclConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig'];

coerce 'AclConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig'->new($_) };

declare 'RepeatedAclConfig',
    as ArrayRef[AclConfig()];

coerce 'RepeatedAclConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig'->new($_) } @$_ ] };

declare 'MapStringAclConfig',
    as HashRef[AclConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::AclConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
