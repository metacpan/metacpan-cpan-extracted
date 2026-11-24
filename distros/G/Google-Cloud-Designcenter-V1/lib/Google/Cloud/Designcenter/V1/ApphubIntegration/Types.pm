package Google::Cloud::Designcenter::V1::ApphubIntegration::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UnregisteredResource',
    as InstanceOf['Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource'];

coerce 'UnregisteredResource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource'->new($_) };

declare 'RepeatedUnregisteredResource',
    as ArrayRef[UnregisteredResource()];

coerce 'RepeatedUnregisteredResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource'->new($_) } @$_ ] };

declare 'MapStringUnregisteredResource',
    as HashRef[UnregisteredResource()];

declare 'DeployedResource',
    as InstanceOf['Google::Cloud::Designcenter::V1::ApphubIntegration::DeployedResource'];

coerce 'DeployedResource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::ApphubIntegration::DeployedResource'->new($_) };

declare 'RepeatedDeployedResource',
    as ArrayRef[DeployedResource()];

coerce 'RepeatedDeployedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::ApphubIntegration::DeployedResource'->new($_) } @$_ ] };

declare 'MapStringDeployedResource',
    as HashRef[DeployedResource()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::ApphubIntegration::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
