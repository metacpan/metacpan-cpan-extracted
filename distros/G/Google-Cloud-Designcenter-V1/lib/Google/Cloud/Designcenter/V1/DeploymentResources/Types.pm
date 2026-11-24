package Google::Cloud::Designcenter::V1::DeploymentResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Application',
    as InstanceOf['Google::Cloud::Designcenter::V1::DeploymentResources::Application'];

coerce 'Application',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::DeploymentResources::Application'->new($_) };

declare 'RepeatedApplication',
    as ArrayRef[Application()];

coerce 'RepeatedApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::DeploymentResources::Application'->new($_) } @$_ ] };

declare 'MapStringApplication',
    as HashRef[Application()];

declare 'State',
    as (Int | Str);

declare 'UpdateStrategy',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::DeploymentResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
