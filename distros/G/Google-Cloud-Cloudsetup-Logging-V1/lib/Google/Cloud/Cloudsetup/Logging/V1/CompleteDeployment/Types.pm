package Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompleteDeploymentEvent',
    as InstanceOf['Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent'];

coerce 'CompleteDeploymentEvent',
    from HashRef, via { 'Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent'->new($_) };

declare 'RepeatedCompleteDeploymentEvent',
    as ArrayRef[CompleteDeploymentEvent()];

coerce 'RepeatedCompleteDeploymentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentEvent'->new($_) } @$_ ] };

declare 'MapStringCompleteDeploymentEvent',
    as HashRef[CompleteDeploymentEvent()];

declare 'State',
    as (Int | Str);

declare 'CompleteDeploymentResult',
    as InstanceOf['Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentResult'];

coerce 'CompleteDeploymentResult',
    from HashRef, via { 'Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentResult'->new($_) };

declare 'RepeatedCompleteDeploymentResult',
    as ArrayRef[CompleteDeploymentResult()];

coerce 'RepeatedCompleteDeploymentResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::CompleteDeploymentResult'->new($_) } @$_ ] };

declare 'MapStringCompleteDeploymentResult',
    as HashRef[CompleteDeploymentResult()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsetup::Logging::V1::CompleteDeployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
