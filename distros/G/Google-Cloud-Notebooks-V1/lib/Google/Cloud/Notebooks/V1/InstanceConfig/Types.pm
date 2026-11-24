package Google::Cloud::Notebooks::V1::InstanceConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InstanceConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig'];

coerce 'InstanceConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig'->new($_) };

declare 'RepeatedInstanceConfig',
    as ArrayRef[InstanceConfig()];

coerce 'RepeatedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig'->new($_) } @$_ ] };

declare 'MapStringInstanceConfig',
    as HashRef[InstanceConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::InstanceConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
