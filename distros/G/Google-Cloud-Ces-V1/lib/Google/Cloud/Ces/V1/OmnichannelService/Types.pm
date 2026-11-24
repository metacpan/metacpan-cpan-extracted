package Google::Cloud::Ces::V1::OmnichannelService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OmnichannelOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata'];

coerce 'OmnichannelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata'->new($_) };

declare 'RepeatedOmnichannelOperationMetadata',
    as ArrayRef[OmnichannelOperationMetadata()];

coerce 'RepeatedOmnichannelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::OmnichannelService::OmnichannelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOmnichannelOperationMetadata',
    as HashRef[OmnichannelOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::OmnichannelService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
