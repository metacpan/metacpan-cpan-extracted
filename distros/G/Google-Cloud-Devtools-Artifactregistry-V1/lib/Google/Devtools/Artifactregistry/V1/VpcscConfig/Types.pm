package Google::Devtools::Artifactregistry::V1::VpcscConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VPCSCConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig'];

coerce 'VPCSCConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig'->new($_) };

declare 'RepeatedVPCSCConfig',
    as ArrayRef[VPCSCConfig()];

coerce 'RepeatedVPCSCConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::VpcscConfig::VPCSCConfig'->new($_) } @$_ ] };

declare 'MapStringVPCSCConfig',
    as HashRef[VPCSCConfig()];

declare 'VPCSCPolicy',
    as (Int | Str);

declare 'GetVPCSCConfigRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::VpcscConfig::GetVPCSCConfigRequest'];

coerce 'GetVPCSCConfigRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::VpcscConfig::GetVPCSCConfigRequest'->new($_) };

declare 'RepeatedGetVPCSCConfigRequest',
    as ArrayRef[GetVPCSCConfigRequest()];

coerce 'RepeatedGetVPCSCConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::VpcscConfig::GetVPCSCConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetVPCSCConfigRequest',
    as HashRef[GetVPCSCConfigRequest()];

declare 'UpdateVPCSCConfigRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::VpcscConfig::UpdateVPCSCConfigRequest'];

coerce 'UpdateVPCSCConfigRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::VpcscConfig::UpdateVPCSCConfigRequest'->new($_) };

declare 'RepeatedUpdateVPCSCConfigRequest',
    as ArrayRef[UpdateVPCSCConfigRequest()];

coerce 'RepeatedUpdateVPCSCConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::VpcscConfig::UpdateVPCSCConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVPCSCConfigRequest',
    as HashRef[UpdateVPCSCConfigRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::VpcscConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
