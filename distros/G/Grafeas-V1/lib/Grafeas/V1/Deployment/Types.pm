package Grafeas::V1::Deployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeploymentNote',
    as InstanceOf['Grafeas::V1::Deployment::DeploymentNote'];

coerce 'DeploymentNote',
    from HashRef, via { 'Grafeas::V1::Deployment::DeploymentNote'->new($_) };

declare 'RepeatedDeploymentNote',
    as ArrayRef[DeploymentNote()];

coerce 'RepeatedDeploymentNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Deployment::DeploymentNote'->new($_) } @$_ ] };

declare 'MapStringDeploymentNote',
    as HashRef[DeploymentNote()];

declare 'DeploymentOccurrence',
    as InstanceOf['Grafeas::V1::Deployment::DeploymentOccurrence'];

coerce 'DeploymentOccurrence',
    from HashRef, via { 'Grafeas::V1::Deployment::DeploymentOccurrence'->new($_) };

declare 'RepeatedDeploymentOccurrence',
    as ArrayRef[DeploymentOccurrence()];

coerce 'RepeatedDeploymentOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Deployment::DeploymentOccurrence'->new($_) } @$_ ] };

declare 'MapStringDeploymentOccurrence',
    as HashRef[DeploymentOccurrence()];

declare 'Platform',
    as (Int | Str);

1;

__END__

=head1 NAME

Grafeas::V1::Deployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
