package Grafeas::V1::Upgrade::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpgradeNote',
    as InstanceOf['Grafeas::V1::Upgrade::UpgradeNote'];

coerce 'UpgradeNote',
    from HashRef, via { 'Grafeas::V1::Upgrade::UpgradeNote'->new($_) };

declare 'RepeatedUpgradeNote',
    as ArrayRef[UpgradeNote()];

coerce 'RepeatedUpgradeNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Upgrade::UpgradeNote'->new($_) } @$_ ] };

declare 'MapStringUpgradeNote',
    as HashRef[UpgradeNote()];

declare 'UpgradeDistribution',
    as InstanceOf['Grafeas::V1::Upgrade::UpgradeDistribution'];

coerce 'UpgradeDistribution',
    from HashRef, via { 'Grafeas::V1::Upgrade::UpgradeDistribution'->new($_) };

declare 'RepeatedUpgradeDistribution',
    as ArrayRef[UpgradeDistribution()];

coerce 'RepeatedUpgradeDistribution',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Upgrade::UpgradeDistribution'->new($_) } @$_ ] };

declare 'MapStringUpgradeDistribution',
    as HashRef[UpgradeDistribution()];

declare 'WindowsUpdate',
    as InstanceOf['Grafeas::V1::Upgrade::WindowsUpdate'];

coerce 'WindowsUpdate',
    from HashRef, via { 'Grafeas::V1::Upgrade::WindowsUpdate'->new($_) };

declare 'RepeatedWindowsUpdate',
    as ArrayRef[WindowsUpdate()];

coerce 'RepeatedWindowsUpdate',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Upgrade::WindowsUpdate'->new($_) } @$_ ] };

declare 'MapStringWindowsUpdate',
    as HashRef[WindowsUpdate()];

declare 'Identity',
    as InstanceOf['Grafeas::V1::Upgrade::WindowsUpdate::Identity'];

coerce 'Identity',
    from HashRef, via { 'Grafeas::V1::Upgrade::WindowsUpdate::Identity'->new($_) };

declare 'RepeatedIdentity',
    as ArrayRef[Identity()];

coerce 'RepeatedIdentity',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Upgrade::WindowsUpdate::Identity'->new($_) } @$_ ] };

declare 'MapStringIdentity',
    as HashRef[Identity()];

declare 'Category',
    as InstanceOf['Grafeas::V1::Upgrade::WindowsUpdate::Category'];

coerce 'Category',
    from HashRef, via { 'Grafeas::V1::Upgrade::WindowsUpdate::Category'->new($_) };

declare 'RepeatedCategory',
    as ArrayRef[Category()];

coerce 'RepeatedCategory',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Upgrade::WindowsUpdate::Category'->new($_) } @$_ ] };

declare 'MapStringCategory',
    as HashRef[Category()];

declare 'UpgradeOccurrence',
    as InstanceOf['Grafeas::V1::Upgrade::UpgradeOccurrence'];

coerce 'UpgradeOccurrence',
    from HashRef, via { 'Grafeas::V1::Upgrade::UpgradeOccurrence'->new($_) };

declare 'RepeatedUpgradeOccurrence',
    as ArrayRef[UpgradeOccurrence()];

coerce 'RepeatedUpgradeOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Upgrade::UpgradeOccurrence'->new($_) } @$_ ] };

declare 'MapStringUpgradeOccurrence',
    as HashRef[UpgradeOccurrence()];

1;

__END__

=head1 NAME

Grafeas::V1::Upgrade::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
